import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:equatable/equatable.dart';

abstract class DeliveryTeamEvent extends Equatable {
  const DeliveryTeamEvent();
}

class LoadDeliveryTeamEvent extends DeliveryTeamEvent {
  final String tripId;
  const LoadDeliveryTeamEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class LoadDeliveryTeamByIdEvent extends DeliveryTeamEvent {
  final String teamId;
  const LoadDeliveryTeamByIdEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

class LoadAllDeliveryTeamsEvent extends DeliveryTeamEvent {
  const LoadAllDeliveryTeamsEvent();

  @override
  List<Object?> get props => [];
}

class AssignDeliveryTeamToTripEvent extends DeliveryTeamEvent {
  final String tripId;
  final String deliveryTeamId;
  
  const AssignDeliveryTeamToTripEvent({
    required this.tripId,
    required this.deliveryTeamId,
  });

  @override
  List<Object> get props => [tripId, deliveryTeamId];
}

class CreateDeliveryTeamEvent extends DeliveryTeamEvent {
  final String deliveryTeamId;
  final VehicleEntity vehicle;
  final List<PersonelEntity> personels;
  final TripEntity tripId;
  
  const CreateDeliveryTeamEvent({
    required this.deliveryTeamId,
    required this.vehicle,
    required this.personels,
    required this.tripId,
  });
  
  @override
  List<Object?> get props => [deliveryTeamId, vehicle, personels, tripId];
}

class UpdateDeliveryTeamEvent extends DeliveryTeamEvent {
  final String deliveryTeamId;
  final VehicleEntity vehicle;
  final List<PersonelEntity> personels;
  final TripEntity tripId;
  
  const UpdateDeliveryTeamEvent({
    required this.deliveryTeamId,
    required this.vehicle,
    required this.personels,
    required this.tripId,
  });
  
  @override
  List<Object?> get props => [deliveryTeamId, vehicle, personels, tripId];
}

class DeleteDeliveryTeamEvent extends DeliveryTeamEvent {
  final String deliveryTeamId;
  
  const DeleteDeliveryTeamEvent(this.deliveryTeamId);
  
  @override
  List<Object?> get props => [deliveryTeamId];
}
