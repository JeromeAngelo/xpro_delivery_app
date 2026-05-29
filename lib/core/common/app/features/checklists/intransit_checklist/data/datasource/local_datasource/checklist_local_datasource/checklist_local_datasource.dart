import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';

import '../checklist_local_impl/checklist_local_base.dart';
import '../checklist_local_impl/get_checklist_impl.dart';
import '../checklist_local_impl/check_item_impl.dart';
import '../checklist_local_impl/load_checklist_by_trip_id_impl.dart';
import '../checklist_local_impl/cache_checklist_impl.dart';
import '../checklist_local_impl/watch_checklist_by_trip_id_impl.dart';

abstract class ChecklistLocalDatasource {
  Future<List<ChecklistModel>> getChecklist();
  Future<bool> checkItem(String id);
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId);
  Future<void> cacheChecklist(List<ChecklistModel> checklist);
  Stream<List<ChecklistModel>> watchChecklistByTripId(String tripId);
}

class ChecklistLocalDatasourceImpl extends ChecklistLocalBase
    with
        GetChecklistImpl,
        CheckItemImpl,
        LoadChecklistByTripIdImpl,
        CacheChecklistImpl,
        WatchChecklistByTripIdImpl
    implements ChecklistLocalDatasource {
  ChecklistLocalDatasourceImpl(super.objectBoxStore);
}
