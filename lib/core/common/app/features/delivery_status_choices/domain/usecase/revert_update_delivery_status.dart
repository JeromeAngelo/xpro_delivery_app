import 'package:equatable/equatable.dart';
import '../../../../../../usecases/usecase.dart';
import '../../../../../../utils/typedefs.dart';
import '../entity/delivery_status_choices_entity.dart';
import '../repo/delivery_status_choices_repo.dart';

class RevertUpdateDeliveryStatus
    implements UsecaseWithParams<void, RevertDeliveryStatusParams> {
  const RevertUpdateDeliveryStatus(this._repo);

  final DeliveryStatusChoicesRepo _repo;

  @override
  ResultFuture<void> call(RevertDeliveryStatusParams params) {
    return _repo.revertUpdateDeliveryStatus(
      params.deliveryDataId,
      params.status,
    );
  }
}

class RevertDeliveryStatusParams extends Equatable {
  const RevertDeliveryStatusParams({
    required this.deliveryDataId,
    required this.status,
  });

  final String deliveryDataId;
  final DeliveryStatusChoicesEntity status;

  @override
  List<Object?> get props => [deliveryDataId, status];
}
