import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/domain/entity/return_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/domain/repo/return_items_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetReturnItemsByTripId extends UsecaseWithParams<List<ReturnItemsEntity>, String> {
  const GetReturnItemsByTripId(this._repo);

  final ReturnItemsRepo _repo;

  @override
  ResultFuture<List<ReturnItemsEntity>> call(String params) => _repo.getReturnItemsByTripId(params);
  
  ResultFuture<List<ReturnItemsEntity>> loadFromLocal(String params) => _repo.loadLocalReturnItemsByTripId(params);
}
