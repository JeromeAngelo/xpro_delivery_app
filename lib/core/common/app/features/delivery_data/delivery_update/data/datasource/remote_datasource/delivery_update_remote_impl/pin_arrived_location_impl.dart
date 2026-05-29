import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/services/location_services.dart';

mixin PinArrivedLocationImpl on DeliveryUpdateRemoteBase {
  Future<void> pinArrivedLocation(String deliveryId) async {
    try {
      debugPrint('📍 Pinning arrived location for delivery: $deliveryId');

      // Get current location using the location service
      final position = await LocationService.getCurrentLocation();

      debugPrint(
        '📍 Current location: ${position.latitude}, ${position.longitude}',
      );

      // Update delivery data with location
      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryId,
            body: {
              'pinLang': position.longitude,
              'pinLong': position.latitude,
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Successfully pinned location for delivery: $deliveryId');
      debugPrint(
        '📍 Pinned coordinates: lat=${position.latitude}, lng=${position.longitude}',
      );
    } catch (e) {
      debugPrint('❌ Failed to pin arrived location: $e');
      throw ServerException(
        message: 'Failed to pin arrived location: $e',
        statusCode: '500',
      );
    }
  }
}
