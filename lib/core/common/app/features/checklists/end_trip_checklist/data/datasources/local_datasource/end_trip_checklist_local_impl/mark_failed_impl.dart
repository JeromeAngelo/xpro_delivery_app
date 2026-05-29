import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkFailedImpl on EndTripChecklistLocalBase {
  Future<void> markFailed(EndTripChecklistModel status, String error) async {
    final retryCount = (status.retryCount) + 1;
    final updated = status.copyWith(
      syncStatus: SyncStatus.pending.name,
      retryCount: retryCount,
      lastSyncError: error,
      nextRetryAt: DateTime.now().add(
        Duration(seconds: 2 * retryCount * 2),
      ), // exponential backoff
    );
    endTripChecklistBox.put(updated);
    debugPrint(
      'LOCAL ⚠️ Sync failed → ${status.objectName}, retryCount=$retryCount',
    );
  }
}
