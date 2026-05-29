import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CreateTripUpdateImpl on TripUpdateLocalBase {
  Future<void> createTripUpdate({
    required String tripId,
    required String description,
    required String image,
    required String latitude,
    required String longitude,
    required TripUpdateStatus status,
  }) async {
    try {
      debugPrint('📥 LOCAL: Creating new TripUpdate');
      debugPrint('🏷️ Trip ID: $tripId');

      // -------------------------------------------------------------
      // 1️⃣ Find Trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint('⚠️ Trip not found for TripUpdate creation: $tripId');
        return;
      }

      // -------------------------------------------------------------
      // 2️⃣ Create TripUpdate model
      // -------------------------------------------------------------
      final newUpdate =
          TripUpdateModel(
              id: '', // no PB ID yet (local-first)
              collectionName: 'tripUpdates',
              status: status,
              date: DateTime.now(),
              image: image,
              description: description,
              latitude: latitude,
              longitude: longitude,
              tripData: trip,
              tripId: trip.id,
              hasTrip: true,
              hasPendingSync: true,
            )
            ..syncStatus = SyncStatus.pending.name
            ..retryCount = 0
            ..lastSyncAttemptAt = null
            ..nextRetryAt = null
            ..version = 0;

      // -------------------------------------------------------------
      // 3️⃣ Store locally
      // -------------------------------------------------------------
      final newId = tripUpdateBox.put(newUpdate);
      final stored = tripUpdateBox.get(newId)!;

      debugPrint(
        '✅ LOCAL: TripUpdate stored → OBX: ${stored.objectBoxId}, Status: ${stored.status}',
      );

      // -------------------------------------------------------------
      // 4️⃣ Attach to Trip (toMany)
      // -------------------------------------------------------------
      trip.tripUpdates.add(stored);
      tripBox.put(trip);

      debugPrint(
        '🔗 TripUpdate linked → Trip: ${trip.name}, '
        'TripUpdates count: ${trip.tripUpdates.length}',
      );

      // -------------------------------------------------------------
      // 5️⃣ Normalize via sync function (dedupe & safety)
      // -------------------------------------------------------------
      await syncTripUpdatesForTrip(trip);

      debugPrint('🟢 TripUpdate creation & sync complete → Trip: ${trip.name}');
    } catch (e, st) {
      debugPrint('❌ createTripUpdate ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
