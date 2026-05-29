import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin CalculateTotalTripDistanceImpl on TripLocalBase {
  Future<String> calculateTotalTripDistance(String tripId) async {
    try {
      debugPrint('📊 LOCAL: Calculating total trip distance');
      final trip =
          tripBox
              .query(TripModel_.pocketbaseId.equals(tripId))
              .build()
              .findFirst();

      if (trip != null) {
        final startOdometer = trip.otp.target?.intransitOdometer ?? '0';
        final endOdometer = trip.endTripOtp.target?.endTripOdometer ?? '0';

        final totalDistance =
            (int.parse(endOdometer) - int.parse(startOdometer)).toString();
        trip.totalTripDistance = totalDistance;

        tripBox.put(trip);
        debugPrint(
          '✅ LOCAL: Total trip distance calculated: $totalDistance km',
        );
        return totalDistance;
      } else {
        throw const CacheException(message: 'Trip not found in local storage');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to calculate trip distance: $e');
      throw CacheException(message: e.toString());
    }
  }
}
