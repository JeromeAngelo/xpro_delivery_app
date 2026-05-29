import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin SyncDeliveryDataByTripIdImpl on DeliveryDataRemoteBase {
  Future<List<DeliveryDataModel>> syncDeliveryDataByTripId(
    String tripId,
  ) async {
    try {
      debugPrint('🔄 Syncing delivery data for trip ID: $tripId');

      final result = await pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            expand:
                'customer,customer.invoices,customer.deliveryStatus,'
                'invoice,invoice.products,invoice.customer,'
                'invoices,invoices.products,invoices.customer,'
                'trip,trip.deliveryTeam,trip.personels,'
                'deliveryUpdates,deliveryUpdates.customer,'
                'invoiceItems,invoiceItems.invoice',
            filter: 'trip = "$tripId"',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${result.length} delivery data records for sync');

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(processDeliveryDataRecord(record));
      }

      debugPrint(
        '✅ Successfully synced ${deliveryDataList.length} delivery data records',
      );

      return deliveryDataList;
    } catch (e) {
      debugPrint('❌ Failed to sync delivery data by trip ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to sync delivery data by trip ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
