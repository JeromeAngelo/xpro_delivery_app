import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/repo/return_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetReturnByCustomerId implements UsecaseWithParams<ReturnEntity, String> {
  const GetReturnByCustomerId(this._repo);

  final ReturnRepo _repo;

  @override
  ResultFuture<ReturnEntity> call(String params) => _repo.getReturnByCustomerId(params);
}
