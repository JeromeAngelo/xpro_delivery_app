import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/repo/end_trip_otp_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class VerifyOdoStatusEndTripOtp
    implements UsecaseWithParams<bool, VerifyOdoStatusEndTripOtpParams> {
  const VerifyOdoStatusEndTripOtp(this._repo);

  final EndTripOtpRepo _repo;

  @override
  ResultFuture<bool> call(VerifyOdoStatusEndTripOtpParams params) {
    return _repo.verifyOdoStatus(id: params.id, noOdometer: params.noOdometer);
  }
}

class VerifyOdoStatusEndTripOtpParams {
  final String id;
  final bool noOdometer;

  const VerifyOdoStatusEndTripOtpParams({
    required this.id,
    required this.noOdometer,
  });
}
