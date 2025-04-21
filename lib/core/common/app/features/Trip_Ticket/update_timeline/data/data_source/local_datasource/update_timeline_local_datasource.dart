import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';

abstract class UpdateTimelineLocalDatasource {
  Future<UpdateTimelineModel> loadUpdateTimeline();
  Future<void> setUpdateTimeline(UpdateTimelineModel updateTimeline);
}

class UpdateTimelineLocalDatasourceImpl implements UpdateTimelineLocalDatasource {
  final Box<UpdateTimelineModel> _updateTimelineBox;

  const UpdateTimelineLocalDatasourceImpl(this._updateTimelineBox);

  @override
  Future<UpdateTimelineModel> loadUpdateTimeline() async {
    final results = _updateTimelineBox.getAll();
    if (results.isNotEmpty) {
      return results.first;
    }
    return UpdateTimelineModel(
      id: '',
      collectionId: '',
      collectionName: '',
    );
  }

  @override
  Future<void> setUpdateTimeline(UpdateTimelineModel updateTimeline) async {
    _updateTimelineBox.put(updateTimeline);
  }
}
