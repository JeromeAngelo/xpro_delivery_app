import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';
class UpdateDeliveryStatus
    implements UsecaseWithParams<void, UpdateDeliveryStatusParams> {
  const UpdateDeliveryStatus(this._repo);

  final DeliveryUpdateRepo _repo;

  @override
  ResultFuture<void> call(UpdateDeliveryStatusParams params) {
    return _repo.updateDeliveryStatus(
      params.deliveryDataId,
      params.status,
    );
  }
}

class UpdateDeliveryStatusParams extends Equatable {
  const UpdateDeliveryStatusParams({
    required this.deliveryDataId,
    required this.status,
  });

  final String deliveryDataId;
  final DeliveryStatusChoicesEntity status;

  @override
  List<Object?> get props => [deliveryDataId, status];
}
