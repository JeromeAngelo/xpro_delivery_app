import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../repo/otp_repo.dart';

class VerifyOdoStatus implements UsecaseWithParams<bool, VerifyOdoStatusParams> {
  const VerifyOdoStatus(this._otpRepo);

  final OtpRepo _otpRepo;

  @override
  ResultFuture<bool> call(VerifyOdoStatusParams params) => _otpRepo.verifyOdoStatus(
        id: params.id,
        noOdometer: params.noOdometer,
      );
}

class VerifyOdoStatusParams {
  final String id;
  final bool noOdometer;

  const VerifyOdoStatusParams({
    required this.id,
    required this.noOdometer,
  });
}