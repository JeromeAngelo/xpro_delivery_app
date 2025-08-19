import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class UpdateDeliveryLocation extends UsecaseWithParams<DeliveryDataEntity, UpdateDeliveryLocationParams> {
  const UpdateDeliveryLocation(this._repository);

  final DeliveryDataRepo _repository;

  @override
  ResultFuture<DeliveryDataEntity> call(UpdateDeliveryLocationParams params) async {
    return _repository.updateDeliveryLocation(params.id, params.latitude, params.longitude);
  }
}

class UpdateDeliveryLocationParams {
  final String id;
  final double latitude;
  final double longitude;

  const UpdateDeliveryLocationParams({
    required this.id,
    required this.latitude,
    required this.longitude,
  });
}
