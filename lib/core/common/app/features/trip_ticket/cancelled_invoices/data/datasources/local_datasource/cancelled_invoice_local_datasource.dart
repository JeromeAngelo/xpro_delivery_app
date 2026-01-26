import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../../objectbox.g.dart';
import '../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../../../services/objectbox.dart';
import '../../../../../delivery_data/customer_data/data/model/customer_data_model.dart';
import '../../../../../delivery_data/invoice_data/data/model/invoice_data_model.dart';
import '../../../../../delivery_team/delivery_team/data/models/delivery_team_model.dart';
import '../../../../../users/user_performance/data/model/user_performance_model.dart';

abstract class CancelledInvoiceLocalDataSource {
  /// 🆕 Background sync helper methods
  Future<void> markSyncing(CancelledInvoiceModel cancelledInvoice);
  Future<void> markSynced(CancelledInvoiceModel cancelledInvoice);
  Future<void> markFailed(CancelledInvoiceModel cancelledInvoice, String error);
  Future<List<CancelledInvoiceModel>> getPendingSyncList();
  // Get all cancelled invoices
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices();

  /// Load cancelled invoices by trip ID from local storage
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  );
  Future<List<CancelledInvoiceModel>> forceLoadCancelledInvoicesByTripId(
    String tripId,
  );

  /// Load cancelled invoice by ID from local storage (returns single item)
  Future<CancelledInvoiceModel> loadCancelledInvoicesById(String id);

  /// Create cancelled invoice by delivery data ID in local storage
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
    String deliveryDataId,
  );

  /// Delete cancelled invoice from local storage
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId);

  /// Cache cancelled invoices to local storage
  Future<void> cacheCancelledInvoices(
    List<CancelledInvoiceModel> cancelledInvoices,
  );
  Box<CancelledInvoiceModel> get cancelledInvoiceBox;

  /// Update cancelled invoice in local storage
  Future<void> updateCancelledInvoice(CancelledInvoiceModel cancelledInvoice);
}

class CancelledInvoiceLocalDataSourceImpl
    implements CancelledInvoiceLocalDataSource {
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;

  @override
  Box<CancelledInvoiceModel> get cancelledInvoiceBox =>
      objectBoxStore.cancelledInvoiceBox;

  final ObjectBoxStore objectBoxStore;
  List<CancelledInvoiceModel>? _cachedCancelledInvoices;

  CancelledInvoiceLocalDataSourceImpl(this.objectBoxStore);

  @override
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices() async {
    try {
      debugPrint('📱 LOCAL: Fetching all cancelled invoices');

      final cancelledInvoices = cancelledInvoiceBox.getAll();

      debugPrint('📊 Storage Stats:');
      debugPrint(
        'Total stored cancelled invoices: ${cancelledInvoiceBox.count()}',
      );
      debugPrint('Found cancelled invoices: ${cancelledInvoices.length}');

      // Set up relations for each cancelled invoice
      for (final cancelledInvoice in cancelledInvoices) {
        _setupRelations(cancelledInvoice);
      }

      _cachedCancelledInvoices = cancelledInvoices;
      return cancelledInvoices;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<CancelledInvoiceModel>> forceLoadCancelledInvoicesByTripId(
    String tripId,
  ) async {
    try {
      debugPrint(
        '🔁 LOCAL: Force loading cancelled invoices for tripId=$tripId',
      );

      // -------------------------------------------------------------
      // 1️⃣ Load cancelled invoices using the existing loader
      //     (ensures basic relations are already resolved)
      // -------------------------------------------------------------
      final cancelledInvoices = await loadCancelledInvoicesByTripId(tripId);

      if (cancelledInvoices.isEmpty) {
        debugPrint('🔁 LOCAL: No cancelled invoices found for tripId=$tripId');
        return [];
      }

      // -------------------------------------------------------------
      // 2️⃣ For each cancelled invoice, re-query by its own ID
      // -------------------------------------------------------------
      for (final invoice in cancelledInvoices) {
        try {
          final invoiceId = invoice.id;
          if (invoiceId == null || invoiceId.isEmpty) continue;

          // Re-query cancelledInvoiceBox by this invoice's ID
          final q =
              cancelledInvoiceBox
                  .query(CancelledInvoiceModel_.id.equals(invoiceId))
                  .build();
          final found = q.find();
          q.close();

          if (found.isEmpty) {
            debugPrint(
              '⚠️ LOCAL: No rows found for cancelled invoice OBX=${invoice.objectBoxId}, ID=$invoiceId',
            );
            continue;
          }

          // ---------------------------------------------------------
          // Sort by preferred timestamp (lastLocalUpdatedAt -> updated -> created)
          // ---------------------------------------------------------
          found.sort((a, b) {
            final ta = a.lastLocalUpdatedAt ?? a.updated ?? a.created;
            final tb = b.lastLocalUpdatedAt ?? b.updated ?? b.created;

            if (ta == null && tb == null) return 0;
            if (ta == null) return -1;
            if (tb == null) return 1;
            return ta.compareTo(tb);
          });

          // ---------------------------------------------------------
          // Reattach to Trip (ToMany normalization) for UI watchers
          // ---------------------------------------------------------
          final trip = invoice.trip.target;
          if (trip != null) {
            // Remove old instance(s) and add freshly loaded invoice
            trip.cancelledInvoices.removeWhere((e) => e.id == invoiceId);
            trip.cancelledInvoices.addAll(found);

            // Persist parent → notifies listeners
            tripBox.put(trip);

            debugPrint(
              '🔁 LOCAL: Trip ${trip.name} refreshed with ${found.length} instance(s) of cancelled invoice ID=$invoiceId',
            );
          } else {
            debugPrint('⚠️ LOCAL: Invoice ID=$invoiceId has no linked trip');
          }

          // Persist the invoice(s) themselves
          cancelledInvoiceBox.putMany(found);

          debugPrint(
            '🔁 LOCAL: Cancelled invoice ID=$invoiceId refreshed successfully',
          );
        } catch (e) {
          debugPrint(
            '❌ LOCAL: Failed to reload cancelled invoice OBX=${invoice.objectBoxId}: $e',
          );
        }
      }

      debugPrint(
        '🔁 LOCAL: Force load cancelled invoices complete for tripId=$tripId',
      );

      return cancelledInvoices;
    } catch (e, st) {
      debugPrint('❌ forceLoadCancelledInvoicesByTripId ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  ) async {
    try {
      debugPrint("📥 LOCAL loadCancelledInvoicesByTripId() tripId = $tripId");

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint("⚠️ Trip not found in local DB for tripId: $tripId");
        return [];
      }
      await _cleanCancelledInvoices();
      // -------------------------------------------------------------
      // 2️⃣ Get CancelledInvoices linked to this trip
      // -------------------------------------------------------------
      final cancelledSet = <String, CancelledInvoiceModel>{}; // dedupe by PB id

      for (final ci in trip.cancelledInvoices) {
        final fullCI = cancelledInvoiceBox.get(ci.objectBoxId);
        if (fullCI != null) {
          cancelledSet[fullCI.id ?? ""] = fullCI;
        }
      }

      if (cancelledSet.isEmpty) {
        debugPrint("⚠️ No cancelled invoices found for trip: ${trip.name}");
        return [];
      }

      final output = <CancelledInvoiceModel>[];

      // -------------------------------------------------------------
      // 3️⃣ Load nested relations safely
      // -------------------------------------------------------------
      for (final cancelled in cancelledSet.values) {
        debugPrint(
          "📄 Loading relations for CancelledInvoice → ${cancelled.id}",
        );

        // 🚚 DeliveryData
        final dd = cancelled.deliveryData.target;
        if (dd != null) {
          final fullDD = deliveryDataBox.get(dd.objectBoxId);
          if (fullDD != null) {
            cancelled.deliveryData.target = fullDD;
            cancelled.deliveryData.targetId = fullDD.objectBoxId;
            debugPrint("🚚 DeliveryData loaded → ${fullDD.id}");
          }
        }

        // 👤 Customer
        final customer = cancelled.customer.target;
        if (customer != null) {
          final fullCustomer = customerBox.get(customer.objectBoxId);
          if (fullCustomer != null) {
            cancelled.customer.target = fullCustomer;
            cancelled.customer.targetId = fullCustomer.objectBoxId;
            debugPrint("👤 Customer loaded → ${fullCustomer.name}");
          }
        }

        // 🧾 Primary Invoice
        final invoice = cancelled.invoice.target;
        if (invoice != null) {
          final fullInvoice = invoiceBox.get(invoice.objectBoxId);
          if (fullInvoice != null) {
            cancelled.invoice.target = fullInvoice;
            cancelled.invoice.targetId = fullInvoice.objectBoxId;
            debugPrint("🧾 Invoice loaded → ${fullInvoice.id}");
          }
        }

        // 📑 Multiple Invoices
        final invoiceList = <InvoiceDataModel>[];
        for (final inv in cancelled.invoices) {
          final fullInv = invoiceBox.get(inv.objectBoxId);
          if (fullInv != null) invoiceList.add(fullInv);
        }
        cancelled.invoices
          ..clear()
          ..addAll(invoiceList);

        debugPrint(
          "✅ CancelledInvoice ready → ${cancelled.id} "
          "(${cancelled.invoices.length} invoices)",
        );

        output.add(cancelled);
      }

      debugPrint(
        "📦 Found ${output.length} cancelled invoices linked to trip: ${trip.name}",
      );
      return output;
    } catch (e, st) {
      debugPrint("❌ loadCancelledInvoicesByTripId ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<CancelledInvoiceModel> loadCancelledInvoicesById(String id) async {
    try {
      debugPrint('📱 LOCAL: Fetching cancelled invoice by ID: $id');

      // -----------------------------------------------------
      // 1️⃣ Query CancelledInvoice by PocketBase ID
      // -----------------------------------------------------
      final query =
          cancelledInvoiceBox
              .query(CancelledInvoiceModel_.pocketbaseId.equals(id))
              .build();
      final cancelledInvoice = query.findFirst();
      query.close();

      if (cancelledInvoice == null) {
        debugPrint('⚠️ CancelledInvoice not found for ID: $id');
        throw const CacheException(
          message: 'Cancelled invoice not found in local storage',
        );
      }

      debugPrint('📦 CancelledInvoice found → ${cancelledInvoice.id}');

      // -----------------------------------------------------
      // 2️⃣ Load DeliveryData (ToOne)
      // -----------------------------------------------------
      final ddRef = cancelledInvoice.deliveryData.target;
      if (ddRef != null) {
        final fullDD = deliveryDataBox.get(ddRef.objectBoxId);
        if (fullDD != null) {
          cancelledInvoice.deliveryData.target = fullDD;
          cancelledInvoice.deliveryData.targetId = fullDD.objectBoxId;
          debugPrint('🚚 DeliveryData loaded → ${fullDD.id}');
        } else {
          debugPrint(
            '⚠️ DeliveryData reference exists but cannot load full object',
          );
        }
      } else {
        debugPrint('⚠️ No DeliveryData assigned');
      }

      // -----------------------------------------------------
      // 3️⃣ Load Customer (ToOne)
      // -----------------------------------------------------
      final customerRef = cancelledInvoice.customer.target;
      if (customerRef != null) {
        final fullCustomer = customerBox.get(customerRef.objectBoxId);
        if (fullCustomer != null) {
          cancelledInvoice.customer.target = fullCustomer;
          cancelledInvoice.customer.targetId = fullCustomer.objectBoxId;
          debugPrint('👤 Customer loaded → ${fullCustomer.name}');
        } else {
          debugPrint(
            '⚠️ Customer reference exists but cannot load full object',
          );
        }
      } else {
        debugPrint('⚠️ No customer assigned');
      }

      // -----------------------------------------------------
      // 4️⃣ Load Primary Invoice (ToOne)
      // -----------------------------------------------------
      final invoiceRef = cancelledInvoice.invoice.target;
      if (invoiceRef != null) {
        final fullInvoice = invoiceBox.get(invoiceRef.objectBoxId);
        if (fullInvoice != null) {
          cancelledInvoice.invoice.target = fullInvoice;
          cancelledInvoice.invoice.targetId = fullInvoice.objectBoxId;
          debugPrint('🧾 Invoice loaded → ${fullInvoice.id}');
        } else {
          debugPrint('⚠️ Invoice reference exists but cannot load full object');
        }
      } else {
        debugPrint('⚠️ No primary invoice assigned');
      }

      // -----------------------------------------------------
      // 5️⃣ Load Invoices (ToMany)
      // -----------------------------------------------------
      final invoices = cancelledInvoice.invoices;
      if (invoices.isNotEmpty) {
        for (var i = 0; i < invoices.length; i++) {
          final inv = invoices[i];
          final fullInv = invoiceBox.get(inv.objectBoxId);
          if (fullInv != null) {
            invoices[i] = fullInv;
            debugPrint('📄 Invoice loaded → ${fullInv.id}');
          } else {
            debugPrint('⚠️ Invoice not found → OBX ID: ${inv.objectBoxId}');
          }
        }
      } else {
        debugPrint('⚠️ No invoices for this cancelled invoice');
      }

      debugPrint('✅ CancelledInvoice fully loaded with expected relations');
      return cancelledInvoice;
    } catch (e) {
      debugPrint('❌ LOCAL: loadCancelledInvoicesById error: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel input,
    String deliveryDataId,
  ) async {
    try {
      debugPrint('📱 LOCAL: Creating cancelled invoice (offline-first)');

      final now = DateTime.now();

      // --------------------------------------------------
      // 0️⃣ Validate deliveryData ID
      // --------------------------------------------------
      if (deliveryDataId.isEmpty) {
        throw const CacheException(message: 'Invalid delivery data ID');
      }

      // --------------------------------------------------
      // 1️⃣ Resolve DeliveryData LOCALLY
      // --------------------------------------------------
      final deliveryQuery =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataId))
              .build();

      final localDeliveryData = deliveryQuery.findFirst();
      deliveryQuery.close();

      if (localDeliveryData == null) {
        throw const CacheException(message: 'DeliveryData not found locally');
      }

      debugPrint(
        '✅ LOCAL: DeliveryData resolved → OBX: ${localDeliveryData.objectBoxId}',
      );

      // --------------------------------------------------
      // 2️⃣ Resolve Trip (if exists)
      // --------------------------------------------------
      TripModel? tripModel;
      final tripPbId =
          localDeliveryData.trip.target?.id ??
          localDeliveryData.trip.target?.pocketbaseId;

      if (tripPbId != null && tripPbId.isNotEmpty) {
        final tripQuery =
            objectBoxStore.tripBox
                .query(TripModel_.id.equals(tripPbId))
                .build();
        tripModel = tripQuery.findFirst();
        tripQuery.close();

        debugPrint(
          tripModel != null
              ? '🚛 LOCAL: Trip resolved → OBX: ${tripModel.objectBoxId}'
              : '⚠️ LOCAL: Trip not found for PB ID: $tripPbId',
        );
      } else {
        debugPrint('⚠️ LOCAL: Trip ID missing on DeliveryData');
      }

      final model = CancelledInvoiceModel(
        id: null, // null locally until synced
        deliveryDataId: localDeliveryData.pocketbaseId, // REQUIRED for PB
        tripId: tripModel?.pocketbaseId, // optional
        deliveryDataModel: localDeliveryData,
        tripModel: tripModel,
        reasonString:
            input.reason?.name ?? UndeliverableReason.storeClosed.name,
        // optional
        reason: input.reason ?? UndeliverableReason.storeClosed,
        image: input.image,
        created: input.created ?? now,
        updated: now,
        syncStatus: SyncStatus.pending.name,
        retryCount: 0,
        lastSyncAttemptAt: now,
        lastLocalUpdatedAt: now,
      );

      final obxId = cancelledInvoiceBox.put(model);
      model.objectBoxId = obxId;

      model.deliveryData
        ..targetId = localDeliveryData.objectBoxId
        ..target = localDeliveryData;

      if (tripModel != null) {
        model.trip
          ..targetId = tripModel.objectBoxId
          ..target = tripModel;
      }

      debugPrint(
        '✅ LOCAL: CancelledInvoice saved → OBX:$obxId | PB:${model.id} | reason :${model.reason} or reasonString: ${model.reasonString}',
      );

      // --------------------------------------------------
      // 6️⃣ LINK → Trip (ToMany)
      // --------------------------------------------------
      if (tripModel != null) {
        await _linkCancelledInvoiceToTrip(tripModel, model);
      }

      // --------------------------------------------------
      // 6️⃣ Update UserPerformance (undelivered)
      // --------------------------------------------------
      try {
        final user = tripModel?.user.target;
        if (user != null) {
          final userPerfBox = objectBoxStore.store.box<UserPerformanceModel>();
          final perfQuery =
              userPerfBox
                  .query(UserPerformanceModel_.user.equals(user.objectBoxId))
                  .build();
          final perf = perfQuery.findFirst();
          perfQuery.close();

          if (perf != null) {
            final prevCancelled = perf.cancelledDeliveries ?? 0;
            perf
              ..cancelledDeliveries = prevCancelled + 1
              ..updated = now
              ..lastLocalUpdatedAt = now.toUtc()
              ..syncStatus = SyncStatus.pending.name
              ..version += 1;

            userPerfBox.put(perf);
            debugPrint(
              '✅ LOCAL: UserPerformance updated → Cancelled: $prevCancelled → ${perf.cancelledDeliveries}',
            );
          } else {
            debugPrint(
              '⚠️ LOCAL: No UserPerformance found for user OBX: ${user.objectBoxId}',
            );
          }
        } else {
          debugPrint('⚠️ LOCAL: User not resolved, skipping UserPerformance');
        }
      } catch (e, st) {
        debugPrint(
          '⚠️ LOCAL: UserPerformance update failed (ignored)\n$e\n$st',
        );
      }

      // --------------------------------------------------
      // 7️⃣ Update DeliveryTeam (undelivered)
      // --------------------------------------------------
      try {
        if (tripModel != null) {
          DeliveryTeamModel? team;
          for (final t in objectBoxStore.deliveryTeamBox.getAll()) {
            if (t.trip.targetId == tripModel.objectBoxId) {
              team = t;
              break;
            }
          }

          if (team != null) {
            final prevActive = team.activeDeliveries ?? 0;
            final prevUndelivered = team.undeliveredCustomers ?? 0;
            team
              ..activeDeliveries = (prevActive - 1).clamp(0, 999999)
              ..undeliveredCustomers = prevUndelivered + 1;

            objectBoxStore.deliveryTeamBox.put(team);
            debugPrint(
              '✅ LOCAL: DeliveryTeam updated → Active: $prevActive → ${team.activeDeliveries}, Undelivered: $prevUndelivered → ${team.undeliveredCustomers}',
            );
          } else {
            debugPrint(
              '⚠️ LOCAL: No DeliveryTeam found for Trip OBX: ${tripModel.objectBoxId}',
            );
          }
        }
      } catch (e, st) {
        debugPrint('⚠️ LOCAL: DeliveryTeam update failed (ignored)\n$e\n$st');
      }

      return model;
    } catch (e, st) {
      debugPrint('❌ LOCAL createCancelledInvoice ERROR:\n$e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _linkCancelledInvoiceToTrip(
    TripModel trip,
    CancelledInvoiceModel invoice,
  ) async {
    final tripBox = objectBoxStore.tripBox;

    // Prevent duplicate linking (important after restart)
    final alreadyLinked = trip.cancelledInvoices.any(
      (e) => e.objectBoxId == invoice.objectBoxId,
    );

    if (!alreadyLinked) {
      trip.cancelledInvoices.add(invoice);
      tripBox.put(trip);

      debugPrint(
        '🔗 CancelledInvoice linked → Trip: ${trip.id}, '
        'Total cancelled: ${trip.cancelledInvoices.length}',
      );
    } else {
      debugPrint('ℹ️ CancelledInvoice already linked → Trip: ${trip.id}');
    }

    await _cleanCancelledInvoices();
  }

  /// 🧹 Clean CancelledInvoice table:
  /// 1️⃣ Remove items with NULL / EMPTY PocketBase ID (id)
  /// 2️⃣ Remove duplicates using PocketBase ID
  Future<void> _cleanCancelledInvoices() async {
    try {
      debugPrint('🧹 Starting CancelledInvoice cleanup');

      final allCancelled = cancelledInvoiceBox.getAll();

      final seen = <String, CancelledInvoiceModel>{};

      for (final ci in allCancelled) {
        final pbId = (ci.id ?? '').trim();

        // -------------------------------------------------
        // 🔴 Step 1 — Remove invalid (no PB ID)
        // -------------------------------------------------
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing INVALID CancelledInvoice → '
            'Reason: ${ci.reason}, OBX: ${ci.objectBoxId}',
          );
          cancelledInvoiceBox.remove(ci.objectBoxId);
          continue;
        }

        // -------------------------------------------------
        // 🔁 Step 2 — Remove duplicates
        // -------------------------------------------------
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate CancelledInvoice → Removing '
            'PB: $pbId (OBX: ${ci.objectBoxId})',
          );
          cancelledInvoiceBox.remove(ci.objectBoxId);
          continue;
        }

        // -------------------------------------------------
        // ✅ First valid occurrence
        // -------------------------------------------------
        seen[pbId] = ci;
      }

      debugPrint(
        '🟢 CancelledInvoice cleanup complete — '
        '${allCancelled.length - seen.length} invalid/duplicate records removed.',
      );
    } catch (e, st) {
      debugPrint('❌ _cleanCancelledInvoices error: $e\n$st');
    }
  }

  @override
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId) async {
    try {
      debugPrint('📱 LOCAL: Deleting cancelled invoice: $cancelledInvoiceId');

      final cancelledInvoice =
          cancelledInvoiceBox
              .query(CancelledInvoiceModel_.id.equals(cancelledInvoiceId))
              .build()
              .findFirst();

      if (cancelledInvoice == null) {
        debugPrint(
          '⚠️ LOCAL: Cancelled invoice not found: $cancelledInvoiceId',
        );
        return false;
      }

      final success = cancelledInvoiceBox.remove(cancelledInvoice.objectBoxId);

      if (success) {
        debugPrint('✅ LOCAL: Successfully deleted cancelled invoice');
      } else {
        debugPrint('❌ LOCAL: Failed to delete cancelled invoice');
      }

      return success;
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Failed to delete cancelled invoice: ${e.toString()}',
      );
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheCancelledInvoices(
    List<CancelledInvoiceModel> cancelledInvoices,
  ) async {
    try {
      debugPrint('💾 LOCAL: Starting cancelled invoices caching process...');
      debugPrint(
        '📥 LOCAL: Received ${cancelledInvoices.length} cancelled invoices to cache',
      );

      await _cleanupCancelledInvoices();
      await _autoSave(cancelledInvoices);

      final cachedCount = cancelledInvoiceBox.count();
      debugPrint(
        '✅ LOCAL: Cache verification: $cachedCount cancelled invoices stored',
      );

      _cachedCancelledInvoices = cancelledInvoices;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
  ) async {
    try {
      debugPrint(
        '📱 LOCAL: Updating cancelled invoice: ${cancelledInvoice.id}',
      );

      // Ensure tripId and deliveryDataId are set if relations are assigned
      if (cancelledInvoice.trip.target != null) {
        cancelledInvoice.tripId = cancelledInvoice.trip.target?.pocketbaseId;
      }
      if (cancelledInvoice.deliveryData.target != null) {
        cancelledInvoice.deliveryData.target?.pocketbaseId;
      }

      cancelledInvoiceBox.put(cancelledInvoice);
      debugPrint('✅ LOCAL: Cancelled invoice updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupCancelledInvoices() async {
    try {
      debugPrint('🧹 LOCAL: Starting cancelled invoices cleanup process');
      final allCancelledInvoices = cancelledInvoiceBox.getAll();

      // Create a map to track unique cancelled invoices by their PocketBase ID
      final Map<String?, CancelledInvoiceModel> uniqueCancelledInvoices = {};

      for (var invoice in allCancelledInvoices) {
        // Only keep valid cancelled invoices with required fields
        if (_isValidCancelledInvoice(invoice)) {
          // If duplicate found, keep the most recently updated one
          final existingInvoice = uniqueCancelledInvoices[invoice.id];
          if (existingInvoice == null ||
              (invoice.updated?.isAfter(
                    existingInvoice.updated ?? DateTime(0),
                  ) ??
                  false)) {
            uniqueCancelledInvoices[invoice.id] = invoice;
          }
        }
      }

      // Clear all and save only valid unique cancelled invoices
      cancelledInvoiceBox.removeAll();
      cancelledInvoiceBox.putMany(uniqueCancelledInvoices.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allCancelledInvoices.length}');
      debugPrint('📊 After cleanup: ${uniqueCancelledInvoices.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidCancelledInvoice(CancelledInvoiceModel invoice) {
    return invoice.id != null && invoice.id!.isNotEmpty;
  }

  Future<void> _autoSave(
    List<CancelledInvoiceModel> cancelledInvoicesList,
  ) async {
    try {
      debugPrint(
        '🔍 LOCAL: Processing ${cancelledInvoicesList.length} cancelled invoices',
      );

      final validCancelledInvoices =
          cancelledInvoicesList.map((invoice) {
            // Ensure tripId and deliveryDataId are set if relations are assigned
            if (invoice.trip.target != null) {
              invoice.tripId = invoice.trip.target?.pocketbaseId;
            }
            if (invoice.deliveryData.target != null) {
              invoice.deliveryData.target?.pocketbaseId;
            }
            return invoice;
          }).toList();

      cancelledInvoiceBox.putMany(validCancelledInvoices);
      _cachedCancelledInvoices = validCancelledInvoices;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Cancelled Invoices: ${validCancelledInvoices.length}');
      debugPrint(
        'Valid Cancelled Invoices: ${validCancelledInvoices.where((i) => i.id != null).length}',
      );
      debugPrint(
        'With Trip Data: ${validCancelledInvoices.where((i) => i.tripId != null).length}',
      );
      debugPrint(
        'With Delivery Data: ${validCancelledInvoices.where((i) => i.deliveryData.target?.id != null).length}',
      );
      debugPrint(
        'With Images: ${validCancelledInvoices.where((i) => i.image != null && i.image!.isNotEmpty).length}',
      );

      // Debug each saved cancelled invoice
      for (var invoice in validCancelledInvoices) {
        debugPrint(
          '💾 Saved: ${invoice.id} - Reason: ${invoice.reason.toString().split('.').last} - Trip: ${invoice.tripId} - DeliveryData: ${invoice.deliveryData.target?.id}',
        );
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  void _setupRelations(CancelledInvoiceModel cancelledInvoice) {
    try {
      debugPrint(
        '🔗 LOCAL: Setting up relations for cancelled invoice: ${cancelledInvoice.id}',
      );

      // Set up delivery data relation
      if (cancelledInvoice.deliveryData.target?.id != null) {
        final deliveryData =
            deliveryDataBox
                .query(
                  DeliveryDataModel_.pocketbaseId.equals(
                    cancelledInvoice.deliveryData.target!.id!,
                  ),
                )
                .build()
                .findFirst();

        if (deliveryData != null) {
          cancelledInvoice.deliveryData.target = deliveryData;
          debugPrint(
            '✅ LOCAL: Set delivery data relation: ${deliveryData.pocketbaseId}',
          );

          // Also set up nested relations from delivery data
          _setupDeliveryDataRelations(deliveryData);

          // If delivery data has trip relation, use it for cancelled invoice too
          if (deliveryData.trip.target != null) {
            cancelledInvoice.trip.target = deliveryData.trip.target;
            cancelledInvoice.tripId = deliveryData.trip.target?.pocketbaseId;
            debugPrint(
              '✅ LOCAL: Inherited trip relation from delivery data: ${cancelledInvoice.tripId}',
            );
          }
        } else {
          debugPrint(
            '⚠️ LOCAL: Delivery data not found for ID: ${cancelledInvoice.deliveryData.target?.id}',
          );
        }
      }

      // Set up trip relation (if not already set from delivery data)
      if (cancelledInvoice.tripId != null &&
          cancelledInvoice.trip.target == null) {
        final trip =
            tripBox
                .query(TripModel_.pocketbaseId.equals(cancelledInvoice.tripId!))
                .build()
                .findFirst();

        if (trip != null) {
          cancelledInvoice.trip.target = trip;
          debugPrint(
            '✅ LOCAL: Set trip relation: ${trip.pocketbaseId} - ${trip.tripNumberId}',
          );
        } else {
          debugPrint(
            '⚠️ LOCAL: Trip not found for ID: ${cancelledInvoice.tripId}',
          );
        }
      }

      debugPrint('🔗 LOCAL: Relations setup complete for cancelled invoice');
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Failed to setup relations for cancelled invoice: ${e.toString()}',
      );
      // Don't throw error as this is not critical for basic functionality
    }
  }

  void _setupDeliveryDataRelations(DeliveryDataModel deliveryData) {
    try {
      debugPrint(
        '🔗 LOCAL: Setting up delivery data relations: ${deliveryData.pocketbaseId}',
      );

      // Set up trip relation for delivery data if not already set
      if (deliveryData.tripId != null && deliveryData.trip.target == null) {
        final trip =
            tripBox
                .query(TripModel_.pocketbaseId.equals(deliveryData.tripId!))
                .build()
                .findFirst();

        if (trip != null) {
          deliveryData.trip.target = trip;
          debugPrint(
            '✅ LOCAL: Set trip relation for delivery data: ${trip.pocketbaseId} - ${trip.tripNumberId}',
          );
        } else {
          debugPrint(
            '⚠️ LOCAL: Trip not found for delivery data trip ID: ${deliveryData.tripId}',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Failed to setup delivery data relations: ${e.toString()}',
      );
      // Don't throw error as this is not critical
    }
  }

  // Helper method to get cached cancelled invoices
  List<CancelledInvoiceModel>? get cachedCancelledInvoices =>
      _cachedCancelledInvoices;

  // Helper method to clear cache
  void clearCache() {
    _cachedCancelledInvoices = null;
    debugPrint('🗑️ LOCAL: Cancelled invoices cache cleared');
  }

  // Helper method to get storage statistics
  Map<String, dynamic> getStorageStats() {
    final allInvoices = cancelledInvoiceBox.getAll();
    final withTrip = allInvoices.where((i) => i.tripId != null).length;
    final withDeliveryData =
        allInvoices.where((i) => i.deliveryData.target?.id != null).length;
    final withImages =
        allInvoices.where((i) => i.image != null && i.image!.isNotEmpty).length;

    return {
      'total': allInvoices.length,
      'withTrip': withTrip,
      'withDeliveryData': withDeliveryData,
      'withImages': withImages,
      'cached': _cachedCancelledInvoices?.length ?? 0,
    };
  }

  // Helper method to validate cancelled invoice data integrity
  Future<List<String>> validateDataIntegrity() async {
    final issues = <String>[];

    try {
      final allInvoices = cancelledInvoiceBox.getAll();

      for (var invoice in allInvoices) {
        // Check for missing PocketBase ID
        if (invoice.id == null || invoice.id!.isEmpty) {
          issues.add(
            'Cancelled invoice ${invoice.objectBoxId} missing PocketBase ID',
          );
        }

        // Check for orphaned delivery data references
        if (invoice.deliveryData.target?.id != null) {
          final deliveryData =
              deliveryDataBox
                  .query(
                    DeliveryDataModel_.pocketbaseId.equals(
                      invoice.deliveryData.target!.id!,
                    ),
                  )
                  .build()
                  .findFirst();

          if (deliveryData == null) {
            issues.add(
              'Cancelled invoice ${invoice.id} references non-existent delivery data: ${invoice.deliveryData.target!.id!}',
            );
          }
        }

        // Check for orphaned trip references
        if (invoice.tripId != null) {
          final trip =
              tripBox
                  .query(TripModel_.pocketbaseId.equals(invoice.tripId!))
                  .build()
                  .findFirst();

          if (trip == null) {
            issues.add(
              'Cancelled invoice ${invoice.id} references non-existent trip: ${invoice.tripId}',
            );
          }
        }
      }

      debugPrint(
        '🔍 LOCAL: Data integrity check complete. Found ${issues.length} issues.',
      );
    } catch (e) {
      issues.add('Failed to validate data integrity: ${e.toString()}');
      debugPrint('❌ LOCAL: Data integrity validation failed: ${e.toString()}');
    }

    return issues;
  }

  // Helper method to repair broken relations
  Future<void> repairBrokenRelations() async {
    try {
      debugPrint('🔧 LOCAL: Starting relation repair process');

      final allInvoices = cancelledInvoiceBox.getAll();
      int repairedCount = 0;

      for (var invoice in allInvoices) {
        bool needsUpdate = false;

        // Repair delivery data relation
        if (invoice.deliveryData.target?.id != null &&
            invoice.deliveryData.target == null) {
          final deliveryData =
              deliveryDataBox
                  .query(
                    DeliveryDataModel_.pocketbaseId.equals(
                      invoice.deliveryData.target!.id!,
                    ),
                  )
                  .build()
                  .findFirst();

          if (deliveryData != null) {
            invoice.deliveryData.target = deliveryData;
            needsUpdate = true;
            debugPrint(
              '🔧 LOCAL: Repaired delivery data relation for ${invoice.id}',
            );
          }
        }

        // Repair trip relation
        if (invoice.tripId != null && invoice.trip.target == null) {
          final trip =
              tripBox
                  .query(TripModel_.pocketbaseId.equals(invoice.tripId!))
                  .build()
                  .findFirst();

          if (trip != null) {
            invoice.trip.target = trip;
            needsUpdate = true;
            debugPrint('🔧 LOCAL: Repaired trip relation for ${invoice.id}');
          }
        }

        if (needsUpdate) {
          cancelledInvoiceBox.put(invoice);
          repairedCount++;
        }
      }

      debugPrint(
        '✅ LOCAL: Relation repair complete. Repaired $repairedCount cancelled invoices.',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Relation repair failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<CancelledInvoiceModel>> getPendingSyncList() async {
    final all = cancelledInvoiceBox.getAll();

    return all
        .where(
          (ci) =>
              ci.syncStatus == SyncStatus.pending.name ||
              ci.syncStatus == SyncStatus.failed.name,
        )
        .toList();
  }

  /// 🆕 Mark cancelled invoice as failed sync with retry logic
  @override
  Future<void> markFailed(
    CancelledInvoiceModel cancelledInvoice,
    String error,
  ) async {
    final retryCount = (cancelledInvoice.retryCount) + 1;

    final updated = cancelledInvoice.copyWith(
      syncStatus: SyncStatus.pending.name,
      retryCount: retryCount,
      lastSyncError: error,
      nextRetryAt: DateTime.now().add(
        Duration(seconds: 2 * retryCount * 2), // exponential backoff
      ),
    );

    cancelledInvoiceBox.put(updated);

    debugPrint(
      'LOCAL ⚠️ CancelledInvoice sync failed → '
      'id=${cancelledInvoice.id}, retryCount=$retryCount',
    );
  }

  /// 🆕 Mark cancelled invoice as successfully synced
  @override
  Future<void> markSynced(CancelledInvoiceModel cancelledInvoice) async {
    final updated = cancelledInvoice.copyWith(
      syncStatus: SyncStatus.synced.name,
      retryCount: 0,
      lastSyncError: null,
      nextRetryAt: null,
    );

    cancelledInvoiceBox.put(updated);

    debugPrint('LOCAL ✅ CancelledInvoice synced → id=${cancelledInvoice.id}');
  }

  /// 🆕 Mark cancelled invoice as syncing (in-progress)
  @override
  Future<void> markSyncing(CancelledInvoiceModel cancelledInvoice) async {
    final updated = cancelledInvoice.copyWith(
      syncStatus: SyncStatus.syncing.name,
      lastSyncAttemptAt: DateTime.now(),
    );

    cancelledInvoiceBox.put(updated);

    debugPrint('LOCAL 🔄 CancelledInvoice syncing → id=${cancelledInvoice.id}');
  }
}
