import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/local_datasource/intransit_otp_local_impl/otp_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin VerifyOdoStatusImpl on OtpLocalBase {
  Future<bool> verifyOdoStatus({
    required String id,
    required bool noOdometer,
  }) async {
    try {
      debugPrint('📱 LOCAL: Updating noOdometer status for OTP id: $id');
      final query = otpBox.query(OtpModel_.id.equals(id)).build();
      final otp = query.findFirst();
      query.close();

      if (otp == null) {
        debugPrint('⚠️ LOCAL: OTP not found for id: $id');
        return false;
      }

      otp.noOdometer = noOdometer;
      otpBox.put(otp);
      debugPrint('✅ LOCAL: noOdometer set to $noOdometer for OTP id: $id');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: verifyOdoStatus error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
