import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';

import '../end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import '../end_trip_checklist_local_impl/generate_end_trip_checklist_impl.dart';
import '../end_trip_checklist_local_impl/check_end_trip_checklist_item_impl.dart';
import '../end_trip_checklist_local_impl/load_end_trip_checklist_impl.dart';
import '../end_trip_checklist_local_impl/cache_checklists_impl.dart';
import '../end_trip_checklist_local_impl/mark_syncing_impl.dart';
import '../end_trip_checklist_local_impl/mark_synced_impl.dart';
import '../end_trip_checklist_local_impl/mark_failed_impl.dart';
import '../end_trip_checklist_local_impl/get_pending_sync_list_impl.dart';

abstract class EndTripChecklistLocalDataSource {
  Future<List<EndTripChecklistModel>> generateEndTripChecklist(String tripId);
  Future<bool> checkEndTripChecklistItem(String id);
  Future<List<EndTripChecklistModel>> loadEndTripChecklist(String tripId);
  Future<void> cacheChecklists(List<EndTripChecklistModel> checklists);

  /// 🆕 Background sync helper methods
  Future<void> markSyncing(EndTripChecklistModel status);
  Future<void> markSynced(EndTripChecklistModel status);
  Future<void> markFailed(EndTripChecklistModel status, String error);
  Future<List<EndTripChecklistModel>> getPendingSyncList();
}

class EndTripChecklistLocalDataSourceImpl extends EndTripChecklistLocalBase
    with
        GenerateEndTripChecklistImpl,
        CheckEndTripChecklistItemImpl,
        LoadEndTripChecklistImpl,
        CacheChecklistsImpl,
        MarkSyncingImpl,
        MarkSyncedImpl,
        MarkFailedImpl,
        GetPendingSyncListImpl
    implements EndTripChecklistLocalDataSource {
  EndTripChecklistLocalDataSourceImpl(super.objectBoxStore);
}
