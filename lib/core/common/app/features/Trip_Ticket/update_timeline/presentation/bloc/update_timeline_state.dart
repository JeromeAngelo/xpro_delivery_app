import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/entity/update_timeline_entity.dart';

abstract class UpdateTimelineState extends Equatable {
  const UpdateTimelineState();
}

class UpdateTimelineInitial extends UpdateTimelineState {
  @override
  List<Object> get props => [];
}

class UpdateTimelineLoading extends UpdateTimelineState {
  @override
  List<Object> get props => [];
}

class UpdateTimelineLoaded extends UpdateTimelineState {
  final UpdateTimelineEntity updateTimelineEntity;
  const UpdateTimelineLoaded(this.updateTimelineEntity);
  @override
  List<Object> get props => [updateTimelineEntity];
}

class UpdateTimelineError extends UpdateTimelineState {
  final String message;
  const UpdateTimelineError({required this.message});
  @override
  List<Object> get props => [message];
}

class SetUpdateTimelineSuccess extends UpdateTimelineState {
  const SetUpdateTimelineSuccess();
  @override
  List<Object> get props => [];
}