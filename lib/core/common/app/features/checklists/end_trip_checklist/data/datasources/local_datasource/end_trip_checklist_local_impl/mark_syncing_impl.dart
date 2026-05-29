import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkSyncingImpl on EndTripChecklistLocalBase {
  Future<void> markSyncing(EndTripChecklistModel status) async {
    final updated = status.copyWith(
      syncStatus: SyncStatus.syncing.name,
      lastSyncAttemptAt: DateTime.now(),
    );
    endTripChecklistBox.put(updated);
    debugPrint('LOCAL 🔄 Marked syncing → ${status.objectName}');
  }
}
