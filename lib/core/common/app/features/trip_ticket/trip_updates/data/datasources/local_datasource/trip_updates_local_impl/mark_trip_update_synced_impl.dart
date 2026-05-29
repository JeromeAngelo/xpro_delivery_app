import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkTripUpdateSyncedImpl on TripUpdateLocalBase {
  Future<void> markTripUpdateSynced(
    TripUpdateModel update,
    String remoteId,
  ) async {
    final updated =
        update.copyWith(id: remoteId, hasPendingSync: false)
          ..syncStatus = SyncStatus.synced.name
          ..retryCount = 0
          ..lastSyncError = null
          ..updatedBy = null;

    tripUpdateBox.put(updated);

    debugPrint(
      'LOCAL ✅ TripUpdate synced → OBX=${update.objectBoxId}, PB=$remoteId',
    );
  }
}
