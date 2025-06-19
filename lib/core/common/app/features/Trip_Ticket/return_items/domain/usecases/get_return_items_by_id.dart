import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/domain/entity/return_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/domain/repo/return_items_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetReturnItemById extends UsecaseWithParams<ReturnItemsEntity, String> {
  const GetReturnItemById(this._repo);

  final ReturnItemsRepo _repo;

  @override
  ResultFuture<ReturnItemsEntity> call(String params) => _repo.getReturnItemById(params);
  
  ResultFuture<ReturnItemsEntity> loadFromLocal(String params) => _repo.getReturnItemByLocalById(params);
}
