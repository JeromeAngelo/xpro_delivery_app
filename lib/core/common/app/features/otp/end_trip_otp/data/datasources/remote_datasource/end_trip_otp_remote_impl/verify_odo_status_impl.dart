import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_impl/end_trip_otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin VerifyOdoStatusImpl on EndTripOtpRemoteBase {
  Future<bool> verifyOdoStatus({
    required String id,
    required bool noOdometer,
  }) async {
    try {
      debugPrint('🔍 Updating End Trip OTP no-odometer status...');
      debugPrint('OTP ID: $id');
      debugPrint('noOdometer: $noOdometer');

      await pocketBaseClient
          .collection('endTripOtp')
          .update(
            id,
            body: {
              'noOdometer': noOdometer,
              if (noOdometer) 'endTripOdometer': null,
            },
          );

      debugPrint('✅ End Trip OTP no-odometer status updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ End Trip OTP no-odometer update error: ${e.toString()}');
      throw ServerException(
        message:
            'Failed to update End Trip OTP no-odometer status: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
