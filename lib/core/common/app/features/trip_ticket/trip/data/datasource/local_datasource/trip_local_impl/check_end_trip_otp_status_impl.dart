import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CheckEndTripOtpStatusImpl on TripLocalBase {
  Future<bool> checkEndTripOtpStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end trip OTP status for: $tripId');

      final trips = tripBox.getAll().where((trip) => trip.id == tripId);
      if (trips.isEmpty) {
        throw const CacheException(message: 'Trip not found in local storage');
      }

      final trip = trips.first;
      final hasEndTripOtp = trip.endTripOtp.target != null;
      final isEndTrip = trip.isEndTrip;

      debugPrint('📊 End Trip Status Check:');
      debugPrint('Has End Trip OTP: $hasEndTripOtp');
      debugPrint('Is End Trip: $isEndTrip');

      return hasEndTripOtp && isEndTrip!;
    } catch (e) {
      debugPrint('❌ End trip status check failed: $e');
      throw CacheException(message: e.toString());
    }
  }
}
