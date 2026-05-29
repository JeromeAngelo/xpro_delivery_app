import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/remote_data_source/intransit_otp_remote_impl/otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin VerifyOdoStatusImpl on OtpRemoteBase {
  Future<bool> verifyOdoStatus({
    required String id,
    required bool noOdometer,
  }) async {
    try {
      debugPrint('🔍 Verifying Odometer status for OTP: $id');
      await pocketBaseClient
          .collection('otp')
          .update(id, body: {'noOdometer': noOdometer});
      debugPrint('✅ Updated noOdometer=$noOdometer for OTP: $id');
      return true;
    } catch (e) {
      debugPrint('❌ verifyOdoStatus error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to update noOdometer status: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
