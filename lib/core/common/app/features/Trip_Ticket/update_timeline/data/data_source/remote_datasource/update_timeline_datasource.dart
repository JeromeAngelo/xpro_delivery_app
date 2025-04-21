import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class UpdateTimelineDatasource {
  Future<UpdateTimelineModel> loadUpdateTimeline();
  Future<void> setUpdateTimeline(UpdateTimelineModel updateTimeline);
}

class UpdateTimelineDatasourceImpl implements UpdateTimelineDatasource {
  const UpdateTimelineDatasourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<UpdateTimelineModel> loadUpdateTimeline() async {
    try {
      final result =
          await _pocketBaseClient.collection('update_timeline').getFullList();
      final updateTimelineList = result
          .map((record) => UpdateTimelineModel.fromJson(record.toJson()))
          .toList();
      if (updateTimelineList.isNotEmpty) {
        return updateTimelineList.first;
      } else {
        throw const ServerException(
          message: 'No update timeline found',
          statusCode: '404',
        );
      }
    } catch (e) {
      throw ServerException(
        message: e.toString(),
        statusCode: '500',
      );
    }
  }
  @override
  Future<void> setUpdateTimeline(UpdateTimelineModel updateTimeline) async {
    try {
      await _pocketBaseClient
          .collection('update_timeline')
          .create(body: updateTimeline.toJson());
    } catch (e) {
      throw ServerException(
        message: e.toString(),
        statusCode: '500',
      );
    }
  }
}
