import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/delivery_receipt_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetDeliveryReceiptByTripIdImpl on DeliveryReceiptRemoteBase {
  Future<DeliveryReceiptModel> getDeliveryReceiptByTripId(String tripId) async {
    try {
      debugPrint('🔄 Fetching delivery receipt by trip ID: $tripId');

      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Using trip ID: $actualTripId');

      final records = await pocketBaseClient
          .collection('deliveryReceipt')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'trip,deliveryData',
          );

      if (records.isEmpty) {
        throw const ServerException(
          message: 'No delivery receipt found for this trip',
          statusCode: '404',
        );
      }

      final record = records.first;
      debugPrint('✅ Retrieved delivery receipt: ${record.id}');

      final mappedData = mapDeliveryReceiptData(record);
      return DeliveryReceiptModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error fetching delivery receipt by trip ID: $e');
      throw ServerException(
        message: 'Failed to load delivery receipt by trip ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
