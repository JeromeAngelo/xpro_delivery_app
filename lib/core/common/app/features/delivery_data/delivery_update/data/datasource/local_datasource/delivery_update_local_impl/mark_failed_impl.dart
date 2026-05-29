import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkFailedImpl on DeliveryUpdateLocalBase {
  Future<void> markFailed(DeliveryUpdateModel status, String error) async {
    final retryCount = (status.retryCount) + 1;
    final updated = status.copyWith(
      syncStatus: SyncStatus.pending.name,
      retryCount: retryCount,
      lastSyncError: error,
      nextRetryAt: DateTime.now().add(Duration(seconds: 2 * retryCount * 2)),
    );
    deliveryUpdateBox.put(updated);
    debugPrint(
      'LOCAL ⚠️ Sync failed → ${status.title}, retryCount=$retryCount',
    );
  }
}
