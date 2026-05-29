import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';

import '../end_trip_checklist_remote_impl/end_trip_checklist_remote_base.dart';
import '../end_trip_checklist_remote_impl/generate_end_trip_checklist_impl.dart';
import '../end_trip_checklist_remote_impl/check_end_trip_checklist_item_impl.dart';
import '../end_trip_checklist_remote_impl/load_end_trip_checklist_impl.dart';

abstract class EndTripChecklistRemoteDataSource {
  Future<List<EndTripChecklistModel>> generateEndTripChecklist(String tripId);
  Future<bool> checkEndTripChecklistItem(String id);
  Future<List<EndTripChecklistModel>> loadEndTripChecklist(String tripId);
}

class EndTripChecklistRemoteDataSourceImpl extends EndTripChecklistRemoteBase
    with
        GenerateEndTripChecklistImpl,
        CheckEndTripChecklistItemImpl,
        LoadEndTripChecklistImpl
    implements EndTripChecklistRemoteDataSource {
  const EndTripChecklistRemoteDataSourceImpl({required super.pocketBaseClient});
}
