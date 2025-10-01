import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CompleteDeliveryParams {
  final DeliveryDataEntity deliveryData;

  const CompleteDeliveryParams({
    required this.deliveryData,
  });
}

class CompleteDelivery extends UsecaseWithParams<void, CompleteDeliveryParams> {
  const CompleteDelivery(this._repo);

  final DeliveryUpdateRepo _repo;

  @override
  ResultFuture<void> call(CompleteDeliveryParams params) => _repo.completeDelivery(
    params.deliveryData,
  );
}
