import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetAllDeliveryReceiptsImpl on DeliveryReceiptLocalBase {
  Future<List<DeliveryReceiptModel>> getAllDeliveryReceipts() async {
    try {
      debugPrint('📱 LOCAL: Fetching all delivery receipts');

      final query = deliveryReceiptBox.query().build();
      final deliveryReceipts = query.find();
      query.close();

      debugPrint('📊 Storage Stats:');
      debugPrint(
        'Total stored delivery receipts: ${deliveryReceiptBox.count()}',
      );
      debugPrint('Found delivery receipts: ${deliveryReceipts.length}');

      cachedDeliveryReceipts = deliveryReceipts;
      return deliveryReceipts;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
