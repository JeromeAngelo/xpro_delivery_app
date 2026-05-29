import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin GetDeliveryDataByIdImpl on DeliveryDataRemoteBase {
  Future<DeliveryDataModel> getDeliveryDataById(String id) async {
    try {
      debugPrint('🔄 Fetching delivery data with ID: $id');

      final record = await pocketBaseClient
          .collection('deliveryData')
          .getOne(
            id,
            expand:
                'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      debugPrint('✅ Retrieved delivery data with ID: $id');

      return processDeliveryDataRecord(record);
    } catch (e) {
      debugPrint('❌ Failed to fetch delivery data by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load delivery data by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
