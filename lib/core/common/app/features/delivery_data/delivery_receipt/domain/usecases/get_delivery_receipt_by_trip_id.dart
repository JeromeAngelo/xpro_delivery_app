import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/entity/delivery_receipt_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/repo/delivery_receipt_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetDeliveryReceiptByTripId extends UsecaseWithParams<DeliveryReceiptEntity, String> {
  const GetDeliveryReceiptByTripId(this._repo);

  final DeliveryReceiptRepo _repo;

  @override
  ResultFuture<DeliveryReceiptEntity> call(String tripId) async {
    return _repo.getDeliveryReceiptByTripId(tripId);
  }

  /// Load delivery receipt from local storage
  /// 
  /// This method loads the delivery receipt from local cache first
  ResultFuture<DeliveryReceiptEntity> loadFromLocal(String tripId) async {
    return _repo.getLocalDeliveryReceiptByTripId(tripId);
  }
}
