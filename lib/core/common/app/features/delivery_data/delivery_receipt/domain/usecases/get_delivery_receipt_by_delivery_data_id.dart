import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/entity/delivery_receipt_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/repo/delivery_receipt_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetDeliveryReceiptByDeliveryDataId extends UsecaseWithParams<DeliveryReceiptEntity, String> {
  const GetDeliveryReceiptByDeliveryDataId(this._repo);

  final DeliveryReceiptRepo _repo;

  @override
  ResultFuture<DeliveryReceiptEntity> call(String deliveryDataId) async {
    return _repo.getDeliveryReceiptByDeliveryDataId(deliveryDataId);
  }

  /// Load delivery receipt from local storage by delivery data ID
  /// 
  /// This method loads the delivery receipt from local cache first
  ResultFuture<DeliveryReceiptEntity> loadFromLocal(String deliveryDataId) async {
    return _repo.getLocalDeliveryReceiptByDeliveryDataId(deliveryDataId);
  }
}
