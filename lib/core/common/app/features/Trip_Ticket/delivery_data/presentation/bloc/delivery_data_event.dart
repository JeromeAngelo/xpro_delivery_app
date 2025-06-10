import 'package:equatable/equatable.dart';

abstract class DeliveryDataEvent extends Equatable {
  const DeliveryDataEvent();

  @override
  List<Object?> get props => [];
}

/// Event to get all delivery data
class GetAllDeliveryDataEvent extends DeliveryDataEvent {
  const GetAllDeliveryDataEvent();
}

/// Event to get delivery data by trip ID
class GetDeliveryDataByTripIdEvent extends DeliveryDataEvent {
  final String tripId;

  const GetDeliveryDataByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}
///local delivery data by trip ID
class GetLocalDeliveryDataByTripIdEvent extends DeliveryDataEvent {
  final String tripId;

  const GetLocalDeliveryDataByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Event to delete delivery data by ID
class DeleteDeliveryDataEvent extends DeliveryDataEvent {
  final String id;

  const DeleteDeliveryDataEvent(this.id);

  @override
  List<Object?> get props => [id];
}


/// Event to get delivery data by ID
class GetDeliveryDataByIdEvent extends DeliveryDataEvent {
  final String id;

  const GetDeliveryDataByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Local Event to get delivery data by ID
class GetLocalDeliveryDataByIdEvent extends DeliveryDataEvent {
  final String id;

  const GetLocalDeliveryDataByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to calculate delivery time by delivery ID
class CalculateDeliveryTimeEvent extends DeliveryDataEvent {
  final String deliveryId;

  const CalculateDeliveryTimeEvent(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

/// Event to sync delivery data by trip ID from remote to local
class SyncDeliveryDataByTripIdEvent extends DeliveryDataEvent {
  final String tripId;

  const SyncDeliveryDataByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Event to set invoice into unloading status
class SetInvoiceIntoUnloadingEvent extends DeliveryDataEvent {
  final String deliveryDataId;

  const SetInvoiceIntoUnloadingEvent(this.deliveryDataId);

  @override
  List<Object?> get props => [deliveryDataId];
}

/// Event to set invoice into unloading status
class SetInvoiceIntoUnloadedEvent extends DeliveryDataEvent {
  final String deliveryDataId;

  const SetInvoiceIntoUnloadedEvent(this.deliveryDataId);

  @override
  List<Object?> get props => [deliveryDataId];
}



