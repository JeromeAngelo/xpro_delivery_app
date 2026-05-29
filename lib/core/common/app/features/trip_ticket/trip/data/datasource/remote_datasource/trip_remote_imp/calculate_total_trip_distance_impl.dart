import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin CalculateTotalTripDistanceImpl on TripRemoteBase {
  Future<String> calculateTotalTripDistance(String tripId) async {
    try {
      debugPrint('📊 Starting total trip distance calculation');

      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Using trip ID: $actualTripId');

      // Get start odometer from in-transit OTP
      final otpRecords = await pocketBaseClient
          .collection('otp')
          .getList(filter: 'trip = "$actualTripId"', sort: '-created');

      // Get end odometer from end-trip OTP
      final endTripOtpRecords = await pocketBaseClient
          .collection('endTripOtp')
          .getList(filter: 'trip = "$actualTripId"', sort: '-created');

      if (otpRecords.items.isEmpty || endTripOtpRecords.items.isEmpty) {
        debugPrint('⚠️ Missing OTP records for distance calculation');
        throw const ServerException(
          message: 'Missing OTP records',
          statusCode: '404',
        );
      }

      final startOdometer =
          otpRecords.items.first.data['intransitOdometer'] ?? '0';
      final endOdometer =
          endTripOtpRecords.items.first.data['endTripOdometer'] ?? '0';

      debugPrint('🔢 Start Odometer: $startOdometer');
      debugPrint('🔢 End Odometer: $endOdometer');

      final totalDistance =
          (int.parse(endOdometer) - int.parse(startOdometer)).toString();
      debugPrint('📏 Calculated total distance: $totalDistance');

      // Update trip with total distance
      await pocketBaseClient
          .collection('tripticket')
          .update(actualTripId, body: {'totalTripDistance': totalDistance});

      debugPrint('✅ Total trip distance updated successfully');
      return totalDistance;
    } catch (e) {
      debugPrint('❌ Failed to calculate trip distance: $e');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
