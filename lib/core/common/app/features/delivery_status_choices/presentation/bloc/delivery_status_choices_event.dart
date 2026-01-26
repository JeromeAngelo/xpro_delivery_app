import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';

import '../../../trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

abstract class DeliveryStatusChoicesEvent extends Equatable {
  const DeliveryStatusChoicesEvent();
}

class SyncAllDeliveryStatusChoicesEvent extends DeliveryStatusChoicesEvent {
  final List<DeliveryStatusChoicesEntity> deliveryStatusChoices;
  const SyncAllDeliveryStatusChoicesEvent(this.deliveryStatusChoices);

  @override
  // TODO: implement props
  List<Object?> get props => [deliveryStatusChoices];
}

/// 📦 Get ASSIGNED / ALLOWED status choices for a DeliveryData
class GetAllAssignedDeliveryStatusChoicesEvent
    extends DeliveryStatusChoicesEvent {
  final String deliveryDataId;

  const GetAllAssignedDeliveryStatusChoicesEvent(this.deliveryDataId);

  @override
  List<Object?> get props => [deliveryDataId];
}

/// 📝 Update delivery status (choice selected)
class UpdateCustomerStatusEvent extends DeliveryStatusChoicesEvent {
  final String deliveryDataId;
  final DeliveryStatusChoicesEntity status;

  const UpdateCustomerStatusEvent({
    required this.deliveryDataId,
    required this.status,
  });

  @override
  List<Object?> get props => [deliveryDataId, status];
}

/// 📦 Get bulk assigned/allowed status choices for multiple DeliveryData ids
class GetAllBulkDeliveryStatusChoicesEvent extends DeliveryStatusChoicesEvent {
  final List<String> deliveryDataIds;

  const GetAllBulkDeliveryStatusChoicesEvent(this.deliveryDataIds);

  @override
  List<Object?> get props => [deliveryDataIds];
}

/// 📝 Bulk update delivery status for multiple customers
class BulkUpdateDeliveryStatusEvent extends DeliveryStatusChoicesEvent {
  final List<String> deliveryDataIds;
  final DeliveryStatusChoicesEntity status;

  const BulkUpdateDeliveryStatusEvent({
    required this.deliveryDataIds,
    required this.status,
  });

  @override
  List<Object?> get props => [deliveryDataIds, status];
}

// Replace the existing CompleteDeliveryEvent with this:
class SetEndDeliveryEvent extends DeliveryStatusChoicesEvent {
  final DeliveryDataEntity deliveryData;
  
  const SetEndDeliveryEvent({
    required this.deliveryData,
  });
  
  @override
  List<Object> get props => [deliveryData];
}