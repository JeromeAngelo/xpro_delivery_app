import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin SaveDeliveryUpdateChoicesImpl on DeliveryUpdateLocalBase {
  Future<void> saveDeliveryUpdateChoices(
    String customerId,
    List<DeliveryUpdateModel> updates,
  ) async {
    try {
      debugPrint(
        '💾 Saving ${updates.length} delivery update HISTORY for: $customerId',
      );

      final oldQuery =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.customer.equals(customerId))
              .build();

      final oldUpdates = oldQuery.find();
      final historyRecords =
          oldUpdates
              .where(
                (u) =>
                    u.customer != null && !u.customer!.startsWith('choices_'),
              )
              .toList();

      for (var record in historyRecords) {
        deliveryUpdateBox.remove(record.objectBoxId);
      }
      debugPrint(
        '🧹 Removed ${historyRecords.length} old delivery history records',
      );
      oldQuery.close();

      for (final update in updates) {
        update.customer = customerId;
        update.isAssigned = true;

        update.created ??= DateTime.now();

        deliveryUpdateBox.put(update);
        debugPrint('✅ Saved history: ${update.title} (${update.id})');
      }

      debugPrint(
        '✅ Saved ${updates.length} delivery history records for $customerId',
      );
    } catch (e) {
      debugPrint('❌ Failed to save delivery history: $e');
      throw CacheException(message: e.toString());
    }
  }
}
