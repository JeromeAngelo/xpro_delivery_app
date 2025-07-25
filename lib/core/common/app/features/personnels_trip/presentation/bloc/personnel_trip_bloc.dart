import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/usecase/get_all_personnel_trips.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/usecase/get_personnel_trip_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/usecase/get_personnel_trips_by_personnel_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/usecase/get_personnel_trips_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/presentation/bloc/personnel_trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/presentation/bloc/personnel_trip_state.dart';

class PersonnelTripBloc extends Bloc<PersonnelTripEvent, PersonnelTripState> {
  PersonnelTripBloc({
    required GetAllPersonnelTrips getAllPersonnelTrips,
    required GetPersonnelTripById getPersonnelTripById,
    required GetPersonnelTripsByPersonnelId getPersonnelTripsByPersonnelId,
    required GetPersonnelTripsByTripId getPersonnelTripsByTripId,
  })  : _getAllPersonnelTrips = getAllPersonnelTrips,
        _getPersonnelTripById = getPersonnelTripById,
        _getPersonnelTripsByPersonnelId = getPersonnelTripsByPersonnelId,
        _getPersonnelTripsByTripId = getPersonnelTripsByTripId,
        super(const PersonnelTripInitial()) {
    on<GetAllPersonnelTripsEvent>(_onGetAllPersonnelTrips);
    on<GetPersonnelTripByIdEvent>(_onGetPersonnelTripById);
    on<GetPersonnelTripsByPersonnelIdEvent>(_onGetPersonnelTripsByPersonnelId);
    on<GetPersonnelTripsByTripIdEvent>(_onGetPersonnelTripsByTripId);
  }

  final GetAllPersonnelTrips _getAllPersonnelTrips;
  final GetPersonnelTripById _getPersonnelTripById;
  final GetPersonnelTripsByPersonnelId _getPersonnelTripsByPersonnelId;
  final GetPersonnelTripsByTripId _getPersonnelTripsByTripId;

  Future<void> _onGetAllPersonnelTrips(
    GetAllPersonnelTripsEvent event,
    Emitter<PersonnelTripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Getting all personnel trips');
    emit(const PersonnelTripLoading());

    final result = await _getAllPersonnelTrips();

    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get all personnel trips - ${failure.message}');
        emit(PersonnelTripError(failure.message));
      },
      (personnelTrips) {
        debugPrint('✅ BLOC: Successfully retrieved ${personnelTrips.length} personnel trips');
        emit(AllPersonnelTripsLoaded(personnelTrips));
      },
    );
  }

  Future<void> _onGetPersonnelTripById(
    GetPersonnelTripByIdEvent event,
    Emitter<PersonnelTripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Getting personnel trip by ID: ${event.id}');
    emit(const PersonnelTripLoading());

    final result = await _getPersonnelTripById(event.id);

    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get personnel trip by ID - ${failure.message}');
        emit(PersonnelTripError(failure.message));
      },
      (personnelTrip) {
        debugPrint('✅ BLOC: Successfully retrieved personnel trip: ${personnelTrip.id}');
        emit(PersonnelTripByIdLoaded(personnelTrip));
      },
    );
  }

  Future<void> _onGetPersonnelTripsByPersonnelId(
    GetPersonnelTripsByPersonnelIdEvent event,
    Emitter<PersonnelTripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Getting personnel trips by personnel ID: ${event.personnelId}');
    emit(const PersonnelTripLoading());

    final result = await _getPersonnelTripsByPersonnelId(event.personnelId);

    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get personnel trips by personnel ID - ${failure.message}');
        emit(PersonnelTripError(failure.message));
      },
      (personnelTrips) {
        debugPrint('✅ BLOC: Successfully retrieved ${personnelTrips.length} personnel trips for personnel: ${event.personnelId}');
        emit(PersonnelTripsByPersonnelIdLoaded(personnelTrips, event.personnelId));
      },
    );
  }

  Future<void> _onGetPersonnelTripsByTripId(
    GetPersonnelTripsByTripIdEvent event,
    Emitter<PersonnelTripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Getting personnel trips by trip ID: ${event.tripId}');
    emit(const PersonnelTripLoading());

    final result = await _getPersonnelTripsByTripId(event.tripId);

    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get personnel trips by trip ID - ${failure.message}');
        emit(PersonnelTripError(failure.message));
      },
      (personnelTrips) {
        debugPrint('✅ BLOC: Successfully retrieved ${personnelTrips.length} personnel trips for trip: ${event.tripId}');
        emit(PersonnelTripsByTripIdLoaded(personnelTrips, event.tripId));
      },
    );
  }
}
