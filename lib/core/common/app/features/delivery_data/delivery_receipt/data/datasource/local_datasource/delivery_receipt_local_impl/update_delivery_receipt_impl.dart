import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin UpdateDeliveryReceiptImpl on DeliveryReceiptLocalBase {
  Future<void> updateDeliveryReceipt(
    DeliveryReceiptModel deliveryReceipt,
  ) async {
    try {
      debugPrint('📱 LOCAL: Updating delivery receipt: ${deliveryReceipt.id}');

      // Ensure delivery data ID is set if delivery data is assigned
      if (deliveryReceipt.deliveryData.target != null) {
        deliveryReceipt.deliveryData.target!.id =
            deliveryReceipt.deliveryData.target?.id;
      }

      // Ensure trip ID is set if trip is assigned
      if (deliveryReceipt.trip.target != null) {
        deliveryReceipt.trip.target!.id = deliveryReceipt.trip.target?.id;
      }

      deliveryReceiptBox.put(deliveryReceipt);
      debugPrint('✅ LOCAL: Delivery receipt updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
