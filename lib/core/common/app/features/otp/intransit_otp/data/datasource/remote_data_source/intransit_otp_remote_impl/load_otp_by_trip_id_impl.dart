import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/otp_type.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/remote_data_source/intransit_otp_remote_impl/otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import '../../../models/otp_models.dart';

mixin LoadOtpByTripIdImpl on OtpRemoteBase {
  Future<OtpModel> loadOtpByTripId(String tripId) async {
    try {
      debugPrint('🔍 Starting OTP load process for trip: $tripId');

      // Get stored user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');
      debugPrint('📦 Raw stored user data: $storedUserData');

      if (storedUserData == null) {
        throw const ServerException(
          message: 'No stored user data found',
          statusCode: '404',
        );
      }

      final userData = jsonDecode(storedUserData);
      debugPrint('🔄 Parsed user data: $userData');

      // Direct query using provided trip ID
      debugPrint('🎯 Using direct trip ID on OTP: $tripId');
      final otpRecords = await pocketBaseClient
          .collection('otp')
          .getFullList(expand: 'trip', filter: 'trip = "$tripId"');

      if (otpRecords.isEmpty) {
        debugPrint('⚠️ No OTP records found');
        throw const ServerException(
          message: 'No OTP found for this trip',
          statusCode: '404',
        );
      }

      final record = otpRecords.first;
      debugPrint('✅ Found OTP record ID: ${record.id}');
      debugPrint('📄 OTP Data: ${record.data}');

      return OtpModel(
        id: record.id,
        generatedCode: record.data['generatedCode'],
        otpCode: record.data['otpCode'],
        isVerified: record.data['isVerified'] ?? false,
        verifiedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        otpType:
            record.data['otpType']?.toString().isNotEmpty == true
                ? OtpType.values.firstWhere(
                  (type) =>
                      type.toString() == 'OtpType.${record.data['otpType']}',
                  orElse: () => OtpType.inTransit,
                )
                : OtpType.inTransit,
        trip: TripModel(id: tripId),
        intransitOdometer: record.data['intransitOdometer'],
      );
    } catch (e) {
      debugPrint('❌ Error in loadOtpByTripId: $e');
      throw ServerException(
        message: 'Failed to load OTP by trip id: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
