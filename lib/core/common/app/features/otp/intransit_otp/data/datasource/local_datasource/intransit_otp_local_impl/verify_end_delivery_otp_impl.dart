import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/local_datasource/intransit_otp_local_impl/otp_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin VerifyEndDeliveryOtpImpl on OtpLocalBase {
  Future<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  }) async {
    try {
      debugPrint('📱 LOCAL: Verifying End-Delivery OTP');
      final otps = otpBox.getAll();

      if (otps.isNotEmpty) {
        final otp = otps.first;
        if (enteredOtp == otp.generatedCode) {
          otp.otpCode = enteredOtp;
          otp.isVerified = true;
          otp.verifiedAt = DateTime.now();
          otpBox.put(otp);
          debugPrint('✅ LOCAL: End-Delivery OTP verified');
          return true;
        }
      }

      debugPrint('❌ LOCAL: End-Delivery OTP verification failed');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: End-Delivery verification error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
