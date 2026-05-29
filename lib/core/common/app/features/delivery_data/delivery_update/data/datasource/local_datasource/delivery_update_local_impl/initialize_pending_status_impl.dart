import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin InitializePendingStatusImpl on DeliveryUpdateLocalBase {
  Future<void> initializePendingStatus(List<String> customerIds) async {
    try {
      debugPrint('🔄 LOCAL: Initializing pending status');

      for (final customerId in customerIds) {
        final customer =
            deliveryDataBox
                .query(DeliveryDataModel_.pocketbaseId.equals(customerId))
                .build()
                .findFirst();

        if (customer != null) {
          final pendingStatus = DeliveryUpdateModel(
            title: 'Pending',
            subtitle: 'Waiting for delivery',
            isAssigned: true,
            customer: customerId,
            created: DateTime.now(),
          );

          await autoSave(pendingStatus);
          customer.deliveryUpdates.add(pendingStatus);
          deliveryDataBox.put(customer);
        }
      }

      debugPrint('✅ LOCAL: Successfully initialized pending status');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to initialize pending status - $e');
      throw CacheException(message: e.toString());
    }
  }
}
