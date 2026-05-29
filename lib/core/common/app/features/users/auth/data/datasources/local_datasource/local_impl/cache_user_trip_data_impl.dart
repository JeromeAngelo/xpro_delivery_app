import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin CacheUserTripDataImpl on AuthLocalBase {
  Future<void> cacheUserTripData(TripModel trip) async {
    try {
      debugPrint('💾 Caching trip data locally');

      // Save to SharedPreferences with null-safe parameters
      final tripData = {
        'id': trip.id,
        'tripNumberId': trip.tripNumberId,
        'isAccepted': trip.isAccepted,
        'deliveryTeam':
            trip.deliveryTeam.target?.id, // Consistent serialization
        'personels': trip.personels.map((p) => p.toJson()).toList(),
        'deliveryVehicle': trip.deliveryVehicle.target?.toJson(),
        'checklist': trip.checklist.map((c) => c.toJson()).toList(),
        'deliveryData': trip.deliveryData.map((d) => d.toJson()).toList(),
        'otp': trip.otp.target?.toJson(),
        'endTripOtp': trip.endTripOtp.target?.toJson(),
        'endTripChecklist':
            trip.endTripChecklist.map((e) => e.toJson()).toList(),
        'tripUpdates': trip.tripUpdates.map((u) => u.toJson()).toList(),
        'user': trip.user.target?.toJson(),
        'totalTripDistance': trip.totalTripDistance,
        'latitude': trip.latitude?.toString(),
        'longitude': trip.longitude?.toString(),
        'timeAccepted': trip.timeAccepted?.toIso8601String(),
        'isEndTrip': trip.isEndTrip,
        'timeEndTrip': trip.timeEndTrip?.toIso8601String(),
        'created': trip.created?.toIso8601String(),
        'updated': trip.updated?.toIso8601String(),
        'qrCode': trip.qrCode,
      };

      await prefs.setString('user_trip_data', jsonEncode(tripData));

      debugPrint('✅ Trip cached successfully');
      debugPrint('   🎫 Trip Number: ${trip.tripNumberId ?? 'N/A'}');
      debugPrint(
        '   🚛 Delivery Vehicle: ${trip.deliveryVehicle.target?.plateNo ?? 'Not assigned'}',
      );
      debugPrint('   📦 Delivery Data: ${trip.deliveryData.length}');
      debugPrint('   🔑 OTP: ${trip.otp.target?.id ?? 'Not set'}');
      debugPrint('   📋 End Trip Checklist: ${trip.endTripChecklist.length}');
      debugPrint('   📍 Trip Updates: ${trip.tripUpdates.length}');
    } catch (e) {
      debugPrint('❌ Trip cache operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
