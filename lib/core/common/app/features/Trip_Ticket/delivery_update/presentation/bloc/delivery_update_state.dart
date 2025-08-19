import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
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
  final String customerId;
  final String queueCount;

  const QueueRemarksUpdated({
    required this.customerId,
    required this.queueCount,
  });

  @override
  List<Object> get props => [customerId, queueCount];
}

class PinArrivedLocationSuccess extends DeliveryUpdateState {
  final String deliveryId;

  const PinArrivedLocationSuccess({
    required this.deliveryId,
  });

  @override
  List<Object> get props => [deliveryId];
}




