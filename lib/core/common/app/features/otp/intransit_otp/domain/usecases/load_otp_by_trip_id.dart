
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../entity/otp_entity.dart';
import '../repo/otp_repo.dart';

class LoadOtpByTripId extends UsecaseWithParams<OtpEntity, String> {
  const LoadOtpByTripId(this._repo);
  
  final OtpRepo _repo;

  @override
  ResultFuture<OtpEntity> call(String params) => _repo.loadOtpByTripId(params);
}
