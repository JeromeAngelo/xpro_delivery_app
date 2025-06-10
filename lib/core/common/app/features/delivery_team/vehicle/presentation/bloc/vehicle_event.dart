import 'package:equatable/equatable.dart';
abstract class VehicleEvent extends Equatable {
  const VehicleEvent();
}

class GetVehicleEvent extends VehicleEvent {
  @override
  List<Object> get props => [];
}

class LoadVehicleByTripIdEvent extends VehicleEvent {
  final String tripId;
  const LoadVehicleByTripIdEvent(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}

class LoadVehicleByDeliveryTeamEvent extends VehicleEvent {
  final String deliveryTeamId;
  const LoadVehicleByDeliveryTeamEvent(this.deliveryTeamId);
  
  @override
  List<Object> get props => [deliveryTeamId];
}

class LoadLocalVehicleByTripIdEvent extends VehicleEvent {
  final String tripId;
  const LoadLocalVehicleByTripIdEvent(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}

class LoadLocalVehicleByDeliveryTeamEvent extends VehicleEvent {
  final String deliveryTeamId;
  const LoadLocalVehicleByDeliveryTeamEvent(this.deliveryTeamId);
  
  @override
  List<Object> get props => [deliveryTeamId];
}
