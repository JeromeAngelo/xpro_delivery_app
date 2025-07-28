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

/// Event to get all delivery data with trips
class GetAllDeliveryDataWithTripsEvent extends DeliveryDataEvent {
  const GetAllDeliveryDataWithTripsEvent();
}

/// Event to add delivery data to existing trip
class AddDeliveryDataToTripEvent extends DeliveryDataEvent {
  final String tripId;

  const AddDeliveryDataToTripEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}
