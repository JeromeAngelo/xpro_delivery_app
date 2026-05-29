import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin GetDeliveryReceiptByDeliveryDataIdImpl on DeliveryReceiptLocalBase {
  Future<DeliveryReceiptModel> getDeliveryReceiptByDeliveryDataId(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '📱 LOCAL: Fetching delivery receipt for delivery data ID: $deliveryDataId',
      );

      final query =
          deliveryReceiptBox
              .query(
                DeliveryReceiptModel_.deliveryData.equals(
                  deliveryDataId as int,
                ),
              )
              .build();

      final deliveryReceipt = query.findFirst();
      query.close();

      if (deliveryReceipt != null) {
        debugPrint('✅ LOCAL: Found delivery receipt in local storage');
        return deliveryReceipt;
      }

      throw const CacheException(
        message: 'Delivery receipt not found in local storage',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
