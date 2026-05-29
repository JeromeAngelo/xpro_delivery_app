import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetTripUpdatesImpl on TripUpdateLocalBase {
  Future<List<TripUpdateModel>> getTripUpdates(String tripId) async {
    try {
      debugPrint('📥 LOCAL: Fetching TripUpdates for trip: $tripId');

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

      // -------------------------------------------------------------
      // 2️⃣ Get TripUpdates linked to this trip
      // -------------------------------------------------------------
      final tripUpdateSet = <String, TripUpdateModel>{}; // deduplicate by PB ID
      for (final t in trip.tripUpdates) {
        final fullUpdate = tripUpdateBox.get(t.objectBoxId);
        if (fullUpdate != null) {
          tripUpdateSet[fullUpdate.id ?? ""] = fullUpdate;
        }
      }

      if (tripUpdateSet.isEmpty) {
        debugPrint("⚠️ No TripUpdates found for trip: ${trip.name}");
        return [];
      }

      final output = <TripUpdateModel>[];

      // -------------------------------------------------------------
      // 3️⃣ Load nested relations safely
      // -------------------------------------------------------------
      for (final update in tripUpdateSet.values) {
        debugPrint('📄 Loading relations for TripUpdate → ${update.id}');

        // 🔗 Trip relation
        final t = update.trip.target;
        if (t != null) {
          final fullTrip = tripBox.get(t.objectBoxId);
          if (fullTrip != null) {
            update.trip.target = fullTrip;
            update.tripId = fullTrip.id;
            debugPrint('🔗 Trip loaded → ${fullTrip.name}');
          }
        }

        // Add to final output
        output.add(update);
      }

      debugPrint(
        "📦 Found ${output.length} TripUpdates linked to trip: ${trip.name}",
      );

      return output;
    } catch (e, st) {
      debugPrint('❌ getTripUpdates ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
