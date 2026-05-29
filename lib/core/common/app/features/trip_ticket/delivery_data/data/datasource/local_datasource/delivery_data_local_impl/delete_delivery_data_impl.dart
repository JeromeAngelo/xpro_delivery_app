import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin DeleteDeliveryDataImpl on DeliveryDataLocalBase {
  Future<bool> deleteDeliveryData(String id) async {
    try {
      debugPrint('📱 LOCAL: Deleting delivery data with ID: $id');

      final deliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build()
              .findFirst();

      if (deliveryData == null) {
        throw const CacheException(
          message: 'Delivery data not found in local storage',
        );
      }

      // Check if this delivery data is associated with a trip
      if (deliveryData.tripId != null && deliveryData.tripId!.isNotEmpty) {
        debugPrint(
          '⚠️ LOCAL: Cannot delete delivery data that is assigned to a trip',
        );
        throw const CacheException(
          message:
              'Cannot delete delivery data that is assigned to a trip. Please unassign it first.',
        );
      }

      deliveryDataBox.remove(deliveryData.objectBoxId);
      debugPrint('✅ LOCAL: Successfully deleted delivery data');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
