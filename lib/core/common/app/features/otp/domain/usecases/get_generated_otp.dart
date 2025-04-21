import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/repo/otp_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetGeneratedOtp extends UsecaseWithoutParams<String> {
  const GetGeneratedOtp(this._repo);

  final OtpRepo _repo;

  @override
  ResultFuture<String> call() async => _repo.getGeneratedOtp();
}
