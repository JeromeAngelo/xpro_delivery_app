import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin DeleteDeliveryReceiptImpl on DeliveryReceiptLocalBase {
  Future<bool> deleteDeliveryReceipt(String id) async {
    try {
      debugPrint('📱 LOCAL: Deleting delivery receipt with ID: $id');

      final deliveryReceipt =
          deliveryReceiptBox
              .query(DeliveryReceiptModel_.pocketbaseId.equals(id))
              .build()
              .findFirst();

      if (deliveryReceipt == null) {
        throw const CacheException(
          message: 'Delivery receipt not found in local storage',
        );
      }

      deliveryReceiptBox.remove(deliveryReceipt.objectBoxId);
      debugPrint('✅ LOCAL: Successfully deleted delivery receipt');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
