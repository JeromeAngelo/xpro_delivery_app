import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/create_trip_updates.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/get_trip_updates.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_state.dart';

class TripUpdatesBloc extends Bloc<TripUpdatesEvent, TripUpdatesState> {
  final GetTripUpdates _getTripUpdates;
  final CreateTripUpdate _createTripUpdate;
  TripUpdatesState? _cachedState;

  TripUpdatesBloc({
    required GetTripUpdates getTripUpdates,
    required CreateTripUpdate createTripUpdate,
  })  : _getTripUpdates = getTripUpdates,
        _createTripUpdate = createTripUpdate,
        super(TripUpdatesInitial()) {
    on<GetTripUpdatesEvent>(_onGetTripUpdates);
    on<LoadLocalTripUpdatesEvent>(_onLoadLocalTripUpdates);
    on<CreateTripUpdateEvent>(_onCreateTripUpdate);
  }

  Future<void> _onGetTripUpdates(
    GetTripUpdatesEvent event,
    Emitter<TripUpdatesState> emit,
  ) async {
    debugPrint('🔄 Getting trip updates for trip: ${event.tripId}');

    if (_cachedState != null) {
      emit(_cachedState!);
    } else {
      emit(TripUpdatesLoading());
    }

    final result = await _getTripUpdates(event.tripId);
    result.fold(
      (failure) => emit(TripUpdatesError(failure.message)),
      (updates) {
        final newState = TripUpdatesLoaded(updates);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onLoadLocalTripUpdates(
    LoadLocalTripUpdatesEvent event,
    Emitter<TripUpdatesState> emit,
  ) async {
    debugPrint('📱 Loading local trip updates for trip: ${event.tripId}');
    emit(TripUpdatesLoading());

    final result = await _getTripUpdates.loadFromLocal(event.tripId);
    result.fold(
      (failure) {
        emit(TripUpdatesError(failure.message));
        // Immediately try remote fetch if local fails
        add(LoadLocalTripUpdatesEvent(event.tripId));
      },
      (updates) {
        final newState = TripUpdatesLoaded(updates);
        _cachedState = newState;
        emit(newState);
        // Refresh with remote data in background
        add(GetTripUpdatesEvent(event.tripId));
      },
    );
  }

  Future<void> _onCreateTripUpdate(
    CreateTripUpdateEvent event,
    Emitter<TripUpdatesState> emit,
  ) async {
    debugPrint('🔄 Creating trip update');
    emit(TripUpdatesLoading());

    final result = await _createTripUpdate(
      CreateTripUpdateParams(
        tripId: event.tripId,
        description: event.description,
        image: event.image,
        latitude: event.latitude,
        longitude: event.longitude,
        status: event.status,
      ),
    );

    result.fold(
      (failure) => emit(TripUpdatesError(failure.message)),
      (_) {
        emit(TripUpdateCreated(event.tripId));
        // Immediately refresh local data
        add(LoadLocalTripUpdatesEvent(event.tripId));
        // Then update with remote data
        add(GetTripUpdatesEvent(event.tripId));
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
