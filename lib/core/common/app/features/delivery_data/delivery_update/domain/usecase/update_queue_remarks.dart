import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class UpdateQueueRemarks
    extends UsecaseWithParams<void, UpdateQueueRemarksParams> {
  const UpdateQueueRemarks(this._repo);

  final DeliveryUpdateRepo _repo;

  @override
  ResultFuture<void> call(UpdateQueueRemarksParams params) =>
      _repo.updateQueueRemarks(params.statusId, params.remarks, params.image);
}

class UpdateQueueRemarksParams extends Equatable {
  final String statusId;
  final String remarks;
  final String image;

  const UpdateQueueRemarksParams({
    required this.statusId,
    required this.remarks,
    required this.image,
  });

  @override
  List<Object?> get props => [statusId, remarks, image];
}
