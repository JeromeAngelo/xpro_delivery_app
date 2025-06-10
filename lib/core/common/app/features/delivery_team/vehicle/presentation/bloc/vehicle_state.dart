import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/entity/vehicle_entity.dart';
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

class VehicleLoaded extends VehicleState {
  const VehicleLoaded(this.vehicle);
  final VehicleEntity vehicle;
  
  @override
  List<Object> get props => [vehicle];
}

class VehicleByTripLoaded extends VehicleState {
  final VehicleEntity vehicle;
  final bool isFromLocal;
  
  const VehicleByTripLoaded(this.vehicle, {this.isFromLocal = false});
  
  @override
  List<Object> get props => [vehicle, isFromLocal];
}

class VehicleByDeliveryTeamLoaded extends VehicleState {
  final VehicleEntity vehicle;
  final bool isFromLocal;
  
  const VehicleByDeliveryTeamLoaded(this.vehicle, {this.isFromLocal = false});
  
  @override
  List<Object> get props => [vehicle, isFromLocal];
}

class VehicleError extends VehicleState {
  const VehicleError(this.message);
  final String message;
  
  @override
  List<Object> get props => [message];
}

