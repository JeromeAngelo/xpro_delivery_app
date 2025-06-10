import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';

abstract class DeliveryVehicleState extends Equatable {
  const DeliveryVehicleState();

  @override
  List<Object?> get props => [];
}

class DeliveryVehicleInitial extends DeliveryVehicleState {}

class DeliveryVehicleLoading extends DeliveryVehicleState {}

class DeliveryVehicleLoaded extends DeliveryVehicleState {
  final DeliveryVehicleEntity vehicle;

  const DeliveryVehicleLoaded(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class DeliveryVehiclesLoaded extends DeliveryVehicleState {
  final List<DeliveryVehicleEntity> vehicles;

  const DeliveryVehiclesLoaded(this.vehicles);

  @override
  List<Object?> get props => [vehicles];
}

class DeliveryVehicleError extends DeliveryVehicleState {
  final String message;

  const DeliveryVehicleError(this.message);

  @override
  List<Object?> get props => [message];
}
