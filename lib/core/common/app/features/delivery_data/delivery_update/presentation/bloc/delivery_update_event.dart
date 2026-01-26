import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import '../../../../delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';
abstract class DeliveryUpdateEvent extends Equatable {
  const DeliveryUpdateEvent();
}

class GetDeliveryStatusChoicesEvent extends DeliveryUpdateEvent {
  final String customerId;
  const GetDeliveryStatusChoicesEvent(this.customerId);
  
  @override
  List<Object> get props => [customerId];
}

class LoadLocalDeliveryStatusChoicesEvent extends DeliveryUpdateEvent {
  final String customerId;
  const LoadLocalDeliveryStatusChoicesEvent(this.customerId);
  
  @override
  List<Object> get props => [customerId];
}

class GetBulkDeliveryStatusChoicesEvent extends DeliveryUpdateEvent {
  final List<String> customerIds;

  const GetBulkDeliveryStatusChoicesEvent(this.customerIds);

  @override
  List<Object> get props => [customerIds];
}

class LoadLocalBulkDeliveryStatusChoicesEvent extends DeliveryUpdateEvent {
  final List<String> customerIds;

  const LoadLocalBulkDeliveryStatusChoicesEvent(this.customerIds);

  @override
  List<Object> get props => [customerIds];
}


class UpdateDeliveryStatusEvent extends DeliveryUpdateEvent {
  final String deliveryDataId;
  final DeliveryStatusChoicesEntity status;

  const UpdateDeliveryStatusEvent({
    required this.deliveryDataId,
    required this.status,
  });

  @override
  List<Object> get props => [deliveryDataId, status];
}


// Replace the existing CompleteDeliveryEvent with this:
class CompleteDeliveryEvent extends DeliveryUpdateEvent {
  final DeliveryDataEntity deliveryData;
  
  const CompleteDeliveryEvent({
    required this.deliveryData,
  });
  
  @override
  List<Object> get props => [deliveryData];
}


class CheckEndDeliveryStatusEvent extends DeliveryUpdateEvent {
  final String tripId;
  
  const CheckEndDeliveryStatusEvent(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}

class CheckLocalEndDeliveryStatusEvent extends DeliveryUpdateEvent {
  final String tripId;
  
  const CheckLocalEndDeliveryStatusEvent(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}

class BulkUpdateDeliveryStatusEvent extends DeliveryUpdateEvent {
  final List<String> customerIds;
  final String statusId;

  const BulkUpdateDeliveryStatusEvent({
    required this.customerIds,
    required this.statusId,
  });

  @override
  List<Object> get props => [customerIds, statusId];
}




class InitializePendingStatusEvent extends DeliveryUpdateEvent {
  final List<String> customerIds;
  const InitializePendingStatusEvent(this.customerIds);
  @override
  List<Object> get props => [customerIds];
}

class CreateDeliveryStatusEvent extends DeliveryUpdateEvent {
  final String customerId;
  final String title;
  final String subtitle;
  final DateTime time;
  final bool isAssigned;
  final String image;
  const CreateDeliveryStatusEvent({
    required this.customerId,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isAssigned,
    required this.image,
  });
  @override
  List<Object> get props => [customerId, title, subtitle, time, isAssigned, image];
}
class UpdateQueueRemarksEvent extends DeliveryUpdateEvent {
  final String statusId;
  final String remarks;
  final String image;

  const UpdateQueueRemarksEvent({
    required this.statusId,
    required this.remarks,
    required this.image,
  });

  @override
  List<Object> get props => [statusId, remarks, image];
}


class PinArrivedLocationEvent extends DeliveryUpdateEvent {
  final String deliveryId;

  const PinArrivedLocationEvent({
    required this.deliveryId,
  });

  @override
  List<Object> get props => [deliveryId];
}

class SyncDeliveryStatusChoicesEvent extends DeliveryUpdateEvent {
  final String customerId;

  const SyncDeliveryStatusChoicesEvent(this.customerId);

  @override
  List<Object> get props => [customerId];
}
