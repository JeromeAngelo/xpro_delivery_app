import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin SaveTripImpl on TripLocalBase {
  Future<void> saveTrip(TripModel trip) async {
    try {
      debugPrint('💾 LOCAL: Starting trip save');

      if (trip.deliveryTeam.target != null) {
        final deliveryTeamBoxs = deliveryTeamBox;
        final deliveryTeam = trip.deliveryTeam.target!;
        deliveryTeam.tripId = trip.id;

        final deliveryTeamId = deliveryTeamBoxs.put(deliveryTeam);
        debugPrint('✅ LOCAL: Stored delivery team with ID: ${deliveryTeam.id}');
        debugPrint('📦 LOCAL: ObjectBox ID: $deliveryTeamId');
      }

      final tripId = tripBox.put(trip);
      debugPrint('✅ LOCAL: Stored trip with ID: ${trip.id}');
      debugPrint('📦 LOCAL: ObjectBox ID: $tripId');

      // Verify storage
      final storedTrip = tripBox.get(tripId);
      debugPrint('📊 LOCAL: Storage verification:');
      debugPrint('   🚛 Delivery Team: ${storedTrip?.deliveryTeam.target?.id}');
      debugPrint('   👥 Personnel: ${storedTrip?.personels.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Save failed - $e');
      throw CacheException(message: e.toString());
    }
  }
}
