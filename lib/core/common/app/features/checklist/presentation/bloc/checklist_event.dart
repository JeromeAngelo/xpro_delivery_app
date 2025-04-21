import 'package:equatable/equatable.dart';
abstract class ChecklistEvent extends Equatable {
  const ChecklistEvent();
}

class ChecklistItemEvent extends ChecklistEvent {
  final String id;
  final String objectName;
  final bool isChecked;
  final String status;

  const ChecklistItemEvent({
    required this.id,
    required this.objectName,
    required this.isChecked,
    required this.status,
  });

  @override
  List<Object?> get props => [id, objectName, isChecked, status];
}


class LoadChecklistEvent extends ChecklistEvent {
  const LoadChecklistEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadChecklistByTripIdEvent extends ChecklistEvent {
  final String tripId;
  const LoadChecklistByTripIdEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class LoadLocalChecklistByTripIdEvent extends ChecklistEvent {
  final String tripId;
  const LoadLocalChecklistByTripIdEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class CheckItemEvent extends ChecklistEvent {
  const CheckItemEvent(this.id);
  final String id;  // Changed from ChecklistEntity to String
  
  @override
  List<Object?> get props => [id];
}

