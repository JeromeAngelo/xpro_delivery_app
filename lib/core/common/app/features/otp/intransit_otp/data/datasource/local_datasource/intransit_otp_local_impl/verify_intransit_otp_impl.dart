import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/local_datasource/intransit_otp_local_impl/otp_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin VerifyInTransitOtpImpl on OtpLocalBase {
  Future<bool> verifyInTransitOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  }) async {
    try {
      debugPrint('📱 LOCAL: Verifying In-Transit OTP');
      debugPrint('📍 noOdometer: $noOdometer');
      final query = otpBox.query(OtpModel_.id.equals(otpId)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null && enteredOtp == otp.generatedCode) {
        otp.otpCode = enteredOtp;
        otp.isVerified = true;
        otp.verifiedAt = DateTime.now();
        otp.noOdometer = noOdometer;
        otp.intransitOdometer = noOdometer ? null : odometerReading;
        otp.id = tripId;

        otpBox.put(otp);
        debugPrint('✅ LOCAL: OTP verified and data saved');
        return true;
      }

      debugPrint('❌ LOCAL: OTP verification failed');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: Verification error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
