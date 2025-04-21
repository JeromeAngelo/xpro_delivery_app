import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/entity/otp_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/repo/otp_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadOtpById extends UsecaseWithParams<OtpEntity, String> {
  const LoadOtpById(this._repo);
  
  final OtpRepo _repo;

  @override
  ResultFuture<OtpEntity> call(String params) => _repo.loadOtpById(params);
}
