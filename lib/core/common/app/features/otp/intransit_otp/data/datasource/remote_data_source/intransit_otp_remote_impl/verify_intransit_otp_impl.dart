import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/remote_data_source/intransit_otp_remote_impl/otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin VerifyInTransitOtpImpl on OtpRemoteBase {
  Future<bool> verifyInTransitOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  }) async {
    try {
      debugPrint('🔍 Verifying In-Transit OTP...');
      debugPrint('Trip ID: $tripId');
      debugPrint('OTP ID: $otpId');
      debugPrint('Odometer Reading: $odometerReading');
      debugPrint('No Odometer flag: $noOdometer');

      final otpRecord = await pocketBaseClient.collection('otp').getOne(otpId);
      final backendGeneratedCode = otpRecord.data['generatedCode'] as String;
      debugPrint('Backend Generated Code: $backendGeneratedCode');

      if (enteredOtp == backendGeneratedCode) {
        await pocketBaseClient
            .collection('otp')
            .update(
              otpId,
              body: {
                'otpCode': enteredOtp,
                'isVerified': true,
                'verifiedAt': DateTime.now().toIso8601String(),
                'otpType': 'inTransit',
                'trip': tripId,
                if (noOdometer) 'intransitOdometer': null,
                if (!noOdometer) 'intransitOdometer': odometerReading,
                if (noOdometer) 'noOdometer': true,
              },
            );

        debugPrint('✅ OTP verified and odometer reading saved successfully');
        return true;
      }

      debugPrint('❌ OTP verification failed: Code mismatch');
      return false;
    } catch (e) {
      debugPrint('❌ Verification error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to verify OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
