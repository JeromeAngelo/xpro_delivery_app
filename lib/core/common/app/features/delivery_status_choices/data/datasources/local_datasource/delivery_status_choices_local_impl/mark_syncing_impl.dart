import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import '../../../../../../../../enums/sync_status_enums.dart';

mixin MarkSyncingImpl on DeliveryStatusChoicesLocalBase {
  Future<void> markSyncing(DeliveryStatusChoicesModel status) async {
    final updated = status.copyWith(
      syncStatus: SyncStatus.syncing.name,
      lastSyncAttemptAt: DateTime.now(),
    );
    deliveryStatusChoicesBox.put(updated);
    debugPrint('LOCAL 🔄 Marked syncing → ${status.title}');
  }
}
