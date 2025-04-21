import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/repo/otp_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class VerifyInTransitParams {
  final String enteredOtp;
  final String generatedOtp;
  final String tripId;
  final String otpId;
  final String odometerReading;

  const VerifyInTransitParams({
    required this.enteredOtp,
    required this.generatedOtp,
    required this.tripId,
    required this.otpId,
    required this.odometerReading,
  });
}

class VerifyInTransit implements UsecaseWithParams<bool, VerifyInTransitParams> {
  const VerifyInTransit(this._otpRepo);

  final OtpRepo _otpRepo;

  @override
  ResultFuture<bool> call(VerifyInTransitParams params) => _otpRepo.verifyInTransitOtp(
        enteredOtp: params.enteredOtp,
        generatedOtp: params.generatedOtp,
        tripId: params.tripId,
        otpId: params.otpId,
        odometerReading: params.odometerReading,
      );
}

