import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/enums/sync_status_enums.dart';

import '../../../../../../../../objectbox.g.dart';
import '../../../../../../../enums/invoice_status.dart';
import '../../../../../../../errors/exceptions.dart';
import '../../../../../../../services/objectbox.dart';
import '../../../../delivery_data/delivery_update/data/models/delivery_update_model.dart';
import '../../../../delivery_team/delivery_team/data/models/delivery_team_model.dart';
import '../../../../trip_ticket/delivery_collection/data/model/collection_model.dart';
import '../../../../trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import '../../../../trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import '../../../../trip_ticket/trip/data/models/trip_models.dart';
import '../../../../users/user_performance/data/model/user_performance_model.dart';
import '../../model/delivery_status_choices_model.dart';

abstract class DeliveryStatusChoicesLocalDatasource {
  /// Gets the delivery status choices from the local storage.
  Future<void> saveAllDeliveryStatusChoices(
    List<DeliveryStatusChoicesModel?> rawChoices,
  );

  Future<List<DeliveryStatusChoicesModel>> getDeliveryStatusChoices(
    String deliveryDataId, // ✅ PocketBase ID
  );

  Future<void> updateCustomerStatus(
    String deliveryDataPbId, // DeliveryData PB ID
    DeliveryStatusChoicesModel statusChoice, // ✅ FULL STATUS MODEL
  );

  Future<void> revertUpdateCustomerStatus(
    String deliveryDataPbId, // DeliveryData PB ID
    DeliveryStatusChoicesModel statusChoice, // ✅ FULL STATUS MODEL
  );
  Future<void> setEndDelivery(DeliveryDataEntity deliveryData);

  /// Bulk versions for offline use

  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds);

  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesModel statusChoice,
  );

  /// 🆕 Expose ObjectBox box for sync worker purposes
  Box<DeliveryStatusChoicesModel> get deliveryStatusChoicesBox;

  /// 🆕 Background sync helper methods
  Future<void> markSyncing(DeliveryStatusChoicesModel status);
  Future<void> markSynced(DeliveryStatusChoicesModel status);
  Future<void> markFailed(DeliveryStatusChoicesModel status, String error);
  Future<List<DeliveryStatusChoicesModel>> getPendingSyncList();
}

class DeliveryStatusChoicesLocalDatasourceImpl
    implements DeliveryStatusChoicesLocalDatasource {
  final ObjectBoxStore objectBoxStore;
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;

  @override
  Box<DeliveryStatusChoicesModel> get deliveryStatusChoicesBox =>
      objectBoxStore.deliveryStatusBox;

  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;

  const DeliveryStatusChoicesLocalDatasourceImpl({
    required this.objectBoxStore,
  });

  @override
  Future<void> updateCustomerStatus(
    String deliveryDataPbId, // DeliveryData PB ID
    DeliveryStatusChoicesModel statusChoice, // ✅ FULL STATUS MODEL
  ) async {
    try {
      debugPrint('🔵 START: updateDeliveryStatus()');
      debugPrint('   📌 DeliveryData PB ID: $deliveryDataPbId');
      debugPrint('   🏷️ Status: ${statusChoice.title} (${statusChoice.id})');

      // ---------------------------------------------------
      // 0️⃣ VALIDATE
      // ---------------------------------------------------
      if (statusChoice.id == null || statusChoice.id!.trim().isEmpty) {
        debugPrint('❌ Status PB ID is EMPTY → DATA INTEGRITY ISSUE');
        return;
      }

      // ---------------------------------------------------
      // 🆕 0️⃣-A DEDUPLICATION: Check for existing pending/syncing updates
      // ---------------------------------------------------
      try {
        final duplicateQuery =
            deliveryUpdateBox
                .query(
                  DeliveryUpdateModel_.deliveryDataPbId.equals(
                    deliveryDataPbId,
                  ),
                )
                .build();
        final existingUpdates = duplicateQuery.find();
        duplicateQuery.close();

        // Check if an update with the SAME status is already pending or syncing
        for (final existing in existingUpdates) {
          if (existing.statusChoicePbId == statusChoice.id &&
              (existing.syncStatus == SyncStatus.pending.name ||
                  existing.syncStatus == SyncStatus.syncing.name)) {
            debugPrint(
              '⚠️ DUPLICATE DETECTED: Status "${statusChoice.title}" is already pending/syncing for delivery $deliveryDataPbId',
            );
            debugPrint('   📋 Existing update OBX ID: ${existing.objectBoxId}');
            debugPrint('   🔄 Sync status: ${existing.syncStatus}');
            debugPrint(
              '   ✅ Skipping duplicate update request to prevent duplicate uploads',
            );
            return; // ✅ Exit early - prevent duplicate
          }
        }
        debugPrint('✅ No duplicate pending updates found - proceeding');
      } catch (e) {
        debugPrint('⚠️ Duplicate check failed (non-blocking): $e');
        // Continue anyway if check fails
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

      debugPrint('✅ DeliveryData resolved → OBX ID: ${deliveryData.id}');

      // ---------------------------------------------------
      // 2️⃣ CREATE NEW DeliveryUpdate (COPY DATA)
      // ---------------------------------------------------
      final newUpdate = DeliveryStatusChoicesModel(
        id: statusChoice.id,
        title: statusChoice.title,
        subtitle: statusChoice.subtitle,
        deliveryDataId: deliveryDataPbId, // ✅ IMPORTANT: set deliveryDataId
        syncStatus: SyncStatus.pending.name, // mark pending for sync
        retryCount: 0,
        lastLocalUpdatedAt: DateTime.now(),
      );

      // ---------------------------------------------------
      // 3️⃣ LINK RELATIONS (CRITICAL)
      // ---------------------------------------------------
      final deliveryUpdate = DeliveryUpdateModel(
        title: newUpdate.title,
        subtitle: newUpdate.subtitle,
        time: DateTime.now(),
        isAssigned: true,
        id: '', // ⏳ will be set after remote sync
      );

      // Link the delivery update to the delivery data and mark as pending
      deliveryUpdate.deliveryData.target = deliveryData;
      deliveryUpdate.deliveryDataPbId = deliveryDataPbId;
      deliveryUpdate.statusChoicePbId = statusChoice.id;
      deliveryUpdate.syncStatus = SyncStatus.pending.name;
      deliveryUpdate.retryCount = 0;
      deliveryUpdate.customer = deliveryData.pocketbaseId;
      // Mark local last-updated timestamp so UI can prefer this update
      deliveryUpdate.lastLocalUpdatedAt = DateTime.now();

      // Add to the parent relation and persist
      deliveryData.deliveryUpdates.add(deliveryUpdate);

      // ---------------------------------------------------
      // 4️⃣ SAVE (child → parent)
      // ---------------------------------------------------
      final obxId = deliveryUpdateBox.put(deliveryUpdate);
      // Ensure the parent is aware of the child's persisted instance
      deliveryDataBox.put(deliveryData);

      // Optional: save statusChoice locally for offline sync
      deliveryStatusChoicesBox.put(newUpdate);

      debugPrint('✅ Local DeliveryUpdate CREATED');
      debugPrint('   • Update OBX ID: $obxId');
      debugPrint('   • Update PB ID: ${deliveryUpdate.id}');
      debugPrint('   • Title: ${deliveryUpdate.title}');
      debugPrint('   • Subtitle: ${deliveryUpdate.subtitle}');
      debugPrint('   • Time: ${deliveryUpdate.time}');
      debugPrint('   • Total updates: ${deliveryData.deliveryUpdates.length}');

      // ---------------------------------------------------
      // ✅ Verification: read back persisted deliveryData and child updates
      // ---------------------------------------------------
      try {
        final refreshed = deliveryDataBox.get(deliveryData.objectBoxId);
        if (refreshed == null) {
          debugPrint(
            '🔍 Verification: refreshed deliveryData NOT FOUND for OBX ID: ${deliveryData.objectBoxId}',
          );
        } else {
          debugPrint(
            '🔍 Verification: refreshed deliveryData OBX=${refreshed.objectBoxId} relationCount=${refreshed.deliveryUpdates.length}',
          );

          bool foundNew = false;

          // Directly fetch the saved update by obxId (more reliable than comparing times)
          try {
            final saved = deliveryUpdateBox.get(obxId);
            if (saved != null) {
              debugPrint(
                '   • saved update fetched by OBX=$obxId title=${saved.title} sync=${saved.syncStatus} lastLocal=${saved.lastLocalUpdatedAt} time=${saved.time}',
              );
              // Check if it's part of the refreshed relations
              for (final rel in refreshed.deliveryUpdates) {
                if (rel.objectBoxId == saved.objectBoxId) {
                  foundNew = true;
                  debugPrint(
                    '     ↳ This saved entry is present in refreshed relations (OBX=${saved.objectBoxId})',
                  );
                  break;
                }
              }
            } else {
              debugPrint(
                '   • saved update OBX=$obxId NOT found in deliveryUpdateBox',
              );
            }
          } catch (e, st) {
            debugPrint('   • error fetching saved update by obxId: $e\n$st');
          }

          // Also enumerate relations for visibility
          for (final rel in refreshed.deliveryUpdates) {
            final full = deliveryUpdateBox.get(rel.objectBoxId);
            if (full == null) {
              debugPrint(
                '   • relation entry OBX=${rel.objectBoxId} -> MISSING in box',
              );
              continue;
            }
            debugPrint(
              '   • persisted update OBX=${full.objectBoxId} title=${full.title} sync=${full.syncStatus} lastLocal=${full.lastLocalUpdatedAt} time=${full.time}',
            );
          }

          debugPrint(
            '🔍 Verification: newly created update present in refreshed relations? $foundNew',
          );
        }
      } catch (e, st) {
        debugPrint(
          '🔍 Verification: error while checking persisted relations: $e\n$st',
        );
      }
    } catch (e, st) {
      debugPrint('❌ ERROR in updateDeliveryStatus(): $e');
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }

  /// 🆕 Load Delivery Status Choices locally (offline filtering)
  @override
  Future<List<DeliveryStatusChoicesModel>> getDeliveryStatusChoices(
    String deliveryDataId, // ✅ PocketBase ID
  ) async {
    try {
      final ddId = deliveryDataId.trim();
      debugPrint(
        'LOCAL 🔄 Fetching status choices for DeliveryData PB ID: $ddId',
      );

      // ---------------------------------------------------
      // Helpers
      // ---------------------------------------------------
      String _norm(dynamic v) {
        final s = (v ?? '').toString().trim().toLowerCase();
        if (s.isEmpty) return '';
        // collapse multi-spaces to single
        return s.replaceAll(RegExp(r'\s+'), ' ');
      }

      DateTime _bestTime(DeliveryUpdateModel u) {
        return u.lastLocalUpdatedAt ??
            u.updated ??
            u.time ??
            u.created ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      // ---------------------------------------------------
      // 0️⃣ Resolve DeliveryData
      // ---------------------------------------------------
      final ddQuery =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(ddId))
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
      // 1️⃣ Load DeliveryUpdates (current history)
      // ---------------------------------------------------
      final updates = <DeliveryUpdateModel>[];

      for (final rel in deliveryData.deliveryUpdates) {
        final full = deliveryUpdateBox.get(rel.objectBoxId);
        if (full != null) {
          updates.add(full);
          debugPrint(
            '    📝 ${full.title} | time=${full.time} | updated=${full.updated}',
          );
        }
      }

      // ---------------------------------------------------
      // 2️⃣ Determine latest status (robust)
      // ---------------------------------------------------
      updates.sort((a, b) {
        final at = _bestTime(a);
        final bt = _bestTime(b);
        final cmp = at.compareTo(bt);
        if (cmp != 0) return cmp;

        // tie-breaker to stabilize ordering
        return a.objectBoxId.compareTo(b.objectBoxId);
      });

      final latestStatus = updates.isNotEmpty ? _norm(updates.last.title) : '';
      debugPrint('LOCAL 📍 Latest status: "$latestStatus"');

      // If no status yet, treat as "in transit" start (optional)
      // If your flow always starts at "In Transit", keep this.
      final effectiveLatest =
          latestStatus.isEmpty ? 'in transit' : latestStatus;

      // ---------------------------------------------------
      // 3️⃣ Load cached DeliveryStatusChoices
      // ---------------------------------------------------
      final allStatuses = deliveryStatusChoicesBox.getAll();
      if (allStatuses.isEmpty) {
        debugPrint('LOCAL ⚠️ No cached deliveryStatusChoices found');
        return [];
      }

      // ---------------------------------------------------
      // 4️⃣ Determine allowed transitions (match your rules)
      // ---------------------------------------------------
      final allowedTitles = <String>[];

      switch (effectiveLatest) {
        case 'in transit':
          allowedTitles.addAll(['arrived', 'mark as undelivered']);
          break;

        case 'arrived':
          allowedTitles.addAll([
            'unloading',
            'mark as undelivered',
            'waiting for customer',
            'invoices in queue',
          ]);
          break;

        case 'waiting for customer':
          allowedTitles.addAll([
            'unloading',
            'mark as undelivered',
            'invoices in queue',
          ]);
          break;

        case 'invoices in queue':
          allowedTitles.addAll(['unloading', 'mark as undelivered']);
          break;

        case 'unloading':
          allowedTitles.addAll(['mark as received']);
          break;

        case 'mark as received':
          allowedTitles.addAll(['end delivery']);
          break;

        case 'mark as undelivered':
        case 'end delivery':
          return [];

        default:
          // Unknown status → safest fallback
          debugPrint(
            'LOCAL ⚠️ Unknown latest status "$effectiveLatest" - using safe fallback',
          );
          allowedTitles.addAll(['mark as undelivered']);
          break;
      }

      // ---------------------------------------------------
      // ✅ FIX 5️⃣ Exclude only CURRENT status (not full history)
      // ---------------------------------------------------
      // This prevents “Arrived” -> user taps again -> still seeing valid choices
      // even if “Waiting for Customer” existed earlier in history.
      final blockedTitles = <String>{};
      if (effectiveLatest.isNotEmpty) blockedTitles.add(effectiveLatest);

      // ---------------------------------------------------
      // 6️⃣ FILTER + DEDUP
      // ---------------------------------------------------
      final Map<String, DeliveryStatusChoicesModel> unique = {};

      for (final status in allStatuses) {
        if (status.id == null || status.title == null) continue;

        final titleLower = _norm(status.title);

        if (!allowedTitles.contains(titleLower)) continue;
        if (blockedTitles.contains(titleLower)) continue;

        // Dedup by PB id
        if (unique.containsKey(status.id)) {
          debugPrint('⚠️ Duplicate filtered out → ${status.title}');
          continue;
        }

        debugPrint(
          'LOCAL 🟢 Allowed → ${status.title} (${status.collectionName})',
        );

        unique[status.id!] = DeliveryStatusChoicesModel(
          id: status.id,
          title: status.title,
          subtitle: status.subtitle,
          collectionId: status.collectionId,
          collectionName: status.collectionName,
        );
      }

      // Optional: keep same order as allowedTitles list
      final result =
          unique.values.toList()..sort((a, b) {
            final ia = allowedTitles.indexOf(_norm(a.title));
            final ib = allowedTitles.indexOf(_norm(b.title));
            return ia.compareTo(ib);
          });

      debugPrint('LOCAL ✅ Final choices count: ${result.length}');
      return result;
    } catch (e, st) {
      debugPrint('LOCAL ❌ Error in getDeliveryStatusChoices: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  /// 🆕 Bulk offline fetch of status choices for multiple customers
  @override
  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds) async {
    final Map<String, List<DeliveryStatusChoicesModel>> result = {};

    try {
      debugPrint(
        'LOCAL 🔄 Bulk fetching status choices for customers: $customerIds',
      );

      // ---------------------------------------------------
      // Helpers
      // ---------------------------------------------------
      String _norm(dynamic v) {
        final s = (v ?? '').toString().trim().toLowerCase();
        if (s.isEmpty) return '';
        return s.replaceAll(RegExp(r'\s+'), ' ');
      }

      DateTime _bestTime(DeliveryUpdateModel u) {
        return u.lastLocalUpdatedAt ??
            u.updated ??
            u.time ??
            u.created ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      // Load cached choices once
      final allStatuses = deliveryStatusChoicesBox.getAll();
      if (allStatuses.isEmpty) {
        debugPrint('LOCAL ⚠️ No cached deliveryStatusChoices found (bulk)');
        for (final id in customerIds) {
          result[id] = [];
        }
        return result;
      }

      for (final rawCustomerId in customerIds) {
        final customerId = rawCustomerId.trim();

        try {
          debugPrint('LOCAL 🔄 Bulk: resolving DeliveryData for $customerId');

          // ---------------------------------------------------
          // 0️⃣ Resolve DeliveryData
          // ---------------------------------------------------
          final ddQuery =
              deliveryDataBox
                  .query(DeliveryDataModel_.pocketbaseId.equals(customerId))
                  .build();
          final deliveryData = ddQuery.findFirst();
          ddQuery.close();

          if (deliveryData == null) {
            debugPrint('LOCAL ⚠️ DeliveryData not found for $customerId');
            result[customerId] = [];
            continue;
          }

          // ---------------------------------------------------
          // 1️⃣ Load DeliveryUpdates
          // ---------------------------------------------------
          final updates = <DeliveryUpdateModel>[];
          for (final rel in deliveryData.deliveryUpdates) {
            final full = deliveryUpdateBox.get(rel.objectBoxId);
            if (full != null) updates.add(full);
          }

          // ---------------------------------------------------
          // 2️⃣ Determine latest status (robust)
          // ---------------------------------------------------
          updates.sort((a, b) {
            final at = _bestTime(a);
            final bt = _bestTime(b);
            final cmp = at.compareTo(bt);
            if (cmp != 0) return cmp;
            return a.objectBoxId.compareTo(b.objectBoxId);
          });

          final latestStatus =
              updates.isNotEmpty ? _norm(updates.last.title) : '';
          final effectiveLatest =
              latestStatus.isEmpty ? 'in transit' : latestStatus;

          debugPrint(
            'LOCAL 📍 Bulk: latest status for $customerId = "$effectiveLatest"',
          );

          // ---------------------------------------------------
          // 3️⃣ Determine allowed transitions (MATCH single function)
          // ---------------------------------------------------
          final allowedTitles = <String>[];

          switch (effectiveLatest) {
            case 'in transit':
              allowedTitles.addAll(['arrived']);
              break;

            case 'arrived':
              allowedTitles.addAll([
                'unloading',

                'waiting for customer',
                'invoices in queue',
              ]);
              break;

            case 'waiting for customer':
              allowedTitles.addAll(['unloading', 'invoices in queue']);
              break;

            case 'invoices in queue':
              allowedTitles.addAll(['unloading']);
              break;

            case 'unloading':
              allowedTitles.addAll(['mark as received']);
              break;

            case 'mark as received':
              allowedTitles.addAll([]);
              break;

            case 'mark as undelivered':
            case 'end delivery':
              result[customerId] = [];
              continue;

            default:
              debugPrint(
                'LOCAL ⚠️ Bulk: unknown status "$effectiveLatest" for $customerId',
              );
              allowedTitles.addAll(['mark as undelivered']);
              break;
          }

          // ---------------------------------------------------
          // ✅ FIX: Block only CURRENT status (not full history)
          // ---------------------------------------------------
          final blockedTitles = <String>{};
          if (effectiveLatest.isNotEmpty) blockedTitles.add(effectiveLatest);

          // ---------------------------------------------------
          // 4️⃣ Filter + dedup
          // ---------------------------------------------------
          final Map<String, DeliveryStatusChoicesModel> unique = {};

          for (final status in allStatuses) {
            if (status.id == null || status.title == null) continue;

            final titleLower = _norm(status.title);

            if (!allowedTitles.contains(titleLower)) continue;
            if (blockedTitles.contains(titleLower)) continue;

            if (unique.containsKey(status.id)) continue;

            unique[status.id!] = DeliveryStatusChoicesModel(
              id: status.id,
              title: status.title,
              subtitle: status.subtitle,
              collectionId: status.collectionId,
              collectionName: status.collectionName,
            );
          }

          // Keep order same as allowedTitles
          final out =
              unique.values.toList()..sort((a, b) {
                final ia = allowedTitles.indexOf(_norm(a.title));
                final ib = allowedTitles.indexOf(_norm(b.title));
                return ia.compareTo(ib);
              });

          result[customerId] = out;

          debugPrint(
            'LOCAL ✅ Bulk: prepared ${out.length} choices for $customerId',
          );
        } catch (e, st) {
          debugPrint('LOCAL ❌ Bulk: failed for $customerId: $e\n$st');
          result[customerId] = [];
        }
      }

      return result;
    } catch (e, st) {
      debugPrint('LOCAL ❌ Error in bulk fetch: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  /// 🆕 Bulk offline update: create pending updates locally for a list of customers
  @override
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesModel statusChoice,
  ) async {
    try {
      debugPrint(
        'LOCAL 🔄 Bulk updating customers: $customerIds with status: ${statusChoice.title}',
      );

      if (statusChoice.id == null || statusChoice.id!.trim().isEmpty) {
        debugPrint('LOCAL ⚠️ Invalid status PB ID provided');
        return;
      }

      // ---------------------------------------------------
      // 🆕 DEDUPLICATION: Filter out customers with existing pending updates
      // ---------------------------------------------------
      final customersToUpdate = <String>[];
      final skippedCustomers = <String>[];

      for (final customerId in customerIds) {
        try {
          final checkQuery =
              deliveryUpdateBox
                  .query(
                    DeliveryUpdateModel_.deliveryDataPbId.equals(customerId),
                  )
                  .build();
          final existingUpdates = checkQuery.find();
          checkQuery.close();

          // Check if this status is already pending/syncing
          final hasDuplicate = existingUpdates.any(
            (u) =>
                u.statusChoicePbId == statusChoice.id &&
                (u.syncStatus == SyncStatus.pending.name ||
                    u.syncStatus == SyncStatus.syncing.name),
          );

          if (hasDuplicate) {
            skippedCustomers.add(customerId);
            debugPrint(
              'LOCAL ⚠️ Skipping $customerId - duplicate pending "${statusChoice.title}" already exists',
            );
          } else {
            customersToUpdate.add(customerId);
          }
        } catch (e) {
          debugPrint('LOCAL ⚠️ Error checking duplicates for $customerId: $e');
          customersToUpdate.add(customerId); // Try anyway
        }
      }

      debugPrint(
        'LOCAL 📊 Processing ${customersToUpdate.length} customers (${skippedCustomers.length} duplicates skipped)',
      );

      // Process only non-duplicate customers
      for (final customerId in customersToUpdate) {
        try {
          await updateCustomerStatus(customerId, statusChoice);
          debugPrint('LOCAL ✅ Queued update for $customerId');
        } catch (e, st) {
          debugPrint(
            'LOCAL ⚠️ Failed to queue update for $customerId: $e\n$st',
          );
          // continue with next customer
        }
      }

      debugPrint(
        'LOCAL 🎉 Bulk enqueue completed for ${customersToUpdate.length} customers (${skippedCustomers.length} skipped)',
      );
    } catch (e, st) {
      debugPrint('LOCAL ❌ Bulk enqueue failed: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> saveAllDeliveryStatusChoices(
    List<DeliveryStatusChoicesModel?> rawChoices,
  ) async {
    try {
      debugPrint('💽 [LOCAL SAVE] Saving Delivery Status Choices...');

      // ---------------------------------------------------
      // 0️⃣ CLEAN INPUT (nulls + duplicates from API)
      // ---------------------------------------------------
      final incomingChoices = sanitizeChoices(rawChoices);

      // ---------------------------------------------------
      // 1️⃣ REMOVE DUPLICATES ALREADY IN OBJECTBOX
      // ---------------------------------------------------
      final allLocal = deliveryStatusChoicesBox.getAll();
      final Map<String, List<DeliveryStatusChoicesModel>> grouped = {};

      for (final item in allLocal) {
        if (item.id == null) continue;
        grouped.putIfAbsent(item.id!, () => []).add(item);
      }

      for (final entry in grouped.entries) {
        if (entry.value.length > 1) {
          debugPrint(
            '🧨 Removing ${entry.value.length - 1} duplicate(s) for PB ID: ${entry.key}',
          );

          // Keep the first, remove the rest
          final duplicates = entry.value.skip(1);
          for (final dup in duplicates) {
            deliveryStatusChoicesBox.remove(dup.objectBoxId);
            debugPrint('🗑️ Removed duplicate OBX ID: ${dup.objectBoxId}');
          }
        }
      }

      // ---------------------------------------------------
      // 2️⃣ UPSERT CLEAN CHOICES
      // ---------------------------------------------------
      final Map<String, DeliveryStatusChoicesModel> uniqueMap = {};

      for (final choice in incomingChoices) {
        debugPrint(
          '📌 Saving StatusChoice → ${choice.title} | PB: ${choice.id}',
        );

        final existing =
            deliveryStatusChoicesBox
                .query(DeliveryStatusChoicesModel_.id.equals(choice.id!))
                .build()
                .findFirst();

        DeliveryStatusChoicesModel fresh;

        if (existing != null) {
          debugPrint(
            '🔁 Existing found → updating OBX: ${existing.objectBoxId}',
          );

          fresh = deliveryStatusChoicesBox.get(existing.objectBoxId)!;

          fresh
            ..id = choice.id
            ..collectionName = choice.collectionName
            ..title = choice.title
            ..subtitle = choice.subtitle
            ..created = choice.created
            ..updated = choice.updated;
        } else {
          debugPrint('➕ Creating new deliveryStatusChoice → PB: ${choice.id}');

          fresh =
              DeliveryStatusChoicesModel()
                ..id = choice.id
                ..title = choice.title
                ..subtitle = choice.subtitle
                ..collectionName = choice.collectionName
                ..created = choice.created
                ..updated = choice.updated;
        }

        final obxId = deliveryStatusChoicesBox.put(fresh);
        uniqueMap[fresh.id!] = deliveryStatusChoicesBox.get(obxId)!;

        debugPrint('   ✔ Saved OBX: $obxId → ${fresh.title}');
      }

      debugPrint(
        '✅ [LOCAL SAVE COMPLETE] ${uniqueMap.length} UNIQUE status choices saved.',
      );
    } catch (e, st) {
      debugPrint(
        '❌ [LOCAL SAVE ERROR] Failed to save delivery status choices: $e',
      );
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }

  /// Removes null items and removes duplicates by PocketBase id.
  List<DeliveryStatusChoicesModel> sanitizeChoices(
    List<DeliveryStatusChoicesModel?> rawList,
  ) {
    final cleaned = <DeliveryStatusChoicesModel>[];

    final seenIds = <String>{};

    for (final item in rawList) {
      if (item == null) continue; // remove nulls
      if (item.id == null) continue; // must have PB id

      if (seenIds.contains(item.id)) {
        debugPrint('⚠️ Duplicate ignored → ${item.title} (${item.id})');
        continue;
      }

      seenIds.add(item.id!);
      cleaned.add(item);
    }

    debugPrint('🧹 Sanitized: ${cleaned.length} unique status choices kept.');
    return cleaned;
  }

  /// 🆕 Fetch all DeliveryStatusChoices pending sync
  Future<List<DeliveryStatusChoicesModel>> getPendingStatusChoices() async {
    final query =
        deliveryStatusChoicesBox
            .query(
              DeliveryStatusChoicesModel_.syncStatus.equals(
                SyncStatus.pending.name,
              ),
            )
            .build();
    final pending = query.find();
    query.close();
    debugPrint('LOCAL 🔄 Pending sync count: ${pending.length}');
    return pending;
  }

  /// 🆕 Mark a status as syncing (in-progress)
  @override
  Future<void> markSyncing(DeliveryStatusChoicesModel status) async {
    final updated = status.copyWith(
      syncStatus: SyncStatus.syncing.name,
      lastSyncAttemptAt: DateTime.now(),
    );
    deliveryStatusChoicesBox.put(updated);
    debugPrint('LOCAL 🔄 Marked syncing → ${status.title}');
  }

  /// 🆕 Mark a status as successfully synced
  @override
  Future<void> markSynced(DeliveryStatusChoicesModel status) async {
    final updated = status.copyWith(
      syncStatus: SyncStatus.synced.name,
      retryCount: 0,
      lastSyncError: null,
    );
    deliveryStatusChoicesBox.put(updated);
    debugPrint('LOCAL ✅ Synced → ${status.title}');
  }

  /// 🆕 Mark a status as failed sync with retry logic
  @override
  Future<void> markFailed(
    DeliveryStatusChoicesModel status,
    String error,
  ) async {
    final retryCount = (status.retryCount) + 1;
    final updated = status.copyWith(
      syncStatus: SyncStatus.pending.name,
      retryCount: retryCount,
      lastSyncError: error,
      nextRetryAt: DateTime.now().add(
        Duration(seconds: 2 * retryCount * 2),
      ), // exponential backoff
    );
    deliveryStatusChoicesBox.put(updated);
    debugPrint(
      'LOCAL ⚠️ Sync failed → ${status.title}, retryCount=$retryCount',
    );
  }

  @override
  Future<List<DeliveryStatusChoicesModel>> getPendingSyncList() async {
    final all = deliveryStatusChoicesBox.getAll();
    return all
        .where(
          (s) =>
              s.syncStatus == SyncStatus.pending.name ||
              s.syncStatus == SyncStatus.failed.name,
        )
        .toList();
  }

  @override
  Future<void> setEndDelivery(DeliveryDataEntity deliveryData) async {
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
  Future<void> revertUpdateCustomerStatus(
    String deliveryDataPbId,
    DeliveryStatusChoicesModel statusChoice,
  ) async {
    try {
      debugPrint('🔄 START: revertUpdateCustomerStatus()');
      debugPrint('   📌 DeliveryData PB ID: $deliveryDataPbId');

      // ---------------------------------------------------
      // 1️⃣ RESOLVE DELIVERY DATA
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
      debugPrint(
        '📊 Current updates count: ${deliveryData.deliveryUpdates.length}',
      );

      // ---------------------------------------------------
      // 2️⃣ CHECK IF THERE IS A STATUS TO REVERT
      // ---------------------------------------------------
      if (deliveryData.deliveryUpdates.isEmpty) {
        debugPrint('⚠️ No delivery updates to revert');
        return;
      }

      // ---------------------------------------------------
      // 🔥 3️⃣ GET LAST UPDATE (LATEST)
      // ---------------------------------------------------
      final lastUpdate = deliveryData.deliveryUpdates.last;

      debugPrint(
        '🗑️ Reverting LAST update → OBX=${lastUpdate.objectBoxId}, '
        'title=${lastUpdate.title}',
      );

      // ---------------------------------------------------
      // 🔥 4️⃣ REMOVE FROM RELATION FIRST
      // ---------------------------------------------------
      deliveryData.deliveryUpdates.removeLast();

      // ---------------------------------------------------
      // 🔥 5️⃣ DELETE FROM BOX
      // ---------------------------------------------------
      try {
        deliveryUpdateBox.remove(lastUpdate.objectBoxId);
        debugPrint('🗑️ Deleted deliveryUpdate from box');
      } catch (e) {
        debugPrint('⚠️ Failed to delete update from box: $e');
      }

      // ---------------------------------------------------
      // 6️⃣ SAVE DELIVERY DATA (VERY IMPORTANT)
      // ---------------------------------------------------
      deliveryDataBox.put(deliveryData);

      debugPrint(
        '✅ Revert completed → remaining updates: ${deliveryData.deliveryUpdates.length}',
      );

      // ---------------------------------------------------
      // 🔍 VERIFICATION (OPTIONAL BUT GOOD)
      // ---------------------------------------------------
      try {
        final refreshed = deliveryDataBox.get(deliveryData.objectBoxId);

        if (refreshed != null) {
          debugPrint(
            '🔍 Verification: refreshed updates count=${refreshed.deliveryUpdates.length}',
          );

          for (final rel in refreshed.deliveryUpdates) {
            final full = deliveryUpdateBox.get(rel.objectBoxId);

            debugPrint(
              '   • remaining update OBX=${rel.objectBoxId} '
              'title=${full?.title} time=${full?.time}',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Verification failed: $e');
      }
    } catch (e, st) {
      debugPrint('❌ ERROR in revertUpdateCustomerStatus(): $e');
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }
}
