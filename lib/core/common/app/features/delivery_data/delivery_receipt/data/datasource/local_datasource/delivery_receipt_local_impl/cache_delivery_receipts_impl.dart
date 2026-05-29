import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheDeliveryReceiptsImpl on DeliveryReceiptLocalBase {
  Future<void> cacheDeliveryReceipts(
    List<DeliveryReceiptModel> deliveryReceipts,
  ) async {
    try {
      debugPrint('💾 LOCAL: Starting delivery receipt caching process...');
      debugPrint(
        '📥 LOCAL: Received ${deliveryReceipts.length} delivery receipts to cache',
      );

      await cleanupDeliveryReceipts();
      await autoSave(deliveryReceipts);

      final cachedCount = deliveryReceiptBox.count();
      debugPrint(
        '✅ LOCAL: Cache verification: $cachedCount delivery receipts stored',
      );

      cachedDeliveryReceipts = deliveryReceipts;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
