import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/domain/entity/return_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/domain/repo/return_items_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class AddItemsToReturnItemsByDeliveryId extends UsecaseWithParams<ReturnItemsEntity, AddReturnItemsParams> {
  const AddItemsToReturnItemsByDeliveryId(this._repo);

  final ReturnItemsRepo _repo;

  @override
  ResultFuture<ReturnItemsEntity> call(AddReturnItemsParams params) => 
      _repo.addItemsToReturnItemsByDeliveryId(params.deliveryId, params.returnItem);
}

class AddReturnItemsParams extends Equatable {
  const AddReturnItemsParams({
    required this.deliveryId,
    required this.returnItem,
  });

  final String deliveryId;
  final ReturnItemsEntity returnItem;

  @override
  List<Object?> get props => [deliveryId, returnItem];
}
