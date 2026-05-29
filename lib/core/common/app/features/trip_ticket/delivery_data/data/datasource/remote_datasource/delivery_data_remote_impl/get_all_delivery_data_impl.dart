import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin GetAllDeliveryDataImpl on DeliveryDataRemoteBase {
  Future<List<DeliveryDataModel>> getAllDeliveryData() async {
    try {
      debugPrint('🔄 Fetching all delivery data');

      final result = await pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            filter: 'hasTrip = false',
            expand:
                'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${result.length} delivery data records');

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(processDeliveryDataRecord(record));
      }

      return deliveryDataList;
    } catch (e) {
      debugPrint('❌ Failed to fetch delivery data: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load delivery data: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
