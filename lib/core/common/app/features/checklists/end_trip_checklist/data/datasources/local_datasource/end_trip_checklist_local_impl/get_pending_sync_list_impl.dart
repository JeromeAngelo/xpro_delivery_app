import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import '../../../../../../../../../enums/sync_status_enums.dart';

mixin GetPendingSyncListImpl on EndTripChecklistLocalBase {
  Future<List<EndTripChecklistModel>> getPendingSyncList() async {
    final all = endTripChecklistBox.getAll();
    return all
        .where(
          (s) =>
              s.syncStatus == SyncStatus.pending.name ||
              s.syncStatus == SyncStatus.failed.name,
        )
        .toList();
  }
}
