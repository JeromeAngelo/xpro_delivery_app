import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/domain/entity/end_checklist_entity.dart';

abstract class EndTripChecklistState extends Equatable {
  const EndTripChecklistState();

  @override
  List<Object> get props => [];
}

class EndTripChecklistInitial extends EndTripChecklistState {}

class EndTripChecklistLoading extends EndTripChecklistState {}

class EndTripChecklistLoaded extends EndTripChecklistState {
  final List<EndChecklistEntity> checklists;

  const EndTripChecklistLoaded(this.checklists);

  @override
  List<Object> get props => [checklists];
}

class EndTripChecklistError extends EndTripChecklistState {
  final String message;

  const EndTripChecklistError(this.message);

  @override
  List<Object> get props => [message];
}

class EndTripItemChecked extends EndTripChecklistState {}
