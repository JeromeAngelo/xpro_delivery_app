import 'package:equatable/equatable.dart';
abstract class EndTripChecklistEvent extends Equatable {
  const EndTripChecklistEvent();
}

class GenerateEndTripChecklistEvent extends EndTripChecklistEvent {
  final String tripId;
  const GenerateEndTripChecklistEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class CheckEndTripItemEvent extends EndTripChecklistEvent {
  final String id;
  const CheckEndTripItemEvent(this.id);
  
  @override
  List<Object?> get props => [id];
}

class LoadEndTripChecklistEvent extends EndTripChecklistEvent {
  final String tripId;
  const LoadEndTripChecklistEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class LoadLocalEndTripChecklistEvent extends EndTripChecklistEvent {
  final String tripId;
  const LoadLocalEndTripChecklistEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}
