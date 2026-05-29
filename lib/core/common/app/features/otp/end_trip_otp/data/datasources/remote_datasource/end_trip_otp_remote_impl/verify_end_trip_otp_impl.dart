import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_impl/end_trip_otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin VerifyEndTripOtpImpl on EndTripOtpRemoteBase {
  Future<bool> verifyEndTripOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  }) async {
    try {
      debugPrint('🔍 Verifying End-Trip OTP...');
      debugPrint('Entered OTP: $enteredOtp');
      debugPrint('Generated OTP: $generatedOtp');
      debugPrint('Trip ID: $tripId');
      debugPrint('OTP ID: $otpId');
      debugPrint('Odometer Reading: $odometerReading');

      final otpRecord = await pocketBaseClient
          .collection('endTripOtp')
          .getOne(otpId);
      final backendGeneratedCode = otpRecord.data['generatedCode'] as String;
      debugPrint('Backend Generated Code: $backendGeneratedCode');

      if (enteredOtp == backendGeneratedCode) {
        final updateBody = {
          'otpCode': enteredOtp,
          'isVerified': true,
          'verifiedAt': DateTime.now().toIso8601String(),
          'otpType': 'endDelivery',
          'trip': tripId,
          if (noOdometer) 'noOdometer': true,
          if (noOdometer) 'endTripOdometer': null,
          if (!noOdometer) 'endTripOdometer': odometerReading,
        };

        await pocketBaseClient
            .collection('endTripOtp')
            .update(otpId, body: updateBody);

        await pocketBaseClient
            .collection('tripticket')
            .update(
              tripId,
              body: {
                'endTripOtp': otpId,
                'isEndTrip': true,
                'timeEndTrip': DateTime.now().toUtc().toIso8601String(),
                'isAccepted': false,
              },
            );

        final currentUser = pocketBaseClient.authStore.model;
        if (currentUser != null) {
          debugPrint('🔄 Clearing trip assignment for user: ${currentUser.id}');
          await pocketBaseClient
              .collection('users')
              .update(currentUser.id, body: {'tripNumberId': null});
          debugPrint('✅ User trip assignment cleared');
        }

        debugPrint('✅ End Trip OTP verified successfully');
        return true;
      }

      debugPrint('❌ End Trip OTP verification failed: Code mismatch');
      return false;
    } catch (e) {
      debugPrint('❌ End Trip OTP verification error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to verify End Trip OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
