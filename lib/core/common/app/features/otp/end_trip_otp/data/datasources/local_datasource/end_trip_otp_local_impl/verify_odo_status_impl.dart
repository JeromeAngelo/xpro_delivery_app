import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/local_datasource/end_trip_otp_local_impl/end_trip_otp_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin VerifyOdoStatusImpl on EndTripOtpLocalBase {
  Future<bool> verifyOdoStatus({
    required String id,
    required bool noOdometer,
  }) async {
    try {
      debugPrint('🔐 LOCAL: Updating End Trip OTP no-odometer status');
      final query = endTripOtpBox.query(EndTripOtpModel_.id.equals(id)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null) {
        otp.noOdometer = noOdometer;
        if (noOdometer) {
          otp.endTripOdometer = null;
        }
        endTripOtpBox.put(otp);
        debugPrint('✅ LOCAL: End Trip OTP no-odometer status saved');
        return true;
      }

      debugPrint('❌ LOCAL: End Trip OTP not found for no-odometer update');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: verifyOdoStatus error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
