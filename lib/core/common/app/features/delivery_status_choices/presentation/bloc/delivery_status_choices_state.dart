import 'package:equatable/equatable.dart';

import '../../domain/entity/delivery_status_choices_entity.dart';

abstract class DeliveryStatusChoicesState extends Equatable{
  const DeliveryStatusChoicesState();
}

class DeliveryStatusChoicesInitial extends DeliveryStatusChoicesState {
  @override
  // TODO: implement props
  List<Object?> get props => [];
  
}

class DeliveryStatusChoicesLoading extends DeliveryStatusChoicesState {
  @override
  // TODO: implement props
  List<Object?> get props => [];
  
}

class DeliveryStatusChoicesError extends DeliveryStatusChoicesState {
  final String message;
  const DeliveryStatusChoicesError(this.message);
  @override
  // TODO: implement props
  List<Object?> get props => [message];
  
}

class DeliveryStatusChoicesSyncing extends DeliveryStatusChoicesState {
  @override
  // TODO: implement props
  List<Object?> get props => [];
  
}

class DeliveryStatusChoicesSynced extends DeliveryStatusChoicesState {
  final List<DeliveryStatusChoicesEntity> syncedChoices;

  const DeliveryStatusChoicesSynced(this.syncedChoices);

  @override
  List<Object> get props => [syncedChoices];
}

/// 📦 Assigned / allowed choices (offline-first)
class AssignedDeliveryStatusChoicesLoaded
    extends DeliveryStatusChoicesState {
  final List<DeliveryStatusChoicesEntity> updates;

  const AssignedDeliveryStatusChoicesLoaded(this.updates);

  @override
  List<Object?> get props => [updates];
}

/// 📦 Bulk assigned / allowed choices loaded for multiple customers
class BulkAssignedDeliveryStatusChoicesLoaded extends DeliveryStatusChoicesState {
  final Map<String, List<DeliveryStatusChoicesEntity>> choicesByCustomer;

  const BulkAssignedDeliveryStatusChoicesLoaded(this.choicesByCustomer);

  @override
  List<Object?> get props => [choicesByCustomer];
}


/// ✅ Status updated successfully
class DeliveryStatusUpdated extends DeliveryStatusChoicesState {
  const DeliveryStatusUpdated();
  
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

/// ✅ Bulk update completed
class BulkDeliveryStatusUpdated extends DeliveryStatusChoicesState {
  const BulkDeliveryStatusUpdated();

  @override
  List<Object?> get props => [];
}

class EndDeliverySuccess extends DeliveryStatusChoicesState {
  final String deliveryDataId;
  final String? tripId;
  
  const EndDeliverySuccess({
    required this.deliveryDataId,
    this.tripId,
  });
  
  @override
  List<Object?> get props => [deliveryDataId, tripId];
}