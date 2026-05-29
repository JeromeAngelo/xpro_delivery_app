import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin GetDeliveryDataByTripIdImpl on DeliveryDataRemoteBase {
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId) async {
    try {
      debugPrint('🔄 Fetching delivery data for trip ID: $tripId');

      final result = await pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            expand:
                'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
            filter: 'trip = "$tripId"',
            sort: 'customer.name',
          );

      debugPrint(
        '✅ Retrieved ${result.length} delivery data records for trip ID: $tripId',
      );

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(processDeliveryDataRecord(record));
      }

      return deliveryDataList;
    } catch (e) {
      debugPrint('❌ Failed to fetch delivery data by trip ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load delivery data by trip ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
