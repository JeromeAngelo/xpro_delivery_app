import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/entity/delivery_team_entity.dart';

abstract class DeliveryTeamState extends Equatable {
  const DeliveryTeamState();

  @override
  List<Object> get props => [];
}

class DeliveryTeamInitial extends DeliveryTeamState {
  const DeliveryTeamInitial();
}

class DeliveryTeamLoading extends DeliveryTeamState {
  const DeliveryTeamLoading();
}

class DeliveryTeamLoaded extends DeliveryTeamState {
  final String tripId;
  final DeliveryTeamEntity deliveryTeam;

  const DeliveryTeamLoaded({
    required this.tripId,
    required this.deliveryTeam,
  });

  @override
  List<Object> get props => [tripId, deliveryTeam];
}

class DeliveryTeamError extends DeliveryTeamState {
  final String message;
  const DeliveryTeamError(this.message);

  @override
  List<Object> get props => [message];
}

class DeliveryTeamAssigned extends DeliveryTeamState {
  final String deliveryTeamId;
  final String tripId;

  const DeliveryTeamAssigned({
    required this.deliveryTeamId,
    required this.tripId,
  });

  @override
  List<Object> get props => [deliveryTeamId, tripId];
}

class DeliveryTeamSyched extends DeliveryTeamState {
  final String tripId;

  const DeliveryTeamSyched({
    required this.tripId,
  });

  @override
  List<Object> get props => [ tripId];
}
