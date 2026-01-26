import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class DeliveryUpdateState extends Equatable {
  const DeliveryUpdateState();
}

class DeliveryUpdateInitial extends DeliveryUpdateState {
  @override
  List<Object> get props => [];
}

class DeliveryUpdateLoading extends DeliveryUpdateState {
  @override
  List<Object> get props => [];
}

class DeliveryStatusChoicesLoaded extends DeliveryUpdateState {
  final List<DeliveryUpdateEntity> statusChoices;
  final bool isFromLocal;
  const DeliveryStatusChoicesLoaded(this.statusChoices, {this.isFromLocal = false});
  @override
  List<Object> get props => [statusChoices, isFromLocal];
}

class DeliveryStatusUpdateSuccess extends DeliveryUpdateState {
  final bool isFromLocal;
  const DeliveryStatusUpdateSuccess({this.isFromLocal = false});
  @override
  List<Object> get props => [isFromLocal];
}

class DeliveryUpdateError extends DeliveryUpdateState {
  final String message;
  final bool isLocalError;
  const DeliveryUpdateError(this.message, {this.isLocalError = false});
  @override
  List<Object> get props => [message, isLocalError];
}
// Replace the existing DeliveryCompletionSuccess with this:
class DeliveryCompletionSuccess extends DeliveryUpdateState {
  final String deliveryDataId;
  final String? tripId;
  
  const DeliveryCompletionSuccess({
    required this.deliveryDataId,
    this.tripId,
  });
  
  @override
  List<Object?> get props => [deliveryDataId, tripId];
}

class BulkDeliveryStatusUpdateSuccess extends DeliveryUpdateState {
  final List<String> customerIds;
  final String statusId;
  final bool isFromLocal;

  const BulkDeliveryStatusUpdateSuccess({
    required this.customerIds,
    required this.statusId,
    this.isFromLocal = false,
  });

  @override
  List<Object> get props => [customerIds, statusId, isFromLocal];
}

class BulkDeliveryStatusUpdateError extends DeliveryUpdateState {
  final String message;
  final bool isLocalError;

  const BulkDeliveryStatusUpdateError(this.message, {this.isLocalError = false});

  @override
  List<Object> get props => [message, isLocalError];
}



// delivery_update_state.dart
class EndDeliveryStatusChecked extends DeliveryUpdateState {
  final DataMap stats;
  final String tripId;
  final bool isFromLocal;
  
  const EndDeliveryStatusChecked({
    required this.stats,
    required this.tripId,
    this.isFromLocal = false,
  });
  
  @override
  List<Object> get props => [stats, tripId, isFromLocal];
}

class PendingStatusInitialized extends DeliveryUpdateState {
  @override
  List<Object> get props => [];
}

class DeliveryStatusCreated extends DeliveryUpdateState {
  final String customerId;
  
  const DeliveryStatusCreated(this.customerId);
  
  @override
  List<Object> get props => [customerId];
}
class QueueRemarksUpdated extends DeliveryUpdateState {
  final String statusId;
  final String remarks;
  final String image;

  const QueueRemarksUpdated({
    required this.statusId,
    required this.remarks,
    required this.image,
  });

  @override
  List<Object> get props => [statusId, remarks, image];
}


class PinArrivedLocationSuccess extends DeliveryUpdateState {
  final String deliveryId;

  const PinArrivedLocationSuccess({
    required this.deliveryId,
  });

  @override
  List<Object> get props => [deliveryId];
}

class BulkDeliveryStatusChoicesLoaded extends DeliveryUpdateState {
  final Map<String, List<DeliveryUpdateEntity>> bulkStatusChoices;
  final bool isFromLocal;

  const BulkDeliveryStatusChoicesLoaded(
    this.bulkStatusChoices, {
    this.isFromLocal = false,
  });

  @override
  List<Object> get props => [bulkStatusChoices, isFromLocal];
}

class BulkDeliveryStatusChoicesError extends DeliveryUpdateState {
  final String message;
  final bool isLocalError;

  const BulkDeliveryStatusChoicesError(
    this.message, {
    this.isLocalError = false,
  });

  @override
  List<Object> get props => [message, isLocalError];
}
class DeliveryStatusSyncing extends DeliveryUpdateState {
  final String customerId;

  const DeliveryStatusSyncing(this.customerId);

  @override
  List<Object> get props => [customerId];
}


class DeliveryStatusChoicesSynced extends DeliveryUpdateState {
  final List<DeliveryUpdateEntity> syncedChoices;

  const DeliveryStatusChoicesSynced(this.syncedChoices);

  @override
  List<Object> get props => [syncedChoices];
}



