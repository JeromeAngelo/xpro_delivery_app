import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/remote_data_source/intransit_otp_remote_impl/otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetGeneratedOtpImpl on OtpRemoteBase {
  Future<String> getGeneratedOtp() async {
    try {
      final otpRecords = await pocketBaseClient.collection('otp').getFullList();
      if (otpRecords.isNotEmpty) {
        final generatedCode = otpRecords.first.data['generatedCode'];
        if (generatedCode != null) {
          return generatedCode.toString();
        }
        throw const ServerException(
          message: 'Generated OTP code is null',
          statusCode: '404',
        );
      }
      throw const ServerException(
        message: 'No OTP records found',
        statusCode: '404',
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to get OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
