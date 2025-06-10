import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CalculateDeliveryTimeByDeliveryId extends UsecaseWithParams<int, String> {
  const CalculateDeliveryTimeByDeliveryId(this._repo);

  final DeliveryDataRepo _repo;

  @override
  ResultFuture<int> call(String deliveryId) => _repo.calculateDeliveryTimeByDeliveryId(deliveryId);
}
