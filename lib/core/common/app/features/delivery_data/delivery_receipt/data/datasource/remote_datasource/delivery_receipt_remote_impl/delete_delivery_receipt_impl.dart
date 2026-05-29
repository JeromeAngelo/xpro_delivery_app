import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/delivery_receipt_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin DeleteDeliveryReceiptImpl on DeliveryReceiptRemoteBase {
  Future<bool> deleteDeliveryReceipt(String id) async {
    try {
      debugPrint('🔄 Deleting delivery receipt: $id');

      await pocketBaseClient.collection('deliveryReceipt').delete(id);

      debugPrint('✅ Successfully deleted delivery receipt: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting delivery receipt: $e');
      throw ServerException(
        message: 'Failed to delete delivery receipt: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
