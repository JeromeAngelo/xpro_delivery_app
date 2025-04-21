import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/data_source/local_datasource/update_timeline_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/data_source/remote_datasource/update_timeline_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/entity/update_timeline_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/repo/update_timeline_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class UpdateTimelineRepoImpl extends UpdateTimelineRepo {
  final UpdateTimelineDatasource _remoteDatasource;
  final UpdateTimelineLocalDatasource _localDatasource;

  const UpdateTimelineRepoImpl(this._remoteDatasource, this._localDatasource);

  @override
  ResultFuture<UpdateTimelineEntity> loadUpdateTimeline() async {
    try {
      final result = await _remoteDatasource.loadUpdateTimeline();
      await _localDatasource.setUpdateTimeline(result);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> setUpdateTimeline(UpdateTimelineEntity updateTimeline) async {
    try {
      await _remoteDatasource.setUpdateTimeline(updateTimeline as UpdateTimelineModel);
      await _localDatasource.setUpdateTimeline(updateTimeline);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
