import 'package:equatable/equatable.dart';

abstract class PersonnelTripEvent extends Equatable {
  const PersonnelTripEvent();

  @override
  List<Object?> get props => [];
}

class GetAllPersonnelTripsEvent extends PersonnelTripEvent {
  const GetAllPersonnelTripsEvent();
}

class GetPersonnelTripByIdEvent extends PersonnelTripEvent {
  const GetPersonnelTripByIdEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class GetPersonnelTripsByPersonnelIdEvent extends PersonnelTripEvent {
  const GetPersonnelTripsByPersonnelIdEvent(this.personnelId);

  final String personnelId;

  @override
  List<Object?> get props => [personnelId];
}

class GetPersonnelTripsByTripIdEvent extends PersonnelTripEvent {
  const GetPersonnelTripsByTripIdEvent(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}
