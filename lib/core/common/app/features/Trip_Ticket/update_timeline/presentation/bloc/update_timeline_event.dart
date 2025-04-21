import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/entity/update_timeline_entity.dart';

abstract class UpdateTimelineEvent extends Equatable {
  const UpdateTimelineEvent();
}

class LoadUpdateTimelineEvent extends UpdateTimelineEvent {
  @override
  List<Object> get props => [];
}

class SetUpdateTimelineEvent extends UpdateTimelineEvent {
  final UpdateTimelineEntity updateTimeline;
  const SetUpdateTimelineEvent({required this.updateTimeline});
  @override
  List<Object> get props => [updateTimeline];
}
