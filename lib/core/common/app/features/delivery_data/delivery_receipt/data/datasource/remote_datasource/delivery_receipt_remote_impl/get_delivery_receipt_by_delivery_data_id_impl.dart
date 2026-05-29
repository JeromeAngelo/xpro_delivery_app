import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/delivery_receipt_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetDeliveryReceiptByDeliveryDataIdImpl on DeliveryReceiptRemoteBase {
  Future<DeliveryReceiptModel> getDeliveryReceiptByDeliveryDataId(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 Fetching delivery receipt by delivery data ID: $deliveryDataId',
      );

      // Extract delivery data ID if we received a JSON object
      String actualDeliveryDataId;
      if (deliveryDataId.startsWith('{')) {
        final deliveryData = jsonDecode(deliveryDataId);
        actualDeliveryDataId = deliveryData['id'];
      } else {
        actualDeliveryDataId = deliveryDataId;
      }

      debugPrint('🎯 Using delivery data ID: $actualDeliveryDataId');

      final records = await pocketBaseClient
          .collection('deliveryReceipt')
          .getFullList(
            filter: 'deliveryData = "$actualDeliveryDataId"',
            expand: 'trip,deliveryData',
          );

      if (records.isEmpty) {
        throw const ServerException(
          message: 'No delivery receipt found for this delivery data',
          statusCode: '404',
        );
      }

      final record = records.first;
      debugPrint('✅ Retrieved delivery receipt: ${record.id}');

      final mappedData = mapDeliveryReceiptData(record);
      return DeliveryReceiptModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error fetching delivery receipt by delivery data ID: $e');
      throw ServerException(
        message:
            'Failed to load delivery receipt by delivery data ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
