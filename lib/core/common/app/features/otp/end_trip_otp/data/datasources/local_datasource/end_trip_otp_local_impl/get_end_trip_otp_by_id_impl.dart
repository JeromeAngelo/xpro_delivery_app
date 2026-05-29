import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/local_datasource/end_trip_otp_local_impl/end_trip_otp_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin GetEndTripOtpByIdImpl on EndTripOtpLocalBase {
  Future<EndTripOtpModel> getEndTripOtpById(String otpId) async {
    try {
      debugPrint('📱 LOCAL: Fetching End Trip OTP by ID: $otpId');
      final query =
          endTripOtpBox.query(EndTripOtpModel_.id.equals(otpId)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null) {
        debugPrint('✅ LOCAL: Found End Trip OTP record');
        return otp;
      }

      throw const CacheException(
        message: 'End Trip OTP not found',
        statusCode: 404,
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Error fetching End Trip OTP: $e');
      throw CacheException(message: e.toString());
    }
  }
}
