import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin SyncDeliveryStatusChoicesImpl on DeliveryUpdateRemoteBase {
  Future<List<DeliveryUpdateModel>> syncDeliveryStatusChoices(
    String customerId,
  ) async {
    try {
      debugPrint(
        '🔄 [SYNC] Starting delivery update sync for customer: $customerId',
      );

      // 1️⃣ Get the deliveryData record related to this customer
      final customerRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(customerId, expand: 'deliveryUpdates');

      // 2️⃣ Extract the deliveryUpdates list (history of statuses)
      final deliveryUpdates = customerRecord.expand['deliveryUpdates'] as List?;

      if (deliveryUpdates == null || deliveryUpdates.isEmpty) {
        debugPrint('⚠️ No delivery updates found for customer $customerId.');
        return [];
      }

      debugPrint(
        '📦 Found ${deliveryUpdates.length} delivery updates for customer $customerId.',
      );

      // 3️⃣ Convert each update record to your DeliveryUpdateModel
      final updates =
          deliveryUpdates.map((record) {
            final update = DeliveryUpdateModel.fromJson(record.toJson());
            debugPrint(
              '   • Synced Update: ${update.title} (${update.created})',
            );
            return update;
          }).toList();

      debugPrint(
        '✅ [SYNC COMPLETE] ${updates.length} updates synced for $customerId',
      );
      return updates;
    } catch (e) {
      debugPrint(
        '❌ [SYNC ERROR] Failed to sync delivery updates for $customerId: $e',
      );
      throw ServerException(
        message:
            'Failed to sync delivery updates for $customerId: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
