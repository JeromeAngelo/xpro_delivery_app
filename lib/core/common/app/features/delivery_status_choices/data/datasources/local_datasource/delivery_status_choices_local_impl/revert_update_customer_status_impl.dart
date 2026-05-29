import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin RevertUpdateCustomerStatusImpl on DeliveryStatusChoicesLocalBase {
  Future<void> revertUpdateCustomerStatus(
    String deliveryDataPbId,
    DeliveryStatusChoicesModel statusChoice,
  ) async {
    try {
      debugPrint('🔄 START: revertUpdateCustomerStatus()');
      debugPrint('   📌 DeliveryData PB ID: $deliveryDataPbId');

      // ---------------------------------------------------
      // 1️⃣ FIND THE LATEST UPDATE DIRECTLY (skip ToMany issues)
      // ---------------------------------------------------
      // Query all deliveryUpdates for this deliveryData by PB ID
      final updatesQuery =
          deliveryUpdateBox
              .query(
                DeliveryUpdateModel_.deliveryDataPbId.equals(deliveryDataPbId),
              )
              .build();

      final updates = updatesQuery.find();
      updatesQuery.close();

      if (updates.isEmpty) {
        debugPrint('⚠️ No delivery updates found');
        return;
      }

      debugPrint('📊 Found ${updates.length} updates locally');

      // Find the latest update by time
      DeliveryUpdateModel? latestUpdate;
      DateTime? latestTime;

      for (final update in updates) {
        final updateTime =
            update.lastLocalUpdatedAt ??
            update.time ??
            update.created ??
            DateTime(0);
        if (latestTime == null || updateTime.isAfter(latestTime)) {
          latestTime = updateTime;
          latestUpdate = update;
        }
      }

      if (latestUpdate == null) {
        debugPrint('❌ No valid delivery update found');
        return;
      }

      final latestObxId = latestUpdate.objectBoxId;
      debugPrint(
        '🗑️ Reverting update → OBX=$latestObxId, '
        'title=${latestUpdate.title}, time=$latestTime',
      );

      // ---------------------------------------------------
      // 🔥 2️⃣ DELETE THE UPDATE ENTITY (ObjectBox handles relation cleanup)
      // ---------------------------------------------------
      try {
        deliveryUpdateBox.remove(latestObxId);
        debugPrint('🗑️ Deleted deliveryUpdate from box (OBX=$latestObxId)');
      } catch (e) {
        debugPrint('⚠️ Failed to delete update from box: $e');
      }

      debugPrint('✅ Revert completed successfully');
    } catch (e, st) {
      debugPrint('❌ ERROR in revertUpdateCustomerStatus(): $e');
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }
}
