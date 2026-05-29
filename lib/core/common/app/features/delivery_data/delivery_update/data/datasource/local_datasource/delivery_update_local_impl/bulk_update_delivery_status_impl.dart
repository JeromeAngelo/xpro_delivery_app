import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin BulkUpdateDeliveryStatusImpl on DeliveryUpdateLocalBase {
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  ) async {
    try {
      debugPrint('💾 Bulk updating delivery status');
      debugPrint('   📦 Customers: $customerIds');
      debugPrint('   🏷️ New Status ID: $statusId');

      for (final customerId in customerIds) {
        try {
          final query =
              deliveryUpdateBox
                  .query(DeliveryUpdateModel_.customer.equals(customerId))
                  .build();

          final updates = query.find();
          query.close();

          for (var update in updates) {
            update.isAssigned = true;
            update.id = statusId;
            await autoSave(update);
          }

          debugPrint('✅ Local status updated for customer: $customerId');
        } catch (e) {
          debugPrint('⚠️ Failed to update local status for $customerId: $e');
        }
      }

      debugPrint(
        '🎉 Local bulk update completed for ${customerIds.length} customers',
      );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
