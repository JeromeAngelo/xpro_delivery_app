import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:equatable/equatable.dart';

abstract class VehicleState extends Equatable {
  const VehicleState();

  @override
  List<Object> get props => [];
}

class VehicleInitial extends VehicleState {
  const VehicleInitial();
}

class VehicleLoading extends VehicleState {
  const VehicleLoading();
}

class VehiclesLoaded extends VehicleState {
  final List<VehicleEntity> vehicles;
  
  const VehiclesLoaded(this.vehicles);
  
  @override
  List<Object> get props => [vehicles];
}

class VehicleByTripLoaded extends VehicleState {
  final VehicleEntity vehicle;
  
  const VehicleByTripLoaded(this.vehicle);
  
  @override
  List<Object> get props => [vehicle];
}

class VehicleByDeliveryTeamLoaded extends VehicleState {
  final VehicleEntity vehicle;
  
  const VehicleByDeliveryTeamLoaded(this.vehicle);
  
  @override
  List<Object> get props => [vehicle];
}

class VehicleCreated extends VehicleState {
  final VehicleEntity vehicle;
  
  const VehicleCreated(this.vehicle);
  
  @override
  List<Object> get props => [vehicle];
}

class VehicleUpdated extends VehicleState {
  final VehicleEntity vehicle;
  
  const VehicleUpdated(this.vehicle);
  
  @override
  List<Object> get props => [vehicle];
}

class VehicleDeleted extends VehicleState {
  final String vehicleId;
  
  const VehicleDeleted(this.vehicleId);
  
  @override
  List<Object> get props => [vehicleId];
}

class AllVehiclesDeleted extends VehicleState {
  final List<String> vehicleIds;
  
  const AllVehiclesDeleted(this.vehicleIds);
  
  @override
  List<Object> get props => [vehicleIds];
}

class VehicleError extends VehicleState {
  final String message;
  
  const VehicleError(this.message);
  
  @override
  List<Object> get props => [message];
}
