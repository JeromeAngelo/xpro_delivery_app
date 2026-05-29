import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../models/trip_models.dart';

mixin UpdateTripLocationLocalImpl on TripLocalBase {
  Future<TripModel> updateTripLocationLocal(
    String tripId,
    double latitude,
    double longitude, {
    double? accuracy,
    String? source,
    double? totalDistance,
  }) async {
    try {
      debugPrint(
        "\n================= 📍 LOCAL TRIP LOCATION UPDATE =================",
      );
      debugPrint("🆔 tripId: $tripId");
      debugPrint("📍 Lat: ${latitude.toStringAsFixed(6)}");
      debugPrint("📍 Long: ${longitude.toStringAsFixed(6)}");
      debugPrint("🎯 Accuracy: ${accuracy?.toStringAsFixed(2) ?? 'null'}");
      debugPrint("📡 Source: ${source ?? 'GPS_Enhanced'}");
      debugPrint("🛣 TotalDistance: $totalDistance");
      debugPrint(
        "==============================================================\n",
      );

      // 1️⃣ Get Trip from ObjectBox
      TripModel? trip;
      final parsedObjectBoxId = int.tryParse(tripId);
      if (parsedObjectBoxId != null) {
        trip = tripBox.get(parsedObjectBoxId);
      }

      trip ??=
          tripBox
              .query(TripModel_.pocketbaseId.equals(tripId))
              .build()
              .findFirst();
      trip ??= tripBox.query(TripModel_.id.equals(tripId)).build().findFirst();
      trip ??=
          tripBox
              .query(TripModel_.tripNumberId.equals(tripId))
              .build()
              .findFirst();

      if (trip == null) {
        debugPrint("❌ Local Trip NOT FOUND for ID: $tripId");
        throw Exception("Trip not found in local DB");
      }

      debugPrint(
        "📦 Local Trip loaded → name: ${trip.name}, numberId: ${trip.tripNumberId}",
      );

      // 2️⃣ Update fields locally
      trip.latitude = latitude;
      trip.longitude = longitude;
      trip.accuracy = accuracy ?? 0;
      trip.source = source ?? "GPS_Enhanced";
      trip.updated = DateTime.now();

      // Optional: save total distance if you store it locally
      if (totalDistance != null) {
        trip.tripDistance = totalDistance;
      }

      // 3️⃣ Save back to ObjectBox
      tripBox.put(trip);

      debugPrint("💾 Trip location updated locally!");
      debugPrint("🧭 New Location → ${trip.latitude}, ${trip.longitude}");
      debugPrint("🧩 Updated TripModel saved.");
      debugPrint("================= ✅ LOCAL UPDATE DONE =================\n");

      return trip;
    } catch (e, stack) {
      debugPrint("❌ LOCAL updateTripLocation ERROR: $e");
      debugPrint("🪵 STACK: $stack");
      throw Exception("Local update trip location failed: $e");
    }
  }
}
