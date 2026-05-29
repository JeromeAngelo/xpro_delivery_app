import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/local_datasource/end_trip_otp_local_impl/end_trip_otp_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin VerifyEndTripOtpImpl on EndTripOtpLocalBase {
  Future<bool> verifyEndTripOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  }) async {
    try {
      debugPrint('🔐 LOCAL: Verifying End Trip OTP');
      final query =
          endTripOtpBox.query(EndTripOtpModel_.id.equals(otpId)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null && enteredOtp == otp.generatedCode) {
        otp.otpCode = enteredOtp;
        otp.isVerified = true;
        otp.verifiedAt = DateTime.now();
        otp.noOdometer = noOdometer;
        otp.endTripOdometer = noOdometer ? null : odometerReading;
        otp.trip.target?.id = tripId;

        endTripOtpBox.put(otp);
        debugPrint('✅ LOCAL: End Trip OTP verified and data saved');
        return true;
      }

      debugPrint('❌ LOCAL: End Trip OTP verification failed');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: Verification error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
