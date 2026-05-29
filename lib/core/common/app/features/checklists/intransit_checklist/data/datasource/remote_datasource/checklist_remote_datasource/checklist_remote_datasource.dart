import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';

import '../checklist_remote_impl/checklist_remote_base.dart';
import '../checklist_remote_impl/get_checklist_impl.dart';
import '../checklist_remote_impl/check_item_impl.dart';
import '../checklist_remote_impl/load_checklist_by_trip_id_impl.dart';

abstract class ChecklistDatasource {
  Future<List<ChecklistModel>> getChecklist();
  Future<bool> checkItem(String id);
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId);
}

class ChecklistDatasourceImpl extends ChecklistRemoteBase
    with GetChecklistImpl, CheckItemImpl, LoadChecklistByTripIdImpl
    implements ChecklistDatasource {
  ChecklistDatasourceImpl({required super.pocketBaseClient});
}
