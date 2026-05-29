import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_impl/end_trip_otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetEndGeneratedOtpImpl on EndTripOtpRemoteBase {
  Future<String> getEndGeneratedOtp() async {
    try {
      final otpRecords =
          await pocketBaseClient.collection('endTripOtp').getFullList();

      if (otpRecords.isNotEmpty) {
        final generatedCode = otpRecords.first.data['generatedCode'];
        if (generatedCode != null) {
          return generatedCode.toString();
        }
        throw const ServerException(
          message: 'Generated End Trip OTP code is null',
          statusCode: '404',
        );
      }
      throw const ServerException(
        message: 'No End Trip OTP records found',
        statusCode: '404',
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to get End Trip OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
