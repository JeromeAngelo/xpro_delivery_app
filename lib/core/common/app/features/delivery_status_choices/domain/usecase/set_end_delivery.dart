
import '../../../../../../usecases/usecase.dart';
import '../../../../../../utils/typedefs.dart';
import '../../../trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart' show DeliveryDataEntity;
import '../repo/delivery_status_choices_repo.dart';

class SetEndDeliveryParams {
  final DeliveryDataEntity deliveryData;

  const SetEndDeliveryParams({
    required this.deliveryData,
  });
}

class SetEndDelivery extends UsecaseWithParams<void, SetEndDeliveryParams> {
  const SetEndDelivery(this._repo);

  final DeliveryStatusChoicesRepo _repo;

  @override
  ResultFuture<void> call(SetEndDeliveryParams params) => _repo.setEndDelivery(
    params.deliveryData,
  );
}
