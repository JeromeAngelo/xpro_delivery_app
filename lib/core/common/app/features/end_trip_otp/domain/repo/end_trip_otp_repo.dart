import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/entity/end_trip_otp_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class EndTripOtpRepo {

  ResultFuture<String> getEndGeneratedOtp();

   ResultFuture<EndTripOtpEntity> loadEndTripOtpByTripId(String tripId);

    ResultFuture<EndTripOtpEntity> loadEndTripOtpById(String otpId);
  ResultFuture<bool> verifyEndTripOtp({
   required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
  });



}