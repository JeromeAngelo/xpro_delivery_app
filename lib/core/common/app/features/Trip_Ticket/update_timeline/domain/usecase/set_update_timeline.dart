import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/entity/update_timeline_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/repo/update_timeline_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class SetUpdateTimeline extends UsecaseWithParams<void, UpdateTimelineEntity> {

  const SetUpdateTimeline(this._repo);
  final UpdateTimelineRepo _repo;

  @override
  ResultFuture<void> call(UpdateTimelineEntity params) => _repo.setUpdateTimeline(params);
}