import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/entity/update_timeline_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class UpdateTimelineRepo {
  const UpdateTimelineRepo();

  ResultFuture<void> setUpdateTimeline(UpdateTimelineEntity updateTimeline);

  ResultFuture<UpdateTimelineEntity> loadUpdateTimeline();
}
