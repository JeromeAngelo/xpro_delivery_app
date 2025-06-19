import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/domain/entity/return_items_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class ReturnItemsRepo {
  // Remote operations
  ResultFuture<List<ReturnItemsEntity>> getReturnItemsByTripId(String tripId);
  ResultFuture<ReturnItemsEntity> getReturnItemById(String returnItemId);
  ResultFuture<ReturnItemsEntity> addItemsToReturnItemsByDeliveryId(String deliveryId, ReturnItemsEntity returnItem);

  // Local operations
  ResultFuture<List<ReturnItemsEntity>> loadLocalReturnItemsByTripId(String tripId);
  ResultFuture<ReturnItemsEntity> getReturnItemByLocalById(String returnItemId);
}
