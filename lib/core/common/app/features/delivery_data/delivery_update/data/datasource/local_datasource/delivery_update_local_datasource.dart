import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../../../enums/invoice_status.dart';
import '../../../../../../../../services/objectbox.dart';
import '../../../../../delivery_team/delivery_team/data/models/delivery_team_model.dart';
import '../../../../../trip_ticket/delivery_collection/data/model/collection_model.dart';
import '../../../../../trip_ticket/trip/data/models/trip_models.dart';
import '../../../../../users/user_performance/data/model/user_performance_model.dart';

abstract class DeliveryUpdateLocalDatasource {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(
    String deliveryDataId,
  );
  Future<void> updateDeliveryStatus(
    String deliveryDataPbId, // DeliveryData PB ID
    DeliveryStatusChoicesModel statusChoice, // ✅ FULL STATUS MODEL
  );
  Future<void> completeDelivery(DeliveryDataEntity deliveryData);
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  );

  Future<void> saveDeliveryStatusChoices(
    String customerId,
    List<DeliveryUpdateModel> choices,
  );
  Future<void> saveDeliveryUpdateChoices(
    String customerId,
    List<DeliveryUpdateModel> updates,
  );
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  );
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  });
  Future<void> updateQueueRemarks(
    String statusId,
    String remarks,
    String image,
  );
  Future<DataMap> checkEndDeliverStatus(String tripId);
  Future<void> initializePendingStatus(List<String> customerIds);
  Box<DeliveryUpdateModel> get deliveryUpdateBox;

  /// 🆕 Background sync helper methods
  Future<void> markSyncing(DeliveryUpdateModel status);
  Future<void> markSynced(DeliveryUpdateModel status);
  Future<void> markFailed(DeliveryUpdateModel status, String error);
  Future<List<DeliveryUpdateModel>> getPendingSyncList();
}

class DeliveryUpdateLocalDatasourceImpl
    implements DeliveryUpdateLocalDatasource {
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<UserPerformanceModel> get userPerformance =>
      objectBoxStore.userPerformanceBox;

  Box<DeliveryStatusChoicesModel> get deliveryStatusChoicesBox =>
      objectBoxStore.deliveryStatusBox;

  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;
  final ObjectBoxStore objectBoxStore;

  DeliveryUpdateLocalDatasourceImpl(this.objectBoxStore);

  Future<void> _autoSave(DeliveryUpdateModel update) async {
    try {
      if (update.title == null || update.id!.isEmpty) {
        debugPrint('⚠️ Skipping invalid delivery update');
        return;
      }

      debugPrint('🔍 Processing update: ${update.title} (ID: ${update.id})');

      final existingUpdate =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.id.equals(update.id ?? ''))
              .build()
              .findFirst();

      if (existingUpdate != null) {
        debugPrint('🔄 Updating existing status: ${update.title}');
        update.objectBoxId = existingUpdate.objectBoxId;
      } else {
        debugPrint('➕ Adding new status: ${update.title}');
      }

      deliveryUpdateBox.put(update);
      final totalUpdates = deliveryUpdateBox.count();
      debugPrint('📊 Current total valid updates: $totalUpdates');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  /// 🆕 Load Delivery Status Choices locally (offline filtering)
  @override
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(
    String deliveryDataId, // ✅ PocketBase ID
  ) async {
    try {
      debugPrint(
        'LOCAL 🔄 Fetching status choices for DeliveryData PB ID: $deliveryDataId',
      );

      // ---------------------------------------------------
      // 0️⃣ Find DeliveryData first (same pattern as Trip)
      // ---------------------------------------------------
      final ddQuery =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataId))
              .build();

      final deliveryData = ddQuery.findFirst();
      ddQuery.close();

      if (deliveryData == null) {
        debugPrint('LOCAL ❌ DeliveryData not found locally');
        return [];
      }

      debugPrint(
        'LOCAL ✅ DeliveryData found → OBX ID: ${deliveryData.objectBoxId}',
      );

      // ---------------------------------------------------
      // 1️⃣ Load DeliveryUpdates FROM RELATION (NOT QUERY)
      // ---------------------------------------------------
      final updates = <DeliveryUpdateModel>[];

      for (final u in deliveryData.deliveryUpdates) {
        final fullUpdate = deliveryUpdateBox.get(u.objectBoxId);
        if (fullUpdate != null) {
          updates.add(fullUpdate);
          debugPrint('    📝 ${fullUpdate.title} | time=${fullUpdate.time}');
        }
      }

      if (updates.isEmpty) {
        debugPrint('LOCAL ⚠️ No delivery updates found');
      }

      // ---------------------------------------------------
      // 2️⃣ Determine latest status
      // ---------------------------------------------------
      updates.sort((a, b) {
        final at = a.time ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.time ?? DateTime.fromMillisecondsSinceEpoch(0);
        return at.compareTo(bt);
      });

      final latestStatus =
          updates.isNotEmpty ? updates.last.title?.toLowerCase() ?? '' : '';

      debugPrint('LOCAL 📍 Latest status: "$latestStatus"');

      // ---------------------------------------------------
      // 3️⃣ Load cached status choices
      // ---------------------------------------------------
      final allStatuses = deliveryStatusChoicesBox.getAll();

      if (allStatuses.isEmpty) {
        debugPrint('LOCAL ⚠️ No cached deliveryStatusChoices found');
        return [];
      }

      // ---------------------------------------------------
      // 4️⃣ Apply SAME rules as remote
      // ---------------------------------------------------
      if (latestStatus == 'in transit') {
        return _filterLocalStatusChoices(allStatuses, [
          'arrived',
          'mark as undelivered',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'waiting for customer') {
        return _filterLocalStatusChoices(allStatuses, [
          'unloading',
          'mark as undelivered',
          'invoices in queue',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'invoices in queue') {
        return _filterLocalStatusChoices(allStatuses, [
          'unloading',
          'mark as undelivered',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'unloading') {
        return _filterLocalStatusChoices(allStatuses, [
          'mark as received',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'mark as received') {
        return _filterLocalStatusChoices(allStatuses, [
          'end delivery',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'arrived') {
        return _filterLocalStatusChoices(allStatuses, [
          'unloading',
          'mark as undelivered',
          'waiting for customer',
          'invoices in queue',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'mark as undelivered') return [];
      if (latestStatus == 'end delivery') return [];

      // ---------------------------------------------------
      // 5️⃣ Prevent duplicates
      // ---------------------------------------------------
      final assignedTitles =
          updates
              .where((u) => u.title != null)
              .map((u) => u.title!.toLowerCase())
              .toSet();

      final filtered =
          allStatuses
              .where((s) => !assignedTitles.contains(s.title!.toLowerCase()))
              .map((s) {
                final update = DeliveryUpdateModel(
                  title: s.title,
                  subtitle: s.subtitle,
                );
                update.deliveryData.target = deliveryData;
                return update;
              })
              .toList();

      debugPrint('LOCAL ✅ Final choices count: ${filtered.length}');
      return filtered;
    } catch (e, st) {
      debugPrint('LOCAL ❌ Error in getDeliveryStatusChoices: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  List<DeliveryUpdateModel> _filterLocalStatusChoices(
    List<DeliveryStatusChoicesModel> allStatuses,
    List<String> allowedTitles,
    int deliveryDataObxId,
  ) {
    return allStatuses
        .where((status) => allowedTitles.contains(status.title!.toLowerCase()))
        .map((status) {
          debugPrint(
            'LOCAL 🟢 Allowed → ${status.title} collection ${status.collectionName}',
          );

          final update = DeliveryUpdateModel(
            title: status.title,
            subtitle: status.subtitle,
          );

          update.deliveryData.targetId = deliveryDataObxId;

          return update;
        })
        .toList();
  }

  @override
  Future<void> saveDeliveryStatusChoices(
    String customerId,
    List<DeliveryUpdateModel> choices,
  ) async {
    try {
      debugPrint(
        '💾 [LOCAL] Caching ${choices.length} status choices for: $customerId',
      );

      // Use special marker to distinguish choices from history
      final choicesKey = 'choices_$customerId';

      // Remove old cached choices for this customer
      final oldQuery =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.customer.equals(choicesKey))
              .build();
      final oldCount = oldQuery.remove();
      debugPrint('🧹 Removed $oldCount old cached choices');

      // Save new choices with special customer key
      for (final choice in choices) {
        choice.customer = choicesKey; // Use special key to mark as choice
        choice.isAssigned = false; // Mark as available choice
        choice.created = DateTime.now();

        deliveryUpdateBox.put(choice);
        debugPrint('✅ Cached choice: ${choice.title}');
      }

      debugPrint('✅ Cached ${choices.length} status choices for $customerId');
    } catch (e) {
      debugPrint('❌ Failed to cache status choices: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> saveDeliveryUpdateChoices(
    String customerId,
    List<DeliveryUpdateModel> updates,
  ) async {
    try {
      debugPrint(
        '💾 Saving ${updates.length} delivery update HISTORY for: $customerId',
      );

      // Remove old delivery history for this customer (use actual customer ID)
      final oldQuery =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.customer.equals(customerId))
              .build();

      // Filter to only remove history records (not choice records)
      final oldUpdates = oldQuery.find();
      final historyRecords =
          oldUpdates
              .where(
                (u) =>
                    u.customer != null && !u.customer!.startsWith('choices_'),
              )
              .toList();

      for (var record in historyRecords) {
        deliveryUpdateBox.remove(record.objectBoxId);
      }
      debugPrint(
        '🧹 Removed ${historyRecords.length} old delivery history records',
      );
      oldQuery.close();

      // Save delivery history with actual customer ID
      for (final update in updates) {
        update.customer = customerId; // Use actual customer ID for history
        update.isAssigned = true; // Mark as assigned/completed status

        update.created ??= DateTime.now();

        deliveryUpdateBox.put(update);
        debugPrint('✅ Saved history: ${update.title} (${update.id})');
      }

      debugPrint(
        '✅ Saved ${updates.length} delivery history records for $customerId',
      );
    } catch (e) {
      debugPrint('❌ Failed to save delivery history: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  ) async {
    final Map<String, List<DeliveryUpdateModel>> result = {};

    try {
      debugPrint('📦 Fetching bulk delivery status choices from local DB...');

      for (final customerId in customerIds) {
        try {
          final updates =
              deliveryUpdateBox
                  .query(DeliveryUpdateModel_.customer.equals(customerId))
                  .build()
                  .find();

          debugPrint('📊 Delivery Updates for Customer $customerId:');
          debugPrint('   📦 Total Updates: ${updates.length}');
          debugPrint('   📝 Status Timeline:');
          for (var update in updates) {
            debugPrint('      ${update.title}: ${update.created}');
          }

          result[customerId] = updates;
        } catch (e) {
          debugPrint('❌ Failed to fetch local statuses for $customerId: $e');
          result[customerId] = [];
        }
      }

      return result;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateDeliveryStatus(
    String deliveryDataPbId, // DeliveryData PB ID
    DeliveryStatusChoicesModel statusChoice, // Selected status
  ) async {
    try {
      debugPrint('🔵 START: updateDeliveryStatus()');
      debugPrint('   📌 DeliveryData PB ID: $deliveryDataPbId');
      debugPrint('   🏷️ Status: ${statusChoice.title} (${statusChoice.id})');

      // ---------------------------------------------------
      // 0️⃣ VALIDATE INPUT
      // ---------------------------------------------------
      if (statusChoice.id == null || statusChoice.id!.isEmpty) {
        debugPrint('❌ StatusChoice PB ID is NULL or EMPTY');
        return;
      }

      // ---------------------------------------------------
      // 1️⃣ Resolve DeliveryData locally
      // ---------------------------------------------------
      final deliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataPbId))
              .build()
              .findFirst();

      if (deliveryData == null) {
        debugPrint('❌ DeliveryData not found locally');
        return;
      }

      debugPrint(
        '✅ DeliveryData resolved → OBX ID: ${deliveryData.objectBoxId}',
      );

      // ---------------------------------------------------
      // 2️⃣ PREVENT DUPLICATE STATUS FOR SAME DELIVERY
      // ---------------------------------------------------
      final alreadyExists = deliveryData.deliveryUpdates.any(
        (u) => u.title?.toLowerCase() == statusChoice.title?.toLowerCase(),
      );

      if (alreadyExists) {
        debugPrint('⚠️ Duplicate status ignored → ${statusChoice.title}');
        return;
      }

      // ---------------------------------------------------
      // 3️⃣ CREATE DELIVERY UPDATE (OFFLINE FIRST)
      // ---------------------------------------------------
      final deliveryUpdate = DeliveryUpdateModel(
        title: statusChoice.title,
        subtitle: statusChoice.subtitle,
        time: DateTime.now(),
        created: DateTime.now(),
        updated: DateTime.now(),
        isAssigned: true,

        // 🔑 REQUIRED FOR REMOTE SYNC
        deliveryDataPbId: deliveryDataPbId,
        statusChoicePbId: statusChoice.id,

        // 🔁 SYNC CONTROL
        syncStatus: SyncStatus.pending.name,
        retryCount: 0,
      );

      // ---------------------------------------------------
      // 4️⃣ LINK LOCAL RELATION
      // ---------------------------------------------------
      deliveryUpdate.deliveryData.target = deliveryData;
      deliveryData.deliveryUpdates.add(deliveryUpdate);

      // ---------------------------------------------------
      // 5️⃣ SAVE LOCALLY (CHILD FIRST)
      // ---------------------------------------------------
      deliveryUpdateBox.put(deliveryUpdate);
      deliveryDataBox.put(deliveryData);

      debugPrint('✅ DeliveryUpdate saved locally (PENDING SYNC)');
      debugPrint('   • Status: ${deliveryUpdate.title}');
      debugPrint('   • deliveryDataPbId: ${deliveryUpdate.deliveryDataPbId}');
      debugPrint('   • statusChoicePbId: ${deliveryUpdate.statusChoicePbId}');
      debugPrint('   • Total updates: ${deliveryData.deliveryUpdates.length}');
    } catch (e, st) {
      debugPrint('❌ ERROR in updateDeliveryStatus(): $e');
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  ) async {
    try {
      debugPrint('💾 Bulk updating delivery status');
      debugPrint('   📦 Customers: $customerIds');
      debugPrint('   🏷️ New Status ID: $statusId');

      // Iterate through each customer
      for (final customerId in customerIds) {
        try {
          final query =
              deliveryUpdateBox
                  .query(DeliveryUpdateModel_.customer.equals(customerId))
                  .build();

          final updates = query.find();
          query.close();

          for (var update in updates) {
            update.isAssigned = true;
            update.id = statusId; // ✅ update status field locally
            await _autoSave(update);
          }

          debugPrint('✅ Local status updated for customer: $customerId');
        } catch (e) {
          debugPrint('⚠️ Failed to update local status for $customerId: $e');
          // continue updating next customer
        }
      }

      debugPrint(
        '🎉 Local bulk update completed for ${customerIds.length} customers',
      );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> completeDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint(
        '💾 LOCAL: Processing delivery completion for delivery: ${deliveryData.id}',
      );

      // 0️⃣ Validate deliveryData ID
      final deliveryDataId = deliveryData.id;
      if (deliveryDataId == null || deliveryDataId.isEmpty) {
        throw const CacheException(message: 'Invalid delivery data ID');
      }

      // 1️⃣ Resolve DeliveryData locally
      final localDeliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataId))
              .build()
              .findFirst();

      if (localDeliveryData == null) {
        throw const CacheException(message: 'DeliveryData not found locally');
      }

      debugPrint(
        '✅ LOCAL: DeliveryData resolved → OBX ID: ${localDeliveryData.objectBoxId}',
      );

      // 2️⃣ Resolve Trip (single source of truth)
      final tripId =
          deliveryData.trip.target?.id ?? localDeliveryData.trip.target?.id;
      TripModel? tripModel;

      if (tripId != null && tripId.isNotEmpty) {
        final tripQuery =
            objectBoxStore.tripBox.query(TripModel_.id.equals(tripId)).build();
        tripModel = tripQuery.findFirst();
        tripQuery.close();
        debugPrint(
          tripModel != null
              ? '🚛 LOCAL: Trip resolved → OBX ID: ${tripModel.objectBoxId}'
              : '⚠️ LOCAL: Trip not found locally for ID: $tripId',
        );
      } else {
        debugPrint('⚠️ LOCAL: Trip ID missing for delivery data');
      }

      // 3️⃣ Resolve "End Delivery" status
      final endStatus =
          deliveryStatusChoicesBox
              .query(DeliveryStatusChoicesModel_.title.equals('End Delivery'))
              .build()
              .findFirst();

      final endStatusResolved =
          endStatus ??
          deliveryStatusChoicesBox.getAll().firstWhere(
            (s) => s.title?.toLowerCase() == 'end delivery',
            orElse:
                () => DeliveryStatusChoicesModel(
                  id: 'end-delivery-local',
                  title: 'End Delivery',
                  subtitle: 'Delivery Completed',
                ),
          );

      // 4️⃣ Create DeliveryUpdate (End Delivery)
      final now = DateTime.now();
      final deliveryUpdate = DeliveryUpdateModel(
        title: endStatusResolved.title ?? 'End Delivery',
        subtitle: endStatusResolved.subtitle ?? 'Delivery Completed',
        time: now,
        created: now,
        updated: now,
        isAssigned: true,
        deliveryDataPbId: deliveryDataId,
        statusChoicePbId: endStatusResolved.id,
        syncStatus: SyncStatus.pending.name,
        retryCount: 0,
      );

      deliveryUpdate.deliveryData.target = localDeliveryData;
      localDeliveryData.deliveryUpdates.add(deliveryUpdate);

      deliveryUpdateBox.put(deliveryUpdate);
      deliveryDataBox.put(localDeliveryData);

      debugPrint('✅ LOCAL: DeliveryUpdate created → ${deliveryUpdate.title}');

      // ---------------------------------------------------
      // 5️⃣ Receipt lookup (OPTIONAL — MUST NOT BLOCK FLOW)
      // ---------------------------------------------------
      try {
        final receiptQuery =
            objectBoxStore.deliveryReceiptBox
                .query(
                  DeliveryReceiptModel_.deliveryData.equals(
                    localDeliveryData.objectBoxId, // ✅ OBX ID only
                  ),
                )
                .build();

        final receipt = receiptQuery.findFirst();
        receiptQuery.close();

        if (receipt != null) {
          debugPrint('🧾 Receipt found → ${receipt.pocketbaseId}');
        } else {
          debugPrint('⚠️ No receipt found (continuing process)');
        }
      } catch (e, st) {
        // ❗ NEVER BLOCK DELIVERY COMPLETION
        debugPrint('⚠️ Receipt lookup failed, ignored → $e\n$st');
      }

      // 6️⃣ Resolve customer + invoices (optional)
      final customerModel = localDeliveryData.customer.target;
      final invoiceList = localDeliveryData.invoices.toList();

      if (customerModel == null)
        debugPrint(
          '⚠️ LOCAL: Customer missing for deliveryData: $deliveryDataId',
        );
      if (invoiceList.isEmpty)
        debugPrint(
          '⚠️ LOCAL: No invoices linked to deliveryData: $deliveryDataId',
        );

      // 7️⃣ Create CollectionModel
      final collection = CollectionModel(
        id: '${deliveryDataId}_collection_${now.millisecondsSinceEpoch}',
        collectionName: 'deliveryCollection',
        deliveryDataModel: localDeliveryData,
        tripData: tripModel,
        customerData: customerModel,
        invoiceData: invoiceList.isNotEmpty ? invoiceList.first : null,
        invoicesList: invoiceList,
        totalAmount:
            localDeliveryData.invoiceItems.isNotEmpty
                ? localDeliveryData.invoiceItems.fold<double>(
                  0.0,
                  (sum, it) => sum + (it.totalAmount ?? 0.0),
                )
                : null,
        created: now,
        updated: now,
      );

      objectBoxStore.deliveryCollectonBox.put(collection);
      debugPrint('✅ LOCAL: Collection created → ${collection.id}');

      // ---------------------------------------------------
      // 8️⃣ Update User Performance (BEST-EFFORT / NON-BLOCKING)
      // ---------------------------------------------------
      try {
        final user = tripModel?.user.target;

        if (user == null) {
          debugPrint(
            '⚠️ LOCAL: Trip user not resolved, skipping UserPerformance update',
          );
        } else {
          final userPerfBox = objectBoxStore.store.box<UserPerformanceModel>();

          final perfQuery =
              userPerfBox
                  .query(UserPerformanceModel_.user.equals(user.objectBoxId))
                  .build();

          final perf = perfQuery.findFirst();
          perfQuery.close();

          if (perf == null) {
            debugPrint(
              '⚠️ LOCAL: No UserPerformance found for user OBX: ${user.objectBoxId}',
            );
          } else {
            final total = perf.totalDeliveries ?? 0;
            final success = perf.successfulDeliveries ?? 0;

            final newTotal = total + 1;
            final newSuccess = success + 1;

            perf
              ..totalDeliveries = newTotal
              ..successfulDeliveries = newSuccess
              ..deliveryAccuracy = (newSuccess / newTotal) * 100
              ..updated = now
              ..lastLocalUpdatedAt = now.toUtc()
              ..syncStatus = SyncStatus.pending.name
              ..version += 1;

            userPerfBox.put(perf);

            debugPrint(
              '✅ LOCAL: UserPerformance updated\n'
              '   User OBX: ${user.objectBoxId}\n'
              '   Total: $total → $newTotal\n'
              '   Success: $success → $newSuccess\n'
              '   Accuracy: ${perf.deliveryAccuracy?.toStringAsFixed(2)}%',
            );
          }
        }
      } catch (e, st) {
        // ❗ NEVER block delivery completion
        debugPrint(
          '⚠️ LOCAL: UserPerformance update failed (ignored) → $e\n$st',
        );
      }

      // ---------------------------------------------------
      // 9️⃣ Update Delivery Team stats (USING TRIP-FIRST LOGIC)
      // ---------------------------------------------------
      try {
        if (tripId == null || tripId.isEmpty) {
          debugPrint(
            '⚠️ LOCAL: Trip PB ID missing, skipping DeliveryTeam update',
          );
        } else {
          // ✅ 1️⃣ Resolve DeliveryTeam USING THE SAME PATTERN
          DeliveryTeamModel? team;

          final tripQuery =
              objectBoxStore.tripBox
                  .query(TripModel_.id.equals(tripId))
                  .build();
          final trip = tripQuery.findFirst();
          tripQuery.close();

          if (trip == null) {
            debugPrint(
              '⚠️ LOCAL: Trip not found, skipping DeliveryTeam update',
            );
          } else {
            for (final t in objectBoxStore.deliveryTeamBox.getAll()) {
              if (t.trip.targetId == trip.objectBoxId) {
                team = t;
                break;
              }
            }

            if (team == null) {
              debugPrint(
                '⚠️ LOCAL: No DeliveryTeam found for Trip OBX: ${trip.objectBoxId}',
              );
            } else {
              final prevActive = team.activeDeliveries ?? 0;
              final prevTotal = team.totalDelivered ?? 0;

              team
                ..activeDeliveries = (prevActive - 1).clamp(0, 999999)
                ..totalDelivered = prevTotal + 1;

              objectBoxStore.deliveryTeamBox.put(team);

              debugPrint(
                '✅ LOCAL: DeliveryTeam updated\n'
                '   Team PB: ${team.id}\n'
                '   Trip OBX: ${trip.objectBoxId}\n'
                '   Active: $prevActive → ${team.activeDeliveries}\n'
                '   Total: $prevTotal → ${team.totalDelivered}',
              );
            }
          }
        }
      } catch (e, st) {
        // ❗ DO NOT BLOCK DELIVERY COMPLETION
        debugPrint('⚠️ LOCAL: DeliveryTeam update failed (ignored) → $e\n$st');
      }

      // 🔟 Update DeliveryData invoice status
      localDeliveryData
        ..invoiceStatus = InvoiceStatus.delivered
        ..updated = now;
      deliveryDataBox.put(localDeliveryData);

      debugPrint(
        '✅ LOCAL: Delivery completed successfully → DeliveryData OBX ID: ${localDeliveryData.objectBoxId}',
      );
    } catch (e, st) {
      debugPrint('❌ LOCAL: CompleteDelivery failed → $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<DataMap> checkEndDeliverStatus(String tripId) async {
    try {
      debugPrint('🔍 LOCAL: Checking end delivery status for trip: $tripId');

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint('⚠️ Trip not found in local DB for tripId: $tripId');
        return {'total': 0, 'completed': 0, 'pending': 0};
      }

      // -------------------------------------------------------------
      // 2️⃣ Get DeliveryData linked to this trip
      // -------------------------------------------------------------
      final deliverySet = <String, DeliveryDataModel>{}; // deduplicate
      for (final d in trip.deliveryData) {
        final fullDD = deliveryDataBox.get(d.objectBoxId);
        if (fullDD != null) {
          deliverySet[fullDD.id ?? ""] = fullDD;
        }
      }

      if (deliverySet.isEmpty) {
        debugPrint('⚠️ No delivery data found for trip: ${trip.name}');
        return {'total': 0, 'completed': 0, 'pending': 0};
      }

      // -------------------------------------------------------------
      // 3️⃣ Calculate delivery status
      // -------------------------------------------------------------
      final allDeliveries = deliverySet.values.toList();
      final totalCustomers = allDeliveries.length;

      final completedDeliveries =
          allDeliveries.where((delivery) {
            return delivery.deliveryUpdates.any((status) {
              final title = status.title?.toLowerCase().trim();
              return title == 'end delivery' || title == 'mark as undelivered';
            });
          }).length;

      debugPrint('📊 LOCAL: Delivery Status Summary for Trip: $tripId');
      debugPrint('   - Total Customers: $totalCustomers');
      debugPrint('   - Completed Deliveries: $completedDeliveries');
      debugPrint(
        '   - Pending Deliveries: ${totalCustomers - completedDeliveries}',
      );

      return {
        'total': totalCustomers,
        'completed': completedDeliveries,
        'pending': totalCustomers - completedDeliveries,
      };
    } catch (e, st) {
      debugPrint('❌ LOCAL: Error checking end delivery status - $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> initializePendingStatus(List<String> customerIds) async {
    try {
      debugPrint('🔄 LOCAL: Initializing pending status');

      for (final customerId in customerIds) {
        final customer =
            deliveryDataBox
                .query(DeliveryDataModel_.pocketbaseId.equals(customerId))
                .build()
                .findFirst();

        if (customer != null) {
          final pendingStatus = DeliveryUpdateModel(
            title: 'Pending',
            subtitle: 'Waiting for delivery',
            isAssigned: true,
            customer: customerId,
            created: DateTime.now(),
          );

          await _autoSave(pendingStatus);
          customer.deliveryUpdates.add(pendingStatus);
          deliveryDataBox.put(customer);
        }
      }

      debugPrint('✅ LOCAL: Successfully initialized pending status');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to initialize pending status - $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  }) async {
    try {
      debugPrint(
        '💾 LOCAL: Creating delivery status for customer: $customerId',
      );

      final newStatus = DeliveryUpdateModel(
        title: title,
        subtitle: subtitle,
        time: time,
        isAssigned: true,
        customer: customerId,
        image: image,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      await _autoSave(newStatus);

      // Update customer's delivery status relation
      final customer =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(customerId))
              .build()
              .findFirst();

      if (customer != null) {
        customer.deliveryUpdates.add(newStatus);
        deliveryDataBox.put(customer);
      }

      debugPrint('✅ LOCAL: Successfully created delivery status');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to create delivery status - $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateQueueRemarks(
    String statusId,
    String remarks,
    String image,
  ) async {
    try {
      debugPrint('💾 LOCAL: Updating queue remarks for status: $statusId');

      // 🔎 Find existing status by ID
      final query =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.id.equals(statusId))
              .build();
      final existingStatus = query.findFirst();
      query.close();

      if (existingStatus == null) {
        throw CacheException(
          message: 'Status with ID $statusId not found locally',
        );
      }

      // 📝 Update fields
      existingStatus.remarks = remarks;
      existingStatus.time = DateTime.now();
      if (image.isNotEmpty) {
        existingStatus.image = image; // just store path locally
      }

      // await _autoSave(existingStatus);

      // 🔄 Update customer relationship if needed
      final customer =
          deliveryDataBox
              .query(
                DeliveryDataModel_.pocketbaseId.equals(
                  existingStatus.customer ?? '',
                ),
              )
              .build()
              .findFirst();

      if (customer != null) {
        final index = customer.deliveryUpdates.indexWhere(
          (u) => u.id == statusId,
        );
        if (index != -1) {
          customer.deliveryUpdates[index] = existingStatus;
          deliveryDataBox.put(customer);
        }
      }

      debugPrint('✅ LOCAL: Queue remarks updated successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to update queue remarks: $e');
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<List<DeliveryUpdateModel>> getPendingSyncList() async {
   final query =
      deliveryUpdateBox
            .query(
              DeliveryUpdateModel_.syncStatus.equals(
                SyncStatus.pending.name,
              ),
            )
            .build();
    final pending = query.find();
    query.close();
    debugPrint('LOCAL 🔄 Pending sync count: ${pending.length}');
    return pending;
  }
  
  @override
  Future<void> markFailed(DeliveryUpdateModel status, String error) async {
    final retryCount = (status.retryCount) + 1;
    final updated = status.copyWith(
      syncStatus: SyncStatus.pending.name,
      retryCount: retryCount,
      lastSyncError: error,
      nextRetryAt: DateTime.now().add(
        Duration(seconds: 2 * retryCount * 2),
      ), // exponential backoff
    );
    deliveryUpdateBox.put(updated);
    debugPrint(
      'LOCAL ⚠️ Sync failed → ${status.title}, retryCount=$retryCount',
    );
  }
  
  @override
  Future<void> markSynced(DeliveryUpdateModel status) async {
    final updated = status.copyWith(
      syncStatus: SyncStatus.synced.name,
      retryCount: 0,
      lastSyncError: null,
    );
    deliveryUpdateBox.put(updated);
    debugPrint('LOCAL ✅ Synced → ${status.title}');
  }
  
  @override
  Future<void> markSyncing(DeliveryUpdateModel status) async {
    final updated = status.copyWith(
      syncStatus: SyncStatus.syncing.name,
      lastSyncAttemptAt: DateTime.now(),
    );
    deliveryUpdateBox.put(updated);
    debugPrint('LOCAL 🔄 Marked syncing → ${status.title}');
  }
}
