import 'package:equatable/equatable.dart';

abstract class DeliveryVehicleEvent extends Equatable {
  const DeliveryVehicleEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeliveryVehicleByIdEvent extends DeliveryVehicleEvent {
  final String vehicleId;

  const LoadDeliveryVehicleByIdEvent(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class LoadDeliveryVehiclesByTripIdEvent extends DeliveryVehicleEvent {
  final String tripId;

  const LoadDeliveryVehiclesByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class LoadAllDeliveryVehiclesEvent extends DeliveryVehicleEvent {
  const LoadAllDeliveryVehiclesEvent();
}
