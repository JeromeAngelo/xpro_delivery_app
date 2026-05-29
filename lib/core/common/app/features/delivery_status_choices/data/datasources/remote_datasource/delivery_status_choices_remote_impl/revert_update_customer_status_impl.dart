import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/remote_datasource/delivery_status_choices_remote_impl/delivery_status_choices_remote_base.dart';
import '../../../../../../../../errors/exceptions.dart';

mixin RevertUpdateCustomerStatusImpl on DeliveryStatusChoicesRemoteBase {
  Future<String> revertUpdateCustomerStatus(
    String deliveryDataId,
    DeliveryStatusChoicesModel status,
  ) async {
    try {
      debugPrint(
        '🔄 REVERT: Removing latest status for DeliveryData: $deliveryDataId',
      );

      // ---------------------------------------------------
      // 1️⃣ GET DELIVERY DATA WITH UPDATES
      // ---------------------------------------------------
      final deliveryRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId, expand: 'deliveryUpdates');

      if (deliveryRecord.expand['deliveryUpdates'] == null ||
          (deliveryRecord.expand['deliveryUpdates'] as List).isEmpty) {
        debugPrint('⚠️ No delivery updates found to revert');

        throw const ServerException(
          message: 'No delivery updates to revert',
          statusCode: '404',
        );
      }

      final updates = deliveryRecord.expand['deliveryUpdates'] as List;

      // ---------------------------------------------------
      // 2️⃣ GET LATEST UPDATE
      // ---------------------------------------------------
      final lastUpdate = updates.last;
      final lastUpdateId = lastUpdate.id;

      debugPrint('🗑️ Reverting last update: $lastUpdateId');

      // ---------------------------------------------------
      // 3️⃣ REMOVE RELATION FROM DELIVERYDATA
      // ---------------------------------------------------
      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'deliveryUpdates-': [lastUpdateId], // 🔥 remove relation
            },
          );

      debugPrint('✅ Removed relation from deliveryData');

      // ---------------------------------------------------
      // 4️⃣ DELETE DELIVERY UPDATE RECORD
      // ---------------------------------------------------
      await pocketBaseClient.collection('deliveryUpdate').delete(lastUpdateId);

      debugPrint('🗑️ Deleted deliveryUpdate record');

      // ---------------------------------------------------
      // 5️⃣ OPTIONAL: DELETE RELATED NOTIFICATION
      // ---------------------------------------------------
      try {
        final notifList = await pocketBaseClient
            .collection('notifications')
            .getFullList(filter: 'status = "$lastUpdateId"');

        for (final notif in notifList) {
          await pocketBaseClient.collection('notifications').delete(notif.id);

          debugPrint('🗑️ Deleted notification: ${notif.id}');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to delete notification: $e');
      }

      // ---------------------------------------------------
      // 6️⃣ RETURN REMOVED UPDATE ID
      // ---------------------------------------------------
      return lastUpdateId;
    } catch (e) {
      debugPrint('❌ REVERT FAILED: ${e.toString()}');

      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Failed to revert status: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }
}
