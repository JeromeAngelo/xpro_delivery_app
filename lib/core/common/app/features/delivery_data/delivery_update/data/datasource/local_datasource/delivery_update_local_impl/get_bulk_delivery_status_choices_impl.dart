import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin GetBulkDeliveryStatusChoicesImpl on DeliveryUpdateLocalBase {
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  ) async {
    final Map<String, List<DeliveryUpdateModel>> result = {};

    try {
      debugPrint('📦 Fetching bulk delivery status choices from local DB...');

      for (final customerId in customerIds) {
        try {
          final updates =
              deliveryUpdateBox
                  .query(DeliveryUpdateModel_.customer.equals(customerId))
                  .build()
                  .find();

          debugPrint('📊 Delivery Updates for Customer $customerId:');
          debugPrint('   📦 Total Updates: ${updates.length}');
          debugPrint('   📝 Status Timeline:');
          for (var update in updates) {
            debugPrint('      ${update.title}: ${update.created}');
          }

          result[customerId] = updates;
        } catch (e) {
          debugPrint('❌ Failed to fetch local statuses for $customerId: $e');
          result[customerId] = [];
        }
      }

      return result;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
