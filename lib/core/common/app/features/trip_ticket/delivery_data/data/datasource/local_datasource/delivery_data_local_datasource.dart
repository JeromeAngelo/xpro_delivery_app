import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../enums/invoice_status.dart';
import '../../../../../../../../services/objectbox.dart';
import '../../../../../delivery_data/delivery_update/data/models/delivery_update_model.dart';
import '../../../../../delivery_data/customer_data/data/model/customer_data_model.dart';
import '../../../../../delivery_data/invoice_data/data/model/invoice_data_model.dart';
import '../../../../../delivery_data/invoice_items/data/model/invoice_items_model.dart';

abstract class DeliveryDataLocalDataSource {
  Future<void> saveDeliveryDataByTripId(
    String tripId,
    List<DeliveryDataModel> deliveryData,
  ); // Get all delivery data
  Future<List<DeliveryDataModel>> getAllDeliveryData();

  // Get all delivery data by trip ID
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId);

  /// Force reload latest delivery updates for all deliveries in a trip.
  ///
  /// This will re-query the `deliveryUpdate` box for each delivery using
  /// the `deliveryDataPbId` foreign-key and replace the `deliveryUpdates`
  /// collection on the `DeliveryDataModel` instances. Returns the refreshed
  /// delivery models.
  Future<List<DeliveryDataModel>> forceReloadDeliveryUpdatesByTripId(
    String tripId,
  );

  // Get delivery data by ID
  Future<DeliveryDataModel?> getDeliveryDataById(String id);

  // Cache delivery data
  Future<void> cacheDeliveryData(List<DeliveryDataModel> deliveryData);

  // Update delivery data
  Future<void> updateDeliveryData(DeliveryDataModel deliveryData);

  // Delete delivery data
  Future<bool> deleteDeliveryData(String id);

  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId);

  Future<DeliveryDataModel> setInvoiceIntoUnloaded(String deliveryDataId);

  Future<DeliveryDataModel> setInvoiceIntoUnloading(String deliveryDataId);

  Stream<List<DeliveryDataModel>> watchDeliveryDataByTripId(String tripId);
  Stream<List<DeliveryDataModel>> watchAllDeliveryData();

  // 👀 Watch a single delivery data by its ID (immediate updates)
  Stream<DeliveryDataModel?> watchDeliveryDataById(String deliveryId);
}

class DeliveryDataLocalDataSourceImpl implements DeliveryDataLocalDataSource {
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  List<DeliveryDataModel>? _cachedDeliveryData;
  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<InvoiceItemsModel> get invoiceItemsBox => objectBoxStore.invoiceItemsBox;

  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;
  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;
  final ObjectBoxStore objectBoxStore;
  DeliveryDataLocalDataSourceImpl(this.objectBoxStore);
  
  @override
  Stream<List<DeliveryDataModel>> watchDeliveryDataByTripId(String tripId) {
    debugPrint(
      '👀 LOCAL: Watching delivery data via Trip relation → tripId=$tripId',
    );

    // -------------------------------------------------------------
    // 1️⃣ Find trip ONCE
    // -------------------------------------------------------------
    final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
    final trip = tripQuery.findFirst();
    tripQuery.close();

    if (trip == null) {
      debugPrint('⚠️ Trip not found in local DB for tripId=$tripId');
      return Stream.value(<DeliveryDataModel>[]);
    }

    // -------------------------------------------------------------
    // 2️⃣ Watch DeliveryData box (react to any changes)
    // -------------------------------------------------------------
    return deliveryDataBox.query().watch(triggerImmediately: true).map((_) {
      try {
        final deliverySet = <String, DeliveryDataModel>{};

        // ---------------------------------------------------------
        // 3️⃣ Pull DeliveryData from Trip relation
        // ---------------------------------------------------------
        for (final d in trip.deliveryData) {
          final fullDD = deliveryDataBox.get(d.objectBoxId);
          if (fullDD != null) {
            deliverySet[fullDD.id ?? ""] = fullDD;
          }
        }

        if (deliverySet.isEmpty) {
          debugPrint(
            '⚠️ LOCAL: No delivery data linked to trip → ${trip.name}',
          );
          return <DeliveryDataModel>[];
        }

        final output = <DeliveryDataModel>[];

        // ---------------------------------------------------------
        // 4️⃣ Load nested relations (same as getDeliveryDataByTripId)
        // ---------------------------------------------------------
        for (final data in deliverySet.values) {
          // 👤 Customer
          final c = data.customer.target;
          if (c != null) {
            final fullCustomer = customerBox.get(c.objectBoxId);
            if (fullCustomer != null) {
              data.customer.target = fullCustomer;
              data.customer.targetId = fullCustomer.objectBoxId;
            }
          }

          // 🧾 Invoices
          final invoiceList = <InvoiceDataModel>[];
          for (final inv in data.invoices) {
            final fullInv = invoiceBox.get(inv.objectBoxId);
            if (fullInv != null) invoiceList.add(fullInv);
          }
          data.invoices
            ..clear()
            ..addAll(invoiceList);

          // 🧾 Invoices
          final invoiceItemsList = <InvoiceItemsModel>[];
          for (final inv in data.invoiceItems) {
            final fullInv = invoiceItemsBox.get(inv.objectBoxId);
            if (fullInv != null) invoiceItemsList.add(fullInv);
          }
          data.invoiceItems
            ..clear()
            ..addAll(invoiceItemsList);

          // 🔄 Delivery Updates
          final updatesList = <DeliveryUpdateModel>[];
          for (final u in data.deliveryUpdates) {
            final fullUpdate = deliveryUpdateBox.get(u.objectBoxId);
            if (fullUpdate != null) updatesList.add(fullUpdate);
          }
          data.deliveryUpdates
            ..clear()
            ..addAll(updatesList);

          output.add(data);
        }

        debugPrint(
          '✅ LOCAL: Stream emitted ${output.length} delivery items for trip=${trip.name}',
        );
        return output;
      } catch (e, st) {
        debugPrint('❌ watchDeliveryDataByTripId ERROR: $e\n$st');
        return <DeliveryDataModel>[];
      }
    });
  }

  @override
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId) async {
    try {
      final id = tripId.trim();
      debugPrint("📥 LOCAL getDeliveryDataByTripId() tripId = $id");

      // -------------------------------------------------------------
      // 1️⃣ Find trip (prefer pocketbaseId)
      // -------------------------------------------------------------
      TripModel? trip;

      final q1 = tripBox.query(TripModel_.pocketbaseId.equals(id)).build();
      trip = q1.findFirst();
      q1.close();

      if (trip == null) {
        final q2 = tripBox.query(TripModel_.id.equals(id)).build();
        trip = q2.findFirst();
        q2.close();
      }

      if (trip == null) {
        debugPrint("⚠️ Trip not found in local DB for tripId: $id");
        return [];
      }

      // -------------------------------------------------------------
      // 2️⃣ Read deliveryData linked to trip (dedupe by PB id)
      // -------------------------------------------------------------
      final Map<String, DeliveryDataModel> unique = {};

      // NOTE: trip.deliveryData typically returns usable entities already
      for (final d in trip.deliveryData) {
        final key = ((d.pocketbaseId)).trim();
        if (key.isEmpty) continue;
        unique[key] = d;
      }

      if (unique.isEmpty) {
        debugPrint("⚠️ No delivery data found for trip: ${trip.name}");
        return [];
      }

      final output = <DeliveryDataModel>[];

      // -------------------------------------------------------------
      // 3️⃣ Load nested relations safely (without rewriting lists)
      // -------------------------------------------------------------
      for (final data in unique.values) {
        // 👤 Customer
        final cust = data.customer.target;
        if (cust != null) {
          final fullCustomer = customerBox.get(cust.objectBoxId);
          if (fullCustomer != null) {
            data.customer.target = fullCustomer;
            data.customer.targetId = fullCustomer.objectBoxId;
          }
        }

        // 🧾 Invoices (no need to clear/add to relations here)
        for (final inv in data.invoices) {
          // touching inv.objectBoxId is enough; you can fetch full if needed
          invoiceBox.get(inv.objectBoxId);
        }

        // 🔄 Delivery Updates
        for (final up in data.deliveryUpdates) {
          deliveryUpdateBox.get(up.objectBoxId);
        }

        output.add(data);
      }

      debugPrint(
        "📦 Found ${output.length} delivery items linked to trip: ${trip.name}",
      );
      return output;
    } catch (e, st) {
      debugPrint("❌ getDeliveryDataByTripId ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<DeliveryDataModel>> forceReloadDeliveryUpdatesByTripId(
    String tripId,
  ) async {
    try {
      final tid = tripId.trim();
      debugPrint('🔁 LOCAL: Force reloading delivery updates for tripId=$tid');

      // 1️⃣ Load deliveries for the trip
      final deliveries = await getDeliveryDataByTripId(tid);

      if (deliveries.isEmpty) {
        debugPrint('🔁 LOCAL: No deliveries found for tripId=$tid');
        return [];
      }

      // 2️⃣ For each delivery, query updates by deliveryDataPbId
      for (final delivery in deliveries) {
        try {
          final deliveryPbId = (delivery.pocketbaseId).trim();

          if (deliveryPbId.isEmpty) {
            debugPrint(
              '⚠️ LOCAL: Skip delivery updates reload (missing PB/id)',
            );
            continue;
          }

          final q =
              deliveryUpdateBox
                  .query(
                    DeliveryUpdateModel_.deliveryDataPbId.equals(deliveryPbId),
                  )
                  .build();
          final found = q.find();
          q.close();

          // Sort updates by preferred timestamp (oldest -> newest)
          found.sort((a, b) {
            final ta = a.lastLocalUpdatedAt ?? a.updated ?? a.time;
            final tb = b.lastLocalUpdatedAt ?? b.updated ?? b.time;
            if (ta == null && tb == null) return 0;
            if (ta == null) return -1;
            if (tb == null) return 1;
            return ta.compareTo(tb);
          });

          // ✅ Avoid rewriting relation if nothing changed (saves lag)
          final currentIds =
              delivery.deliveryUpdates.map((e) => e.objectBoxId).toList()
                ..sort();
          final foundIds = found.map((e) => e.objectBoxId).toList()..sort();

          final same =
              currentIds.length == foundIds.length &&
              _listEqualsInt(currentIds, foundIds);

          if (!same) {
            delivery.deliveryUpdates
              ..clear()
              ..addAll(found);

            // Persist parent so watchers receive updated relation
            deliveryDataBox.put(delivery);

            debugPrint(
              '🔁 LOCAL: Delivery $deliveryPbId refreshed with ${found.length} updates',
            );
          } else {
            debugPrint(
              'ℹ️ LOCAL: Delivery $deliveryPbId updates already up-to-date (${found.length})',
            );
          }
        } catch (e) {
          debugPrint(
            '🔁 LOCAL: Failed to reload updates for delivery '
            '${delivery.pocketbaseId}: $e',
          );
        }
      }

      debugPrint('🔁 LOCAL: Force reload complete for tripId=$tid');
      return deliveries;
    } catch (e, st) {
      debugPrint('❌ forceReloadDeliveryUpdatesByTripId ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  /// Small helper (keep local in the same file)
  bool _listEqualsInt(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Future<void> saveDeliveryDataByTripId(
    String tripId,
    List<DeliveryDataModel> deliveryData,
  ) async {
    try {
      debugPrint('💾 LOCAL: Saving delivery data for tripId: $tripId');
      debugPrint('📥 LOCAL: Received ${deliveryData.length} delivery items');

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first (OFFLINE-FIRST, RELATION-BASED)
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint('⚠️ Trip not found in local DB for tripId: $tripId');
        throw CacheException(message: 'Trip not found in local DB');
      }

      debugPrint('🚛 Trip found → ${trip.name} (OBX: ${trip.objectBoxId})');

      // -------------------------------------------------------------
      // 2️⃣ Cleanup existing delivery data linked to this trip
      // -------------------------------------------------------------
      await _cleanupDeliveryDataByTrip(trip);
      debugPrint('🧹 LOCAL: Existing delivery data cleared for trip');

      // -------------------------------------------------------------
      // 3️⃣ Prepare & attach delivery data to trip
      // -------------------------------------------------------------
      final preparedData = <DeliveryDataModel>[];

      for (final data in deliveryData) {
        debugPrint('🔍 Preparing DeliveryData → ${data.id}');

        // Attach trip relation (CRITICAL)
        data.trip.target = trip;
        data.tripId = trip.id;

        preparedData.add(data);
      }

      // -------------------------------------------------------------
      // 4️⃣ Save DeliveryData to ObjectBox
      // -------------------------------------------------------------
      final storedIds = deliveryDataBox.putMany(preparedData);

      debugPrint(
        '💾 LOCAL: Saved ${storedIds.length} delivery data records to ObjectBox',
      );

      // -------------------------------------------------------------
      // 5️⃣ Attach saved DeliveryData back to Trip
      // -------------------------------------------------------------
      final savedDeliveryData =
          storedIds.map((id) => deliveryDataBox.get(id)!).toList();

      trip.deliveryData
        ..clear()
        ..addAll(savedDeliveryData);

      tripBox.put(trip);

      debugPrint(
        '🔗 LOCAL: Trip updated → ${trip.name} now has ${trip.deliveryData.length} delivery items',
      );

      // -------------------------------------------------------------
      // 6️⃣ Update in-memory cache
      // -------------------------------------------------------------
      _cachedDeliveryData = deliveryDataBox.getAll();
      debugPrint('🔄 LOCAL: In-memory cache updated');
    } catch (e, st) {
      debugPrint('❌ LOCAL: saveDeliveryDataByTripId ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupDeliveryDataByTrip(TripModel trip) async {
    try {
      debugPrint(
        '🧹 LOCAL: Cleaning up existing delivery data for trip: ${trip.id}',
      );

      if (trip.objectBoxId == 0) {
        debugPrint(
          '⚠️ LOCAL: Trip not found in local storage, skipping cleanup',
        );
        return;
      }

      // Collect all existing delivery data linked to this trip
      final existingData = <DeliveryDataModel>[];
      for (final d in trip.deliveryData) {
        final fullDD = deliveryDataBox.get(d.objectBoxId);
        if (fullDD != null) existingData.add(fullDD);
      }

      if (existingData.isNotEmpty) {
        final idsToRemove = existingData.map((d) => d.objectBoxId).toList();
        deliveryDataBox.removeMany(idsToRemove);
        debugPrint(
          '🗑️ LOCAL: Removed ${existingData.length} delivery data records for trip: ${trip.id}',
        );
        // Clear the trip's deliveryData relation
        trip.deliveryData.clear();
        tripBox.put(trip);
      } else {
        debugPrint(
          'ℹ️ LOCAL: No existing delivery data found for trip: ${trip.id}',
        );
      }
    } catch (e, st) {
      debugPrint(
        '❌ LOCAL: Cleanup failed for trip ${trip.id}: ${e.toString()}\n$st',
      );
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<DeliveryDataModel>> getAllDeliveryData() async {
    try {
      debugPrint('📱 LOCAL: Fetching all delivery data');

      final deliveryData = deliveryDataBox.getAll();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored delivery data: ${deliveryDataBox.count()}');
      debugPrint('Found unassigned delivery data: ${deliveryData.length}');

      _cachedDeliveryData = deliveryData;
      return deliveryData;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  // Helper method to store related entities
  @override
  Future<DeliveryDataModel?> getDeliveryDataById(String id) async {
    try {
      debugPrint('📱 LOCAL: Fetching delivery data by ID: $id');

      // -----------------------------------------------------
      // 1️⃣ Query DeliveryData by PocketBase ID
      // -----------------------------------------------------
      final query =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build();
      final deliveryData = query.findFirst();
      query.close();

      if (deliveryData == null) {
        debugPrint('⚠️ DeliveryData not found for ID: $id');
        return null;
      }

      debugPrint('📦 DeliveryData found → ${deliveryData.id}');

      // -----------------------------------------------------
      // 2️⃣ Load Customer (ToOne)
      // -----------------------------------------------------
      final customerRef = deliveryData.customer.target;
      if (customerRef != null) {
        final fullCustomer = customerBox.get(customerRef.objectBoxId);
        if (fullCustomer != null) {
          deliveryData.customer.target = fullCustomer;
          deliveryData.customer.targetId = fullCustomer.objectBoxId;
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
      // 3️⃣ Load Invoices (ToMany)
      // -----------------------------------------------------
      final invoiceItems = deliveryData.invoiceItems;
      if (invoiceItems.isNotEmpty) {
        for (var i = 0; i < invoiceItems.length; i++) {
          final inv = invoiceItems[i];
          final fullInvoiceItems = invoiceItemsBox.get(inv.objectBoxId);
          if (fullInvoiceItems != null) {
            invoiceItems[i] = fullInvoiceItems;
            debugPrint('📄 Invoice Items loaded → ${fullInvoiceItems.name}');
          } else {
            debugPrint(
              '⚠️ Invoice Items not found → OBX ID: ${inv.objectBoxId}',
            );
          }
        }
      } else {
        debugPrint('⚠️ No invoices Items for this delivery data');
      }

      // -----------------------------------------------------
      // 3️⃣ Load Invoices (ToMany)
      // -----------------------------------------------------
      final invoices = deliveryData.invoices;
      if (invoices.isNotEmpty) {
        for (var i = 0; i < invoices.length; i++) {
          final inv = invoices[i];
          final fullInvoice = invoiceBox.get(inv.objectBoxId);
          if (fullInvoice != null) {
            invoices[i] = fullInvoice;
            debugPrint('📄 Invoice loaded → ${fullInvoice.name}');
          } else {
            debugPrint('⚠️ Invoice not found → OBX ID: ${inv.objectBoxId}');
          }
        }
      } else {
        debugPrint('⚠️ No invoices for this delivery data');
      }

      // -----------------------------------------------------
      // 3️⃣ Load Invoices (ToMany)
      // -----------------------------------------------------
      final invoiceItemsList = deliveryData.invoiceItems;
      if (invoiceItemsList.isNotEmpty) {
        for (var i = 0; i < invoiceItemsList.length; i++) {
          final inv = invoiceItemsList[i];
          final fullInvoice = invoiceItemsBox.get(inv.objectBoxId);
          if (fullInvoice != null) {
            invoiceItemsList[i] = fullInvoice;
            debugPrint('📄 Invoice Items loaded → ${fullInvoice.name}');
          } else {
            debugPrint(
              '⚠️ Invoice Items not found → OBX ID: ${inv.objectBoxId}',
            );
          }
        }
      } else {
        debugPrint('⚠️ No invoices items for this delivery data');
      }
      // -----------------------------------------------------
      // 4️⃣ Load Delivery Updates (ToMany)
      // -----------------------------------------------------
      final updates = deliveryData.deliveryUpdates;
      if (updates.isNotEmpty) {
        for (var i = 0; i < updates.length; i++) {
          final upd = updates[i];
          final fullUpdate = deliveryUpdateBox.get(upd.objectBoxId);
          if (fullUpdate != null) {
            updates[i] = fullUpdate;
            debugPrint(
              '🔄 DeliveryUpdate loaded → ${fullUpdate.title} at ${fullUpdate.time} in customer $id',
            );
          } else {
            debugPrint(
              '⚠️ DeliveryUpdate not found → OBX ID: ${upd.objectBoxId}',
            );
          }
        }
      } else {
        debugPrint('⚠️ No delivery updates for this delivery data');
      }

      debugPrint('✅ DeliveryData fully loaded with expected relations');
      return deliveryData;
    } catch (e) {
      debugPrint('❌ LOCAL: getDeliveryDataById error: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId) async {
    try {
      debugPrint(
        '📱 LOCAL: Calculating delivery time for delivery data: $deliveryId',
      );

      final deliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryId))
              .build()
              .findFirst();

      if (deliveryData == null) {
        throw const CacheException(
          message: 'Delivery data not found in local storage',
        );
      }

      final updates = deliveryData.deliveryUpdates.toList();
      if (updates.isEmpty) {
        debugPrint(
          '⚠️ LOCAL: No delivery updates found for delivery data: $deliveryId',
        );
        return 0;
      }

      // Sort updates by time
      updates.sort((a, b) => a.time!.compareTo(b.time!));

      // Find the "arrived" status
      final arrivedIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'arrived',
      );

      if (arrivedIndex == -1) {
        debugPrint(
          '⚠️ LOCAL: No "arrived" status found for delivery data: $deliveryId',
        );
        return 0;
      }

      // Check for undelivered status
      final undeliveredIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as undelivered',
      );

      // Get end delivery status
      final endDeliveryIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'end delivery',
      );

      // Get mark as received status
      final receivedIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as received',
      );

      // Determine relevant updates based on delivery scenario
      List<DeliveryUpdateModel> relevantUpdates;
      if (undeliveredIndex != -1) {
        // Undelivered scenario - calculate until mark as undelivered
        relevantUpdates = updates.sublist(arrivedIndex, undeliveredIndex + 1);
        debugPrint('📊 LOCAL: Calculating time for undelivered scenario');
      } else if (receivedIndex != -1) {
        // Received scenario - calculate until mark as received
        relevantUpdates = updates.sublist(arrivedIndex, receivedIndex + 1);
        debugPrint('📊 LOCAL: Calculating time for received scenario');
      } else if (endDeliveryIndex != -1) {
        // Normal delivery - include end delivery
        relevantUpdates = updates.sublist(arrivedIndex, endDeliveryIndex + 1);
        debugPrint('📊 LOCAL: Calculating time for normal delivery scenario');
      } else {
        // Fallback to all updates from arrived to the end
        relevantUpdates = updates.sublist(arrivedIndex);
        debugPrint('📊 LOCAL: Calculating time for ongoing delivery scenario');
      }

      double totalSeconds = 0;
      for (int i = 0; i < relevantUpdates.length - 1; i++) {
        final currentTime = relevantUpdates[i].time!;
        final nextTime = relevantUpdates[i + 1].time!;
        final diffInSeconds = nextTime.difference(currentTime).inSeconds;
        totalSeconds += diffInSeconds;

        debugPrint(
          'LOCAL: Status: ${relevantUpdates[i].title} -> ${relevantUpdates[i + 1].title}',
        );
        debugPrint(
          'LOCAL: Time: ${_formatTime(currentTime)} -> ${_formatTime(nextTime)}',
        );
        debugPrint(
          'LOCAL: Difference: ${diffInSeconds ~/ 60} minutes ${diffInSeconds % 60} seconds\n',
        );
      }

      final totalMinutes = (totalSeconds / 60).round();

      debugPrint(
        '✅ LOCAL: Total delivery time calculated: $totalMinutes minutes ($totalSeconds seconds)',
      );

      // Cache the calculated time in the delivery data model
      deliveryData.totalDeliveryTime =
          '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
      deliveryDataBox.put(deliveryData);

      return totalMinutes;
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to calculate delivery time: $e');
      throw CacheException(message: e.toString());
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> cacheDeliveryData(List<DeliveryDataModel> deliveryData) async {
    try {
      debugPrint('💾 LOCAL: Starting delivery data caching process...');
      debugPrint(
        '📥 LOCAL: Received ${deliveryData.length} delivery data items to cache',
      );

      await _cleanupDeliveryData();
      await _autoSave(deliveryData);

      final cachedCount = deliveryDataBox.count();
      debugPrint(
        '✅ LOCAL: Cache verification: $cachedCount delivery data items stored',
      );

      _cachedDeliveryData = deliveryData;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateDeliveryData(DeliveryDataModel deliveryData) async {
    try {
      debugPrint('📱 LOCAL: Updating delivery data: ${deliveryData.id}');

      // Ensure tripId is set if trip is assigned
      if (deliveryData.trip.target != null) {
        deliveryData.tripId = deliveryData.trip.target?.id;
      }

      deliveryDataBox.put(deliveryData);
      debugPrint('✅ LOCAL: Delivery data updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteDeliveryData(String id) async {
    try {
      debugPrint('📱 LOCAL: Deleting delivery data with ID: $id');

      final deliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build()
              .findFirst();

      if (deliveryData == null) {
        throw const CacheException(
          message: 'Delivery data not found in local storage',
        );
      }

      // Check if this delivery data is associated with a trip
      if (deliveryData.tripId != null && deliveryData.tripId!.isNotEmpty) {
        debugPrint(
          '⚠️ LOCAL: Cannot delete delivery data that is assigned to a trip',
        );
        throw const CacheException(
          message:
              'Cannot delete delivery data that is assigned to a trip. Please unassign it first.',
        );
      }

      deliveryDataBox.remove(deliveryData.objectBoxId);
      debugPrint('✅ LOCAL: Successfully deleted delivery data');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupDeliveryData() async {
    try {
      debugPrint('🧹 LOCAL: Starting delivery data cleanup process');
      final allDeliveryData = deliveryDataBox.getAll();

      // Create a map to track unique delivery data by their PocketBase ID
      final Map<String?, DeliveryDataModel> uniqueDeliveryData = {};

      for (var data in allDeliveryData) {
        // Only keep valid delivery data with required fields
        if (_isValidDeliveryData(data)) {
          // If duplicate found, keep the most recently updated one
          final existingData = uniqueDeliveryData[data.pocketbaseId];
          if (existingData == null ||
              (data.updated?.isAfter(existingData.updated ?? DateTime(0)) ??
                  false)) {
            uniqueDeliveryData[data.pocketbaseId] = data;
          }
        }
      }

      // Clear all and save only valid unique delivery data
      deliveryDataBox.removeAll();
      deliveryDataBox.putMany(uniqueDeliveryData.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allDeliveryData.length}');
      debugPrint('📊 After cleanup: ${uniqueDeliveryData.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidDeliveryData(DeliveryDataModel data) {
    return data.id != null && data.pocketbaseId.isNotEmpty;
  }

  Future<void> _autoSave(List<DeliveryDataModel> deliveryDataList) async {
    try {
      debugPrint(
        '🔍 LOCAL: Processing ${deliveryDataList.length} delivery data items',
      );

      final validDeliveryData =
          deliveryDataList.map((data) {
            // Ensure tripId is set if trip is assigned
            if (data.trip.target != null) {
              data.tripId = data.trip.target?.id;
            }
            return data;
          }).toList();

      deliveryDataBox.putMany(validDeliveryData);
      _cachedDeliveryData = validDeliveryData;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Delivery Data: ${validDeliveryData.length}');
      debugPrint(
        'Valid Delivery Data: ${validDeliveryData.where((d) => d.id != null).length}',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Stream<DeliveryDataModel?> watchDeliveryDataById(String deliveryId) {
    debugPrint('👀 LOCAL: Watching single delivery data by ID: $deliveryId');

    // Watch the box for changes in this delivery data
    final query =
        deliveryDataBox
            .query(DeliveryDataModel_.pocketbaseId.equals(deliveryId))
            .build();

    return query.stream().asyncMap((_) async {
      try {
        // Load the DeliveryData with all relations (customer, invoices, updates)
        final deliveryData = await getDeliveryDataById(deliveryId);

        if (deliveryData != null) {
          debugPrint(
            '📦 LOCAL: Stream emitted delivery data for ID: $deliveryId with '
            '${deliveryData.invoices.length} invoices and '
            '${deliveryData.deliveryUpdates.length} updates',
          );
        } else {
          debugPrint('⚠️ LOCAL: Delivery data not found for ID: $deliveryId');
        }

        return deliveryData;
      } catch (e, st) {
        debugPrint(
          '❌ LOCAL: Failed to watch delivery data ID=$deliveryId → $e\n$st',
        );
        return null;
      }
    });
  }

  @override
  Stream<List<DeliveryDataModel>> watchAllDeliveryData() async* {
    debugPrint('👀 LOCAL: Watching ALL delivery data');

    final query = deliveryDataBox.query().build();

    await for (final _ in query.stream()) {
      try {
        final allDeliveryData = deliveryDataBox.getAll();
        if (allDeliveryData.isEmpty) {
          debugPrint('⚠️ LOCAL: No delivery data found');
          yield <DeliveryDataModel>[];
          continue;
        }

        final output = <DeliveryDataModel>[];
        final seenIds = <String>{};
        for (final data in allDeliveryData) {
          if (seenIds.contains(data.id)) continue; // skip duplicates
          seenIds.add(data.id ?? '');

          // ------------------------- Customer -------------------------
          final customerRef = data.customer.target;
          if (customerRef != null) {
            final fullCustomer = customerBox.get(customerRef.objectBoxId);
            if (fullCustomer != null) {
              data.customer.target = fullCustomer;
              data.customer.targetId = fullCustomer.objectBoxId;
            }
          }

          // ------------------------- Invoices -------------------------
          if (data.invoices.isNotEmpty) {
            final invoicesList =
                data.invoices.map((inv) {
                  return invoiceBox.get(inv.objectBoxId) ?? inv;
                }).toList();
            data.invoices
              ..clear()
              ..addAll(invoicesList);
          }

          // ---------------------- Delivery Updates ---------------------
          if (data.deliveryUpdates.isNotEmpty) {
            final updatesList =
                data.deliveryUpdates.map((upd) {
                  return deliveryUpdateBox.get(upd.objectBoxId) ?? upd;
                }).toList();
            data.deliveryUpdates
              ..clear()
              ..addAll(updatesList);
          }

          output.add(data);
        }

        debugPrint('✅ LOCAL: Stream emitted ${output.length} delivery items');
        yield output;
      } catch (e, st) {
        debugPrint('❌ watchAllDeliveryData ERROR: $e\n$st');
        yield <DeliveryDataModel>[];
      }
    }
  }

  @override
  Future<DeliveryDataModel> setInvoiceIntoUnloaded(
    String deliveryDataId,
  ) async {
    try {
      final id = deliveryDataId.trim();
      debugPrint(
        '🔄 LOCAL: Setting invoice to unloaded for deliveryDataId=$id',
      );

      // -------------------------------------------------------------
      // 1️⃣ Find DeliveryData (prefer pocketbaseId)
      // -------------------------------------------------------------
      DeliveryDataModel? delivery;

      final q1 =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build();
      delivery = q1.findFirst();
      q1.close();

      if (delivery == null) {
        final q2 =
            deliveryDataBox.query(DeliveryDataModel_.id.equals(id)).build();
        delivery = q2.findFirst();
        q2.close();
      }

      if (delivery == null) {
        debugPrint('⚠️ LOCAL: DeliveryData not found for id=$id');
        throw const CacheException(
          message: 'DeliveryData not found in local DB',
        );
      }

      debugPrint(
        '📦 LOCAL: DeliveryData found → OBX=${delivery.objectBoxId}, PB=${delivery.pocketbaseId}, current isUnloaded=${delivery.isUnloaded}',
      );

      // -------------------------------------------------------------
      // 2️⃣ Update field
      // -------------------------------------------------------------
      delivery.isUnloaded = true;
      delivery.isUnloading = false;
      delivery.invoiceStatus = InvoiceStatus.unloaded;

      // OPTIONAL (only if your model has updated field)
      try {
        delivery.updated = DateTime.now();
      } catch (_) {
        // ignore if model doesn't have updated
      }

      // -------------------------------------------------------------
      // 3️⃣ Persist
      // -------------------------------------------------------------
      final savedId = deliveryDataBox.put(delivery);

      debugPrint(
        '✅ LOCAL: Successfully set isUnloaded=true and isUnloading=false for DeliveryData '
        'OBX=$savedId, PB=${delivery.pocketbaseId}',
      );

      // -------------------------------------------------------------
      // 4️⃣ Reload relations (optional but consistent with your pattern)
      // -------------------------------------------------------------
      // Customer
      final cust = delivery.customer.target;
      if (cust != null) {
        final fullCustomer = customerBox.get(cust.objectBoxId);
        if (fullCustomer != null) {
          delivery.customer.target = fullCustomer;
          delivery.customer.targetId = fullCustomer.objectBoxId;
        }
      }

      // Invoices
      for (final inv in delivery.invoices) {
        invoiceBox.get(inv.objectBoxId);
      }

      // Updates
      for (final up in delivery.deliveryUpdates) {
        deliveryUpdateBox.get(up.objectBoxId);
      }

      // Invoice Items
      for (final item in delivery.invoiceItems) {
        invoiceItemsBox.get(item.objectBoxId);
      }

      debugPrint(
        '📦 LOCAL: Final DeliveryData state → '
        'isUnloaded=${delivery.isUnloaded}, '
        'invoices=${delivery.invoices.length}, '
        'updates=${delivery.deliveryUpdates.length}, '
        'items=${delivery.invoiceItems.length}',
      );

      return delivery;
    } catch (e, st) {
      debugPrint('❌ LOCAL setInvoiceIntoUnloaded ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<DeliveryDataModel> setInvoiceIntoUnloading(String deliveryDataId) async {
    try {
      final id = deliveryDataId.trim();
      debugPrint(
        '🔄 LOCAL: Setting invoice to unloading for deliveryDataId=$id',
      );

      // -------------------------------------------------------------
      // 1️⃣ Find DeliveryData (prefer pocketbaseId)
      // -------------------------------------------------------------
      DeliveryDataModel? delivery;

      final q1 =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build();
      delivery = q1.findFirst();
      q1.close();

      if (delivery == null) {
        final q2 =
            deliveryDataBox.query(DeliveryDataModel_.id.equals(id)).build();
        delivery = q2.findFirst();
        q2.close();
      }

      if (delivery == null) {
        debugPrint('⚠️ LOCAL: DeliveryData not found for id=$id');
        throw const CacheException(
          message: 'DeliveryData not found in local DB',
        );
      }

      debugPrint(
        '📦 LOCAL: DeliveryData found → OBX=${delivery.objectBoxId}, PB=${delivery.pocketbaseId}, current isUnloading=${delivery.isUnloading}',
      );

      // -------------------------------------------------------------
      // 2️⃣ Update field
      // -------------------------------------------------------------
      delivery.isUnloading = true;
            delivery.invoiceStatus = InvoiceStatus.unloading;


      // OPTIONAL (only if your model has updated field)
      try {
        delivery.updated = DateTime.now();
      } catch (_) {
        // ignore if model doesn't have updated
      }

      // -------------------------------------------------------------
      // 3️⃣ Persist
      // -------------------------------------------------------------
      final savedId = deliveryDataBox.put(delivery);

      debugPrint(
        '✅ LOCAL: Successfully set isUnloading=true for DeliveryData '
        'OBX=$savedId, PB=${delivery.pocketbaseId}',
      );

      // -------------------------------------------------------------
      // 4️⃣ Reload relations (optional but consistent with your pattern)
      // -------------------------------------------------------------
      // Customer
      final cust = delivery.customer.target;
      if (cust != null) {
        final fullCustomer = customerBox.get(cust.objectBoxId);
        if (fullCustomer != null) {
          delivery.customer.target = fullCustomer;
          delivery.customer.targetId = fullCustomer.objectBoxId;
        }
      }

      // Invoices
      for (final inv in delivery.invoices) {
        invoiceBox.get(inv.objectBoxId);
      }

      // Updates
      for (final up in delivery.deliveryUpdates) {
        deliveryUpdateBox.get(up.objectBoxId);
      }

      // Invoice Items
      for (final item in delivery.invoiceItems) {
        invoiceItemsBox.get(item.objectBoxId);
      }

      debugPrint(
        '📦 LOCAL: Final DeliveryData state → '
        'isUnloading=${delivery.isUnloading}, '
        'invoices=${delivery.invoices.length}, '
        'updates=${delivery.deliveryUpdates.length}, '
        'items=${delivery.invoiceItems.length}',
      );

      return delivery;
    } catch (e, st) {
      debugPrint('❌ LOCAL setInvoiceIntoUnloading ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
