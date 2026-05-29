import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import '../../../../../../../../enums/sync_status_enums.dart';

mixin MarkFailedImpl on DeliveryStatusChoicesLocalBase {
  Future<void> markFailed(
    DeliveryStatusChoicesModel status,
    String error,
  ) async {
    final retryCount = (status.retryCount) + 1;
    final updated = status.copyWith(
      syncStatus: SyncStatus.pending.name,
      retryCount: retryCount,
      lastSyncError: error,
      nextRetryAt: DateTime.now().add(
        Duration(seconds: 2 * retryCount * 2),
      ), // exponential backoff
    );
    deliveryStatusChoicesBox.put(updated);
    debugPrint(
      'LOCAL ⚠️ Sync failed → ${status.title}, retryCount=$retryCount',
    );
  }
}
