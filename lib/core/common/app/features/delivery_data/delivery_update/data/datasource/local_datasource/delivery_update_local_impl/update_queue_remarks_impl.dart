import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin UpdateQueueRemarksImpl on DeliveryUpdateLocalBase {
  Future<void> updateQueueRemarks(
    String statusId,
    String remarks,
    String image,
  ) async {
    try {
      debugPrint('💾 LOCAL: Updating queue remarks for status: $statusId');

      final query =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.id.equals(statusId))
              .build();
      final existingStatus = query.findFirst();
      query.close();

      if (existingStatus == null) {
        throw CacheException(
          message: 'Status with ID $statusId not found locally',
        );
      }

      existingStatus.remarks = remarks;
      existingStatus.time = DateTime.now();
      if (image.isNotEmpty) {
        existingStatus.image = image;
      }

      final customer =
          deliveryDataBox
              .query(
                DeliveryDataModel_.pocketbaseId.equals(
                  existingStatus.customer ?? '',
                ),
              )
              .build()
              .findFirst();

      if (customer != null) {
        final index = customer.deliveryUpdates.indexWhere(
          (u) => u.id == statusId,
        );
        if (index != -1) {
          customer.deliveryUpdates[index] = existingStatus;
          deliveryDataBox.put(customer);
        }
      }

      debugPrint('✅ LOCAL: Queue remarks updated successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to update queue remarks: $e');
      throw CacheException(message: e.toString());
    }
  }
}
