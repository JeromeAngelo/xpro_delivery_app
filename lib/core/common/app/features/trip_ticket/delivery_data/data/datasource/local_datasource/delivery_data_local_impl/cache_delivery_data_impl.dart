import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheDeliveryDataImpl on DeliveryDataLocalBase {
  Future<void> cacheDeliveryData(List<DeliveryDataModel> deliveryData) async {
    try {
      debugPrint('💾 LOCAL: Starting delivery data caching process...');
      debugPrint(
        '📥 LOCAL: Received ${deliveryData.length} delivery data items to cache',
      );

      await cleanupDeliveryData();
      await autoSave(deliveryData);

      final cachedCount = deliveryDataBox.count();
      debugPrint(
        '✅ LOCAL: Cache verification: $cachedCount delivery data items stored',
      );

      cachedDeliveryData = deliveryData;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
