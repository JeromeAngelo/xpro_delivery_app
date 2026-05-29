import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin UpdateDeliveryLocationImpl on DeliveryDataRemoteBase {
  Future<DeliveryDataModel> updateDeliveryLocation(
    String id,
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('🔄 Updating delivery location for ID: $id');
      debugPrint('📍 Coordinates: Lat: $latitude, Long: $longitude');

      await pocketBaseClient
          .collection('deliveryData')
          .update(id, body: {'pinLang': latitude, 'pinLong': longitude});

      debugPrint('✅ Successfully updated delivery location for ID: $id');

      // Get the full record with expanded relationships
      final fullRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(
            id,
            expand:
                'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      return processDeliveryDataRecord(fullRecord);
    } catch (e) {
      debugPrint('❌ Failed to update delivery location: ${e.toString()}');
      throw ServerException(
        message: 'Failed to update delivery location: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
