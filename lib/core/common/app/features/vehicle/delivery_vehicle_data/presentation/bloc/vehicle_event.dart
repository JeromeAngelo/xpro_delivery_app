import 'package:equatable/equatable.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();
}

class GetVehiclesEvent extends VehicleEvent {
  const GetVehiclesEvent();
  
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

class CreateVehicleEvent extends VehicleEvent {
  final String vehicleName;
  final String vehiclePlateNumber;
  final String vehicleType;
  final String? deliveryTeamId;
  final String? tripId;
  
  const CreateVehicleEvent({
    required this.vehicleName,
    required this.vehiclePlateNumber,
    required this.vehicleType,
    this.deliveryTeamId,
    this.tripId,
  });
  
  @override
  List<Object?> get props => [
    vehicleName,
    vehiclePlateNumber,
    vehicleType,
    deliveryTeamId,
    tripId,
  ];
}

class UpdateVehicleEvent extends VehicleEvent {
  final String vehicleId;
  final String? vehicleName;
  final String? vehiclePlateNumber;
  final String? vehicleType;
  final String? deliveryTeamId;
  final String? tripId;
  
  const UpdateVehicleEvent({
    required this.vehicleId,
    this.vehicleName,
    this.vehiclePlateNumber,
    this.vehicleType,
    this.deliveryTeamId,
    this.tripId,
  });
  
  @override
  List<Object?> get props => [
    vehicleId,
    vehicleName,
    vehiclePlateNumber,
    vehicleType,
    deliveryTeamId,
    tripId,
  ];
}

class DeleteVehicleEvent extends VehicleEvent {
  final String vehicleId;
  
  const DeleteVehicleEvent(this.vehicleId);
  
  @override
  List<Object> get props => [vehicleId];
}

class DeleteAllVehiclesEvent extends VehicleEvent {
  final List<String> vehicleIds;
  
  const DeleteAllVehiclesEvent(this.vehicleIds);
  
  @override
  List<Object> get props => [vehicleIds];
}
