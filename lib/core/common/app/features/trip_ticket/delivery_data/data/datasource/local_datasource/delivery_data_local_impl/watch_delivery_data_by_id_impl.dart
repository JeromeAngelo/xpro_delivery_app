import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin WatchDeliveryDataByIdImpl on DeliveryDataLocalBase {
  Stream<DeliveryDataModel?> watchDeliveryDataById(String deliveryId) {
    debugPrint('👀 LOCAL: Watching single delivery data by ID: $deliveryId');

    // Watch the box for changes in this delivery data
    final query =
        deliveryDataBox
            .query(DeliveryDataModel_.pocketbaseId.equals(deliveryId))
            .build();

    return query.stream().asyncMap((_) async {
      try {
        // Load the DeliveryData with all relations (customer, invoices, updates)
        final deliveryData = await getDeliveryDataById(deliveryId);

        if (deliveryData != null) {
          debugPrint(
            '📦 LOCAL: Stream emitted delivery data for ID: $deliveryId with '
            '${deliveryData.invoices.length} invoices and '
            '${deliveryData.deliveryUpdates.length} updates',
          );
        } else {
          debugPrint('⚠️ LOCAL: Delivery data not found for ID: $deliveryId');
        }

        return deliveryData;
      } catch (e, st) {
        debugPrint(
          '❌ LOCAL: Failed to watch delivery data ID=$deliveryId → $e\n$st',
        );
        return null;
      }
    });
  }
}
