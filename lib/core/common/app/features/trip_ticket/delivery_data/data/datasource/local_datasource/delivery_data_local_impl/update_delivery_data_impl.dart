import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin UpdateDeliveryDataImpl on DeliveryDataLocalBase {
  Future<void> updateDeliveryData(DeliveryDataModel deliveryData) async {
    try {
      debugPrint('📱 LOCAL: Updating delivery data: ${deliveryData.id}');

      // Ensure tripId is set if trip is assigned
      if (deliveryData.trip.target != null) {
        deliveryData.tripId = deliveryData.trip.target?.id;
      }

      deliveryDataBox.put(deliveryData);
      debugPrint('✅ LOCAL: Delivery data updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
