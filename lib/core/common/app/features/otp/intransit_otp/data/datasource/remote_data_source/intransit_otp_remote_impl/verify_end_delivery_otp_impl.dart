import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/remote_data_source/intransit_otp_remote_impl/otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin VerifyEndDeliveryOtpImpl on OtpRemoteBase {
  Future<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  }) async {
    try {
      debugPrint('🔍 Verifying End-Delivery OTP...');
      debugPrint('Entered OTP: $enteredOtp');
      debugPrint('Generated OTP: $generatedOtp');

      final otpRecords = await pocketBaseClient.collection('otp').getFullList();

      if (otpRecords.isNotEmpty) {
        final record = otpRecords.first;
        final backendGeneratedCode = record.data['generatedCode'] as String;

        if (enteredOtp == backendGeneratedCode) {
          await pocketBaseClient
              .collection('otp')
              .update(record.id, body: {'otpCode': enteredOtp});
          debugPrint('✅ End-Delivery OTP verification successful!');
          return true;
        }
      }
      debugPrint('❌ End-Delivery OTP verification failed: OTP mismatch');
      return false;
    } catch (e) {
      debugPrint('❌ End-Delivery OTP verification error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to verify end-delivery OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
