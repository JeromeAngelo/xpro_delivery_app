import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/mixins/offline_first_mixin.dart';

import '../../domain/usecase/load_delivery_team.dart';
import '../../domain/usecase/load_delivery_team_by_id.dart';
import '../../domain/usecase/assign_delivery_team_to_trip.dart';
import '../../domain/usecase/sync_delivery_team_by_trip.dart';

import 'delivery_team_event.dart';
import 'delivery_team_state.dart';

class DeliveryTeamBloc extends Bloc<DeliveryTeamEvent, DeliveryTeamState>
    with OfflineFirstMixin<DeliveryTeamEvent, DeliveryTeamState> {
  
  final LoadDeliveryTeam _loadDeliveryTeam;
  final LoadDeliveryTeamById _loadDeliveryTeamById;
  final AssignDeliveryTeamToTrip _assignDeliveryTeamToTrip;
  final SyncDeliveryTeamByTrip _syncDeliveryTeam;
  final ConnectivityProvider _connectivity;

  DeliveryTeamState? _cachedState;

  DeliveryTeamBloc({
    required LoadDeliveryTeam loadDeliveryTeam,
    required LoadDeliveryTeamById loadDeliveryTeamById,
    required AssignDeliveryTeamToTrip assignDeliveryTeamToTrip,
    required SyncDeliveryTeamByTrip syncDeliveryTeam,
    required ConnectivityProvider connectivity,
  })  : _loadDeliveryTeam = loadDeliveryTeam,
        _loadDeliveryTeamById = loadDeliveryTeamById,
        _assignDeliveryTeamToTrip = assignDeliveryTeamToTrip,
        _syncDeliveryTeam = syncDeliveryTeam,
        _connectivity = connectivity,
        super(const DeliveryTeamInitial()) {
    on<LoadDeliveryTeamEvent>(_onLoadDeliveryTeam);
    on<LoadDeliveryTeamByIdEvent>(_onLoadDeliveryTeamById);
    on<AssignDeliveryTeamToTripEvent>(_onAssignDeliveryTeamToTrip);
    on<SyncDeliveryTeamEvent>(_onSyncDeliveryTeamByTrip);
  }

  Future<void> _onLoadDeliveryTeam(
  LoadDeliveryTeamEvent event,
  Emitter<DeliveryTeamState> emit,
) async {
  emit(const DeliveryTeamLoading());
  debugPrint('🌐 Loading delivery team from local for trip: ${event.tripId}');

  final result = await _loadDeliveryTeam(event.tripId);

  result.fold(
    (failure) {
      debugPrint('❌ Remote fetch failed: ${failure.message}');
      emit(DeliveryTeamError(failure.message));
    },
    (team) {
      debugPrint('✅ Delivery team loaded successfully for trip: ${event.tripId}');
      emit(DeliveryTeamLoaded(
        tripId: event.tripId,
        deliveryTeam: team,
      ));
    },
  );
}

  // ---------------------------------------------------------------------------
  // LOAD DELIVERY TEAM BY TEAM ID
  // ---------------------------------------------------------------------------
  Future<void> _onLoadDeliveryTeamById(
    LoadDeliveryTeamByIdEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint('🔍 Loading delivery team by ID: ${event.teamId}');

    await executeOfflineFirst(
      localOperation: () async {
        final result = await _loadDeliveryTeamById.loadFromLocal(event.teamId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (team) {
            final newState = DeliveryTeamLoaded(
              tripId: team.trip.target?.id ?? '',
              deliveryTeam: team,
            );
            _cachedState = newState;
            emit(newState);
          },
        );
      },
      remoteOperation: () async {
        final result = await _loadDeliveryTeamById(event.teamId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (team) {
            final newState = DeliveryTeamLoaded(
              tripId: team.trip.target?.id ?? '',
              deliveryTeam: team,
            );
            _cachedState = newState;
            emit(newState);
          },
        );
      },
      onError: (error) => emit(DeliveryTeamError(error)),
      connectivity: _connectivity, onLocalSuccess: (data) {  }, onRemoteSuccess: (data) {  },
    );
  }

  // ---------------------------------------------------------------------------
  // ASSIGN DELIVERY TEAM TO A TRIP
  // ---------------------------------------------------------------------------
  Future<void> _onAssignDeliveryTeamToTrip(
    AssignDeliveryTeamToTripEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint('🔄 Assigning delivery team…');

    final result = await _assignDeliveryTeamToTrip(
      AssignDeliveryTeamParams(
        tripId: event.tripId,
        deliveryTeamId: event.deliveryTeamId,
      ),
    );

    result.fold(
      (failure) => emit(DeliveryTeamError(failure.message)),
      (_) => emit(
        DeliveryTeamAssigned(
          tripId: event.tripId,
          deliveryTeamId: event.deliveryTeamId,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SYNC (REMOTE ONLY)
  // ---------------------------------------------------------------------------
  Future<void> _onSyncDeliveryTeamByTrip(
    SyncDeliveryTeamEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint('🔄 Syncing delivery team for trip: ${event.tripId}');

    if (!_connectivity.isOnline) {
      debugPrint('⚠ Offline — cannot sync.');
      return;
    }

    final result = await _syncDeliveryTeam(event.tripId);

    result.fold(
      (failure) => emit(DeliveryTeamError(failure.message)),
      (team) {
        final newState = DeliveryTeamLoaded(
          tripId: event.tripId,
          deliveryTeam: team,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
