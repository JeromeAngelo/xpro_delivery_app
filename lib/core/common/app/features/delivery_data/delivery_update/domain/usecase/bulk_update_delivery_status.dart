import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/repo/delivery_update_repo.dart';

import 'package:equatable/equatable.dart';

import '../../../../../../../usecases/usecase.dart';

// Params object for bulk update
class BulkUpdateDeliveryStatusParams extends Equatable {
  final List<String> customerIds;
  final String statusId;

  const BulkUpdateDeliveryStatusParams({
    required this.customerIds,
    required this.statusId,
  });

  @override
  List<Object?> get props => [customerIds, statusId];
}

// Use case class
class BulkUpdateDeliveryStatus
    extends UsecaseWithParams<void, BulkUpdateDeliveryStatusParams> {
  final DeliveryUpdateRepo repository;

  const BulkUpdateDeliveryStatus(this.repository);

  @override
  ResultFuture<void> call(BulkUpdateDeliveryStatusParams params) {
    return repository.bulkUpdateDeliveryStatus(
      params.customerIds,
      params.statusId,
    );
  }
}
