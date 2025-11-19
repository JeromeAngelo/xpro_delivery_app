

import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/assign_delivery_team_to_trip.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/create_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/delete_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/load_all_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/update_delivery_team.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/presentation/bloc/vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryTeamBloc extends Bloc<DeliveryTeamEvent, DeliveryTeamState> {
  final TripBloc _tripBloc;
  final PersonelBloc _personelBloc;
  final VehicleBloc _vehicleBloc;
  final ChecklistBloc _checklistBloc;

  final LoadAllDeliveryTeam _loadAllDeliveryTeam;
  final AssignDeliveryTeamToTrip _assignDeliveryTeamToTrip;
  final CreateDeliveryTeam _createDeliveryTeam;
  final UpdateDeliveryTeam _updateDeliveryTeam;
  final DeleteDeliveryTeam _deleteDeliveryTeam;
  DeliveryTeamState? _cachedState;

  DeliveryTeamBloc({
    required TripBloc tripBloc,
    required PersonelBloc personelBloc,
    required VehicleBloc vehicleBloc,
    required ChecklistBloc checklistBloc,

    required LoadAllDeliveryTeam loadAllDeliveryTeam,
    required AssignDeliveryTeamToTrip assignDeliveryTeamToTrip,
    required CreateDeliveryTeam createDeliveryTeam,
    required UpdateDeliveryTeam updateDeliveryTeam,
    required DeleteDeliveryTeam deleteDeliveryTeam,
  })  : _tripBloc = tripBloc,
        _personelBloc = personelBloc,
        _vehicleBloc = vehicleBloc,
        _checklistBloc = checklistBloc,
 
        _loadAllDeliveryTeam = loadAllDeliveryTeam,
        _assignDeliveryTeamToTrip = assignDeliveryTeamToTrip,
        _createDeliveryTeam = createDeliveryTeam,
        _updateDeliveryTeam = updateDeliveryTeam,
        _deleteDeliveryTeam = deleteDeliveryTeam,
        super(const DeliveryTeamInitial()) {

    on<LoadAllDeliveryTeamsEvent>(_onLoadAllDeliveryTeams);
    on<AssignDeliveryTeamToTripEvent>(_onAssignDeliveryTeamToTrip);
    on<CreateDeliveryTeamEvent>(_onCreateDeliveryTeam);
    on<UpdateDeliveryTeamEvent>(_onUpdateDeliveryTeam);
    on<DeleteDeliveryTeamEvent>(_onDeleteDeliveryTeam);
  }




  Future<void> _onLoadAllDeliveryTeams(
    LoadAllDeliveryTeamsEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint('🔄 Loading all delivery teams');

    final result = await _loadAllDeliveryTeam();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load all teams: ${failure.message}');
        emit(DeliveryTeamError(failure.message));
      },
      (deliveryTeams) {
        debugPrint('✅ Loaded ${deliveryTeams.length} delivery teams');
        emit(AllDeliveryTeamsLoaded(deliveryTeams));
      },
    );
  }

  Future<void> _onAssignDeliveryTeamToTrip(
    AssignDeliveryTeamToTripEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint('🔄 Assigning team ${event.deliveryTeamId} to trip ${event.tripId}');

    final result = await _assignDeliveryTeamToTrip(
      AssignDeliveryTeamParams(
        tripId: event.tripId,
        deliveryTeamId: event.deliveryTeamId,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Assignment failed: ${failure.message}');
        emit(DeliveryTeamError(failure.message));
      },
      (deliveryTeam) {
        debugPrint('✅ Team assigned successfully');
        emit(DeliveryTeamAssigned(
          deliveryTeamId: event.deliveryTeamId,
          tripId: event.tripId,
        ));
      },
    );
  }

  Future<void> _onCreateDeliveryTeam(
    CreateDeliveryTeamEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint('🔄 Creating new delivery team');

    final result = await _createDeliveryTeam(
      CreateDeliveryTeamParams(
        deliveryTeamId: event.deliveryTeamId,
        vehicle: event.vehicle,
        personels: event.personels,
        tripId: event.tripId,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Team creation failed: ${failure.message}');
        emit(DeliveryTeamError(failure.message));
      },
      (deliveryTeam) {
        debugPrint('✅ Team created successfully: ${deliveryTeam.id}');
        emit(DeliveryTeamCreated(deliveryTeam));
      },
    );
  }

  Future<void> _onUpdateDeliveryTeam(
    UpdateDeliveryTeamEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint('🔄 Updating delivery team: ${event.deliveryTeamId}');

    final result = await _updateDeliveryTeam(
      UpdateDeliveryTeamParams(
        deliveryTeamId: event.deliveryTeamId,
        vehicle: event.vehicle,
        personels: event.personels,
        tripId: event.tripId,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Team update failed: ${failure.message}');
        emit(DeliveryTeamError(failure.message));
      },
      (deliveryTeam) {
        debugPrint('✅ Team updated successfully: ${deliveryTeam.id}');
        emit(DeliveryTeamUpdated(deliveryTeam));
      },
    );
  }

  Future<void> _onDeleteDeliveryTeam(
    DeleteDeliveryTeamEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint('🔄 Deleting delivery team: ${event.deliveryTeamId}');

    final result = await _deleteDeliveryTeam(event.deliveryTeamId);

    result.fold(
      (failure) {
        debugPrint('❌ Team deletion failed: ${failure.message}');
        emit(DeliveryTeamError(failure.message));
      },
      (_) {
        debugPrint('✅ Team deleted successfully');
        emit(DeliveryTeamDeleted(event.deliveryTeamId));
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
