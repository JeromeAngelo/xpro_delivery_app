import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetAllDeliveryDataImpl on DeliveryDataLocalBase {
  Future<List<DeliveryDataModel>> getAllDeliveryData() async {
    try {
      debugPrint('📱 LOCAL: Fetching all delivery data');

      final deliveryData = deliveryDataBox.getAll();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored delivery data: ${deliveryDataBox.count()}');
      debugPrint('Found unassigned delivery data: ${deliveryData.length}');

      cachedDeliveryData = deliveryData;
      return deliveryData;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
