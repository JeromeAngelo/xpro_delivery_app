import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkTripUpdateFailedImpl on TripUpdateLocalBase {
  Future<void> markTripUpdateFailed(
    TripUpdateModel update,
    String error,
  ) async {
    final retryCount = update.retryCount + 1;

    update
      ..syncStatus = SyncStatus.failed.name
      ..retryCount = retryCount
      ..lastSyncError = error
      ..nextRetryAt = DateTime.now().add(Duration(seconds: 2 * retryCount * 2));

    tripUpdateBox.put(update);

    debugPrint(
      'LOCAL ⚠️ TripUpdate sync failed → OBX=${update.objectBoxId}, retry=$retryCount',
    );
  }
}
