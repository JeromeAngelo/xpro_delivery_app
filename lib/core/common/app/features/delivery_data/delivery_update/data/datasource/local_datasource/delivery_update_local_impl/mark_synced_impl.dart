import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkSyncedImpl on DeliveryUpdateLocalBase {
  Future<void> markSynced(DeliveryUpdateModel status) async {
    final updated = status.copyWith(
      syncStatus: SyncStatus.synced.name,
      retryCount: 0,
      lastSyncError: null,
    );
    deliveryUpdateBox.put(updated);
    debugPrint('LOCAL ✅ Synced → ${status.title}');
  }
}
