import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../../services/objectbox.dart';
import '../../../../../../delivery_data/delivery_update/data/models/delivery_update_model.dart';

abstract class DeliveryDataLocalBase {
  final ObjectBoxStore objectBoxStore;
  List<DeliveryDataModel>? cachedDeliveryData;

  DeliveryDataLocalBase(this.objectBoxStore);

  // ================================================================
  // BOX GETTERS
  // ================================================================
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<InvoiceItemsModel> get invoiceItemsBox => objectBoxStore.invoiceItemsBox;
  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;
  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;

  // ================================================================
  // HELPER METHODS (formerly private, now public for mixin access)
  // ================================================================

  /// DEDUPLICATION HELPER: Removes duplicate delivery updates by title
  /// Keeps the best version (synced > pending > failed) or most recent
  List<DeliveryUpdateModel> deduplicateDeliveryUpdates(
    List<DeliveryUpdateModel> updates,
  ) {
    if (updates.length <= 1) return updates;

    final Map<String, DeliveryUpdateModel> bestByTitle = {};
    int originalCount = updates.length;

    for (final update in updates) {
      if (update.title == null || update.title!.isEmpty) continue;

      final titleKey = update.title!.toLowerCase().trim();

      // Priority: synced > pending > failed
      int getPriority(DeliveryUpdateModel upd) {
        if (upd.syncStatus == 'synced') return 3;
        if (upd.syncStatus == 'pending') return 2;
        return 1; // failed or other
      }

      if (!bestByTitle.containsKey(titleKey)) {
        bestByTitle[titleKey] = update;
      } else {
        final existing = bestByTitle[titleKey]!;
        final existingPriority = getPriority(existing);
        final currentPriority = getPriority(update);

        bool shouldReplace = false;
        if (currentPriority > existingPriority) {
          shouldReplace = true;
        } else if (currentPriority == existingPriority) {
          final existingTime =
              existing.time ??
              existing.updated ??
              DateTime.fromMicrosecondsSinceEpoch(0);
          final currentTime =
              update.time ??
              update.updated ??
              DateTime.fromMicrosecondsSinceEpoch(0);
          if (currentTime.isAfter(existingTime)) {
            shouldReplace = true;
          }
        }

        if (shouldReplace) {
          bestByTitle[titleKey] = update;
        }
      }
    }

    // Maintain chronological order
    final dedupList = bestByTitle.values.toList();
    dedupList.sort((a, b) {
      final timeA =
          a.time ?? a.updated ?? DateTime.fromMicrosecondsSinceEpoch(0);
      final timeB =
          b.time ?? b.updated ?? DateTime.fromMicrosecondsSinceEpoch(0);
      return timeA.compareTo(timeB);
    });

    if (dedupList.length < originalCount) {
      debugPrint(
        '🧹 DEDUP: Removed ${originalCount - dedupList.length} duplicate update(s), kept ${dedupList.length}',
      );
    }

    return dedupList;
  }

  /// Cleanup existing delivery data linked to a trip
  Future<void> cleanupDeliveryDataByTrip(TripModel trip) async {
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

  /// Cleanup all delivery data (deduplication)
  Future<void> cleanupDeliveryData() async {
    try {
      debugPrint('🧹 LOCAL: Starting delivery data cleanup process');
      final allDeliveryData = deliveryDataBox.getAll();

      // Create a map to track unique delivery data by their PocketBase ID
      final Map<String?, DeliveryDataModel> uniqueDeliveryData = {};

      for (var data in allDeliveryData) {
        // Only keep valid delivery data with required fields
        if (isValidDeliveryData(data)) {
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

  /// Validate delivery data
  bool isValidDeliveryData(DeliveryDataModel data) {
    return data.id != null && data.pocketbaseId.isNotEmpty;
  }

  /// Auto-save delivery data list
  Future<void> autoSave(List<DeliveryDataModel> deliveryDataList) async {
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
      cachedDeliveryData = validDeliveryData;

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

  /// Format time as HH:MM:SS
  String formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  /// Abstract method - needed by forceReloadDeliveryUpdatesByTripId and watchDeliveryDataById
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId);

  /// Abstract method - needed by watchDeliveryDataById
  Future<DeliveryDataModel?> getDeliveryDataById(String id);
}
