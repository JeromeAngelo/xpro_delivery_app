import 'package:equatable/equatable.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/entity/personnel_trip_entity.dart';

abstract class PersonnelTripState extends Equatable {
  const PersonnelTripState();

  @override
  List<Object?> get props => [];
}

class PersonnelTripInitial extends PersonnelTripState {
  const PersonnelTripInitial();
}

class PersonnelTripLoading extends PersonnelTripState {
  const PersonnelTripLoading();
}

class PersonnelTripError extends PersonnelTripState {
  const PersonnelTripError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// States for getting all personnel trips
class AllPersonnelTripsLoaded extends PersonnelTripState {
  const AllPersonnelTripsLoaded(this.personnelTrips);

  final List<PersonnelTripEntity> personnelTrips;

  @override
  List<Object?> get props => [personnelTrips];
}

// States for getting personnel trip by ID
class PersonnelTripByIdLoaded extends PersonnelTripState {
  const PersonnelTripByIdLoaded(this.personnelTrip);

  final PersonnelTripEntity personnelTrip;

  @override
  List<Object?> get props => [personnelTrip];
}

// States for getting personnel trips by personnel ID
class PersonnelTripsByPersonnelIdLoaded extends PersonnelTripState {
  const PersonnelTripsByPersonnelIdLoaded(this.personnelTrips, this.personnelId);

  final List<PersonnelTripEntity> personnelTrips;
  final String personnelId;

  @override
  List<Object?> get props => [personnelTrips, personnelId];
}

// States for getting personnel trips by trip ID
class PersonnelTripsByTripIdLoaded extends PersonnelTripState {
  const PersonnelTripsByTripIdLoaded(this.personnelTrips, this.tripId);

  final List<PersonnelTripEntity> personnelTrips;
  final String tripId;

  @override
  List<Object?> get props => [personnelTrips, tripId];
}
