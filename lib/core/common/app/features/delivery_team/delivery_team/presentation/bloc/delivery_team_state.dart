import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/presentation/bloc/personel_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/presentation/bloc/checklist_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/presentation/bloc/delivery_vehicle_state.dart';

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
  final DeliveryTeamEntity deliveryTeam;
  final TripState tripState;
  final PersonelState personelState;
  final ChecklistState checklistState;
  final DeliveryVehicleState deliveryVehicleState;

  const DeliveryTeamLoaded({
    required this.deliveryTeam,
    required this.tripState,
    required this.personelState,
    required this.checklistState,
    required this.deliveryVehicleState
  });

  @override
  List<Object> get props => [
    deliveryTeam,
    tripState,
    personelState,
    checklistState,
    deliveryVehicleState
  ];
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
