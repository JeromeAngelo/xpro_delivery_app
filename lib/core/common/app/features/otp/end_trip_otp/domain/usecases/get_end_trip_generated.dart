import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/repo/end_trip_otp_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetEndTripGeneratedOtp extends UsecaseWithoutParams<String> {
  const GetEndTripGeneratedOtp(this._repo);

  final EndTripOtpRepo _repo;

  @override
  ResultFuture<String> call() async => _repo.getEndGeneratedOtp();
}
