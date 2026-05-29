import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin CreateDeliveryStatusImpl on DeliveryUpdateLocalBase {
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  }) async {
    try {
      debugPrint(
        '💾 LOCAL: Creating delivery status for customer: $customerId',
      );

      final newStatus = DeliveryUpdateModel(
        title: title,
        subtitle: subtitle,
        time: time,
        isAssigned: true,
        customer: customerId,
        image: image,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      await autoSave(newStatus);

      final customer =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(customerId))
              .build()
              .findFirst();

      if (customer != null) {
        customer.deliveryUpdates.add(newStatus);
        deliveryDataBox.put(customer);
      }

      debugPrint('✅ LOCAL: Successfully created delivery status');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to create delivery status - $e');
      throw CacheException(message: e.toString());
    }
  }
}
