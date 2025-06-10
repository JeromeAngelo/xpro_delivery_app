import 'package:equatable/equatable.dart';
abstract class DeliveryTeamEvent extends Equatable {
  const DeliveryTeamEvent();
}

class LoadLocalDeliveryTeamEvent extends DeliveryTeamEvent {
  final String tripId;
  const LoadLocalDeliveryTeamEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
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

class LoadLocalDeliveryTeamByIdEvent extends DeliveryTeamEvent {
  final String teamId;
  const LoadLocalDeliveryTeamByIdEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
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
