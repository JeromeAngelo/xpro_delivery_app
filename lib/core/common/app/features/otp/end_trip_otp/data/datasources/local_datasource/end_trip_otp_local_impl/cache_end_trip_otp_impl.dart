import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/local_datasource/end_trip_otp_local_impl/end_trip_otp_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheEndTripOtpImpl on EndTripOtpLocalBase {
  Future<void> cacheEndTripOtp(EndTripOtpModel otp) async {
    try {
      debugPrint('💾 LOCAL: Caching End Trip OTP');
      endTripOtpBox.put(otp);
      debugPrint('✅ LOCAL: End Trip OTP cached successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Cache error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
