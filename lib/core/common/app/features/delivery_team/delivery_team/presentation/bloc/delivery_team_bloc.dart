import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/mixins/offline_first_mixin.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/usecase/assign_delivery_team_to_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/usecase/load_delivery_team.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/usecase/load_delivery_team_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/presentation/bloc/personel_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';

class DeliveryTeamBloc extends Bloc<DeliveryTeamEvent, DeliveryTeamState> with OfflineFirstMixin<DeliveryTeamEvent, DeliveryTeamState> {
  final TripBloc _tripBloc;
  final PersonelBloc _personelBloc;
  final VehicleBloc _vehicleBloc;
  final DeliveryVehicleBloc _deliveryVehicleBloc;
  final ChecklistBloc _checklistBloc;
  final LoadDeliveryTeam _loadDeliveryTeam;
  final LoadDeliveryTeamById _loadDeliveryTeamById;
  final AssignDeliveryTeamToTrip _assignDeliveryTeamToTrip;
  final ConnectivityProvider _connectivity;
  DeliveryTeamState? _cachedState;

  DeliveryTeamBloc({
    required TripBloc tripBloc,
    required PersonelBloc personelBloc,
    required VehicleBloc vehicleBloc,
    required ChecklistBloc checklistBloc,
    required DeliveryVehicleBloc deliveryVehicleBloc,
    required LoadDeliveryTeam loadDeliveryTeam,
    required LoadDeliveryTeamById loadDeliveryTeamById,
    required AssignDeliveryTeamToTrip assignDeliveryTeamToTrip,
    required ConnectivityProvider connectivity,
  }) : _tripBloc = tripBloc,
       _personelBloc = personelBloc,
       _vehicleBloc = vehicleBloc,
       _deliveryVehicleBloc = deliveryVehicleBloc,
       _checklistBloc = checklistBloc,
       _loadDeliveryTeam = loadDeliveryTeam,
       _loadDeliveryTeamById = loadDeliveryTeamById,
       _assignDeliveryTeamToTrip = assignDeliveryTeamToTrip,
       _connectivity = connectivity,
       super(const DeliveryTeamInitial()) {
    on<LoadDeliveryTeamEvent>(_onLoadDeliveryTeam);
    on<LoadLocalDeliveryTeamEvent>(_onLoadLocalDeliveryTeam);
    on<LoadDeliveryTeamByIdEvent>(_onLoadDeliveryTeamById);
    on<LoadLocalDeliveryTeamByIdEvent>(_onLoadLocalDeliveryTeamById);
    on<AssignDeliveryTeamToTripEvent>(_onAssignDeliveryTeamToTrip);
  }

  Future<void> _onLoadDeliveryTeam(
    LoadDeliveryTeamEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    debugPrint('🔍 OFFLINE-FIRST: Loading delivery team for trip: ${event.tripId}');
    emit(const DeliveryTeamLoading());

    await executeOfflineFirst(
      localOperation: () async {
        final result = await _loadDeliveryTeam.loadFromLocal(event.tripId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (deliveryTeam) {
            final newState = DeliveryTeamLoaded(
              deliveryTeam: deliveryTeam,
              tripState: _tripBloc.state,
              personelState: _personelBloc.state,
              vehicleState: _vehicleBloc.state,
              checklistState: _checklistBloc.state,
              deliveryVehicleState: _deliveryVehicleBloc.state,
            );
            _cachedState = newState;
            emit(newState);
          },
        );
      },
      remoteOperation: () async {
        final result = await _loadDeliveryTeam(event.tripId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (deliveryTeam) {
            final newState = DeliveryTeamLoaded(
              deliveryTeam: deliveryTeam,
              tripState: _tripBloc.state,
              personelState: _personelBloc.state,
              vehicleState: _vehicleBloc.state,
              checklistState: _checklistBloc.state,
              deliveryVehicleState: _deliveryVehicleBloc.state,
            );
            _cachedState = newState;
            emit(newState);
          },
        );
      },
      onLocalSuccess: (data) {
        debugPrint('✅ Delivery team loaded from local cache');
      },
      onRemoteSuccess: (data) {
        debugPrint('✅ Delivery team synced from remote');
      },
      onError: (error) => emit(DeliveryTeamError(error)),
      connectivity: _connectivity,
    );
  }

  /// Legacy method - use LoadDeliveryTeamEvent with offline-first pattern instead
  Future<void> _onLoadLocalDeliveryTeam(
    LoadLocalDeliveryTeamEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    debugPrint('📱 Loading local delivery team for trip: ${event.tripId}');
    emit(const DeliveryTeamLoading());

    final result = await _loadDeliveryTeam.loadFromLocal(event.tripId);
    result.fold(
      (failure) {
        debugPrint('⚠️ Local load failed, attempting remote fetch');
        add(LoadDeliveryTeamEvent(event.tripId));
      },
      (deliveryTeam) {
        debugPrint('✅ Local delivery team loaded: ${deliveryTeam.id}');
        final newState = DeliveryTeamLoaded(
        deliveryTeam: deliveryTeam,
        tripState: _tripBloc.state,
        personelState: _personelBloc.state,
        vehicleState: _vehicleBloc.state,
        checklistState: _checklistBloc.state,
        deliveryVehicleState: _deliveryVehicleBloc.state,
      );
        _cachedState = newState;
        emit(newState);

        // Refresh data in background
        add(LoadDeliveryTeamEvent(event.tripId));
      },
    );
  }

  Future<void> _onLoadDeliveryTeamById(
    LoadDeliveryTeamByIdEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    debugPrint('🔍 OFFLINE-FIRST: Loading delivery team by ID: ${event.teamId}');
    emit(const DeliveryTeamLoading());

    await executeOfflineFirst(
      localOperation: () async {
        final result = await _loadDeliveryTeamById.loadFromLocal(event.teamId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (deliveryTeam) {
            final newState = DeliveryTeamLoaded(
              deliveryTeam: deliveryTeam,
              tripState: _tripBloc.state,
              personelState: _personelBloc.state,
              vehicleState: _vehicleBloc.state,
              checklistState: _checklistBloc.state,
              deliveryVehicleState: _deliveryVehicleBloc.state,
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
          (deliveryTeam) {
            final newState = DeliveryTeamLoaded(
              deliveryTeam: deliveryTeam,
              tripState: _tripBloc.state,
              personelState: _personelBloc.state,
              vehicleState: _vehicleBloc.state,
              checklistState: _checklistBloc.state,
              deliveryVehicleState: _deliveryVehicleBloc.state,
            );
            _cachedState = newState;
            emit(newState);
          },
        );
      },
      onLocalSuccess: (data) {
        debugPrint('✅ Delivery team loaded from cache by ID');
      },
      onRemoteSuccess: (data) {
        debugPrint('✅ Delivery team synced from remote by ID');
      },
      onError: (error) => emit(DeliveryTeamError(error)),
      connectivity: _connectivity,
    );
  }

  /// Legacy method - use LoadDeliveryTeamByIdEvent with offline-first pattern instead
  Future<void> _onLoadLocalDeliveryTeamById(
    LoadLocalDeliveryTeamByIdEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    debugPrint('📱 Loading local delivery team by ID: ${event.teamId}');
    emit(const DeliveryTeamLoading());

    final result = await _loadDeliveryTeamById.loadFromLocal(event.teamId);
    result.fold(
      (failure) {
        debugPrint('⚠️ Local load by ID failed: ${failure.message}');
        add(LoadDeliveryTeamByIdEvent(event.teamId));
      },
      (deliveryTeam) {
        debugPrint('✅ Local team loaded by ID: ${deliveryTeam.id}');
        final newState = DeliveryTeamLoaded(
        deliveryTeam: deliveryTeam,
        tripState: _tripBloc.state,
        personelState: _personelBloc.state,
        vehicleState: _vehicleBloc.state,
        checklistState: _checklistBloc.state,
        deliveryVehicleState: _deliveryVehicleBloc.state,
      );
        _cachedState = newState;
        emit(newState);
        add(LoadDeliveryTeamByIdEvent(event.teamId));
      },
    );
  }

  Future<void> _onAssignDeliveryTeamToTrip(
    AssignDeliveryTeamToTripEvent event,
    Emitter<DeliveryTeamState> emit,
  ) async {
    emit(const DeliveryTeamLoading());
    debugPrint(
      '🔄 Assigning team ${event.deliveryTeamId} to trip ${event.tripId}',
    );

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
      (_) {
        debugPrint('✅ Team assigned successfully');
        emit(
          DeliveryTeamAssigned(
            deliveryTeamId: event.deliveryTeamId,
            tripId: event.tripId,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
