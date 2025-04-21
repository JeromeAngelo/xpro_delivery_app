import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';

abstract class TripUpdatesState extends Equatable {
  const TripUpdatesState();

  @override
  List<Object> get props => [];
}

class TripUpdatesInitial extends TripUpdatesState {}

class TripUpdatesLoading extends TripUpdatesState {}

class TripUpdatesLoaded extends TripUpdatesState {
  final List<TripUpdateEntity> updates;
  
  const TripUpdatesLoaded(this.updates);
  
  @override
  List<Object> get props => [updates];
}

class TripUpdateCreated extends TripUpdatesState {
  final String tripId;
  
  const TripUpdateCreated(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}

class TripUpdatesError extends TripUpdatesState {
  final String message;
  
  const TripUpdatesError(this.message);
  
  @override
  List<String> get props => [message];
}
