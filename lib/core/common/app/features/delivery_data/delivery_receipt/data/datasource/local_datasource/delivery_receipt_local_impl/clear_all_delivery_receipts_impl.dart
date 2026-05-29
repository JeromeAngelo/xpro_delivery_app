import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin ClearAllDeliveryReceiptsImpl on DeliveryReceiptLocalBase {
  Future<void> clearAllDeliveryReceipts() async {
    try {
      debugPrint('🧹 LOCAL: Clearing all delivery receipts');
      deliveryReceiptBox.removeAll();
      cachedDeliveryReceipts = null;
      debugPrint('✅ LOCAL: Successfully cleared all delivery receipts');
    } catch (e) {
      debugPrint('❌ LOCAL: Clear operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
