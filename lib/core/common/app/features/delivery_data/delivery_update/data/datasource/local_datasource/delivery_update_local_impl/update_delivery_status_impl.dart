import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import '../../../../../../../../../enums/sync_status_enums.dart';

mixin UpdateDeliveryStatusImpl on DeliveryUpdateLocalBase {
  Future<void> updateDeliveryStatus(
    String deliveryDataPbId,
    DeliveryStatusChoicesModel statusChoice,
  ) async {
    try {
      debugPrint('🔵 START: updateDeliveryStatus()');
      debugPrint('   📌 DeliveryData PB ID: $deliveryDataPbId');
      debugPrint('   🏷️ Status: ${statusChoice.title} (${statusChoice.id})');

      if (statusChoice.id == null || statusChoice.id!.isEmpty) {
        debugPrint('❌ StatusChoice PB ID is NULL or EMPTY');
        return;
      }

      final deliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataPbId))
              .build()
              .findFirst();

      if (deliveryData == null) {
        debugPrint('❌ DeliveryData not found locally');
        return;
      }

      debugPrint(
        '✅ DeliveryData resolved → OBX ID: ${deliveryData.objectBoxId}',
      );

      final alreadyExists = deliveryData.deliveryUpdates.any(
        (u) => u.title?.toLowerCase() == statusChoice.title?.toLowerCase(),
      );

      if (alreadyExists) {
        debugPrint('⚠️ Duplicate status ignored → ${statusChoice.title}');
        return;
      }

      final adjustedTime = DateTime.now().add(const Duration(seconds: 45));

      final deliveryUpdate = DeliveryUpdateModel(

        title: statusChoice.title,
        subtitle: statusChoice.subtitle,
        time: adjustedTime,
        created: DateTime.now(),
        updated: DateTime.now(),
        isAssigned: true,
        deliveryDataPbId: deliveryDataPbId,
        statusChoicePbId: statusChoice.id,
        syncStatus: SyncStatus.pending.name,
        retryCount: 0,
      );

      deliveryUpdate.deliveryData.target = deliveryData;
      deliveryData.deliveryUpdates.add(deliveryUpdate);

      deliveryUpdateBox.put(deliveryUpdate);
      deliveryDataBox.put(deliveryData);

      debugPrint('✅ DeliveryUpdate saved locally (PENDING SYNC)');
      debugPrint('   • Status: ${deliveryUpdate.title}');
      debugPrint('   • deliveryDataPbId: ${deliveryUpdate.deliveryDataPbId}');
      debugPrint('   • statusChoicePbId: ${deliveryUpdate.statusChoicePbId}');
      debugPrint('   • Total updates: ${deliveryData.deliveryUpdates.length}');
    } catch (e, st) {
      debugPrint('❌ ERROR in updateDeliveryStatus(): $e');
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }
}
