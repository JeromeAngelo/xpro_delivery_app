import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class UpdateDeliveryStatus implements UsecaseWithParams<void, UpdateDeliveryStatusParams> {
  const UpdateDeliveryStatus(this._repo);

  final DeliveryUpdateRepo _repo;

  @override
  ResultFuture<void> call(UpdateDeliveryStatusParams params) async {
    return _repo.updateDeliveryStatus(params.customerId, params.statusId);
  }
}

class UpdateDeliveryStatusParams extends Equatable {
  const UpdateDeliveryStatusParams({
    required this.customerId,
    required this.statusId,
  });

  final String customerId;
  final String statusId;

  @override
  List<Object?> get props => [customerId, statusId];
}
