import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin DeleteDeliveryDataImpl on DeliveryDataRemoteBase {
  Future<bool> deleteDeliveryData(String id) async {
    try {
      debugPrint('🔄 Deleting delivery data with ID: $id');

      // First, get the delivery data to check its relationships
      final record = await pocketBaseClient
          .collection('deliveryData')
          .getOne(id);

      // Check if this delivery data is associated with a trip
      if (record.data['trip'] != null && record.data['trip'] != '') {
        debugPrint('⚠️ Cannot delete delivery data that is assigned to a trip');
        throw ServerException(
          message:
              'Cannot delete delivery data that is assigned to a trip. Please unassign it first.',
          statusCode: '400',
        );
      }

      // Delete the delivery data
      await pocketBaseClient.collection('deliveryData').delete(id);

      debugPrint('✅ Successfully deleted delivery data with ID: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete delivery data: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete delivery data: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }
}
