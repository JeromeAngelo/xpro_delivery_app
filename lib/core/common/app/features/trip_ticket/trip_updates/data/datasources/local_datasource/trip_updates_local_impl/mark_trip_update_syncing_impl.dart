import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkTripUpdateSyncingImpl on TripUpdateLocalBase {
  Future<void> markTripUpdateSyncing(TripUpdateModel update) async {
    final updated =
        update.copyWith(hasPendingSync: false)
          ..syncStatus = SyncStatus.syncing.name
          ..lastSyncAttemptAt = DateTime.now();

    tripUpdateBox.put(updated);

    debugPrint(
      'LOCAL 🔄 TripUpdate marked syncing → OBX=${update.objectBoxId}',
    );
  }
}
