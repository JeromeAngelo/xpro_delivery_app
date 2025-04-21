import 'package:bloc/bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/usecase/load_update_timeline.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/usecase/set_update_timeline.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/presentation/bloc/update_timeline_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/presentation/bloc/update_timeline_state.dart';

class UpdateTimelineBloc
    extends Bloc<UpdateTimelineEvent, UpdateTimelineState> {
  UpdateTimelineBloc(
      {required LoadUpdateTimeline loadUpdateTimeline,
      required SetUpdateTimeline setDeliveryUpdate})
      : _loadUpdateTimeline = loadUpdateTimeline,
        _setDeliveryUpdate = setDeliveryUpdate,
        super(UpdateTimelineInitial()) {
    on<LoadUpdateTimelineEvent>(_onLoadUpdateTimelineHandler);
    on<SetUpdateTimelineEvent>(_setDeliveryUpdateHandler);
  }

  final LoadUpdateTimeline _loadUpdateTimeline;
  final SetUpdateTimeline _setDeliveryUpdate;

  Future<void> _onLoadUpdateTimelineHandler(
      LoadUpdateTimelineEvent event, Emitter<UpdateTimelineState> emit) async {
    emit(UpdateTimelineLoading());
    final result = await _loadUpdateTimeline.call();
    result.fold(
      (failure) => emit(UpdateTimelineError(message: failure.message)),
      (updateTimeline) => emit(UpdateTimelineLoaded(updateTimeline)),
    );
  }

  Future<void> _setDeliveryUpdateHandler(
      SetUpdateTimelineEvent event, Emitter<UpdateTimelineState> emit) async {
    final result = await _setDeliveryUpdate(event.updateTimeline);
    result.fold(
      (failure) => emit(UpdateTimelineError(message: failure.message)),
      (_) => emit(const SetUpdateTimelineSuccess()),
    );
  }
}
