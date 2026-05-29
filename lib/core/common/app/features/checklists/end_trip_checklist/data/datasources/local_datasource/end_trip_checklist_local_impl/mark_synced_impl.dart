import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkSyncedImpl on EndTripChecklistLocalBase {
  Future<void> markSynced(EndTripChecklistModel status) async {
    final updated = status.copyWith(
      syncStatus: SyncStatus.synced.name,
      retryCount: 0,
      lastSyncError: null,
    );
    endTripChecklistBox.put(updated);
    debugPrint('LOCAL ✅ Synced → ${status.objectName}');
  }
}
