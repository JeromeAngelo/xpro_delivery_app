
// Params object for bulk update
import 'package:equatable/equatable.dart';

import '../../../../../../usecases/usecase.dart';
import '../../../../../../utils/typedefs.dart';
import '../entity/delivery_status_choices_entity.dart';
import '../repo/delivery_status_choices_repo.dart';

class BulkUpdateDeliveryStatusUsecaseParams extends Equatable {
  final List<String> customerIds;
  final DeliveryStatusChoicesEntity statusId;

  const BulkUpdateDeliveryStatusUsecaseParams({
    required this.customerIds,
    required this.statusId,
  });

  @override
  List<Object?> get props => [customerIds, statusId];
}

// Use case class
class BulkUpdateDeliveryStatusUsecase
    extends UsecaseWithParams<void, BulkUpdateDeliveryStatusUsecaseParams> {
  final DeliveryStatusChoicesRepo repository;

  const BulkUpdateDeliveryStatusUsecase(this.repository);

  @override
  ResultFuture<void> call(BulkUpdateDeliveryStatusUsecaseParams params) {
    return repository.bulkUpdateDeliveryStatus(
      params.customerIds,
      params.statusId,
    );
  }
}
