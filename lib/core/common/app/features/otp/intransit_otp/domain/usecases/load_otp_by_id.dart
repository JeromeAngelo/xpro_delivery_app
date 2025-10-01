
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../entity/otp_entity.dart';
import '../repo/otp_repo.dart';

class LoadOtpById extends UsecaseWithParams<OtpEntity, String> {
  const LoadOtpById(this._repo);
  
  final OtpRepo _repo;

  @override
  ResultFuture<OtpEntity> call(String params) => _repo.loadOtpById(params);
}
