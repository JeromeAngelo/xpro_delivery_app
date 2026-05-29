import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CalculateDeliveryTimeByDeliveryIdImpl on DeliveryDataLocalBase {
  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId) async {
    try {
      debugPrint(
        '📱 LOCAL: Calculating delivery time for delivery data: $deliveryId',
      );

      final deliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryId))
              .build()
              .findFirst();

      if (deliveryData == null) {
        throw const CacheException(
          message: 'Delivery data not found in local storage',
        );
      }

      final updates = deliveryData.deliveryUpdates.toList();
      if (updates.isEmpty) {
        debugPrint(
          '⚠️ LOCAL: No delivery updates found for delivery data: $deliveryId',
        );
        return 0;
      }

      // Sort updates by time
      updates.sort((a, b) => a.time!.compareTo(b.time!));

      // Find the "arrived" status
      final arrivedIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'arrived',
      );

      if (arrivedIndex == -1) {
        debugPrint(
          '⚠️ LOCAL: No "arrived" status found for delivery data: $deliveryId',
        );
        return 0;
      }

      // Check for undelivered status
      final undeliveredIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as undelivered',
      );

      // Get end delivery status
      final endDeliveryIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'end delivery',
      );

      // Get mark as received status
      final receivedIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as received',
      );

      // Determine relevant updates based on delivery scenario
      List<DeliveryUpdateModel> relevantUpdates;
      if (undeliveredIndex != -1) {
        // Undelivered scenario - calculate until mark as undelivered
        relevantUpdates = updates.sublist(arrivedIndex, undeliveredIndex + 1);
        debugPrint('📊 LOCAL: Calculating time for undelivered scenario');
      } else if (receivedIndex != -1) {
        // Received scenario - calculate until mark as received
        relevantUpdates = updates.sublist(arrivedIndex, receivedIndex + 1);
        debugPrint('📊 LOCAL: Calculating time for received scenario');
      } else if (endDeliveryIndex != -1) {
        // Normal delivery - include end delivery
        relevantUpdates = updates.sublist(arrivedIndex, endDeliveryIndex + 1);
        debugPrint('📊 LOCAL: Calculating time for normal delivery scenario');
      } else {
        // Fallback to all updates from arrived to the end
        relevantUpdates = updates.sublist(arrivedIndex);
        debugPrint('📊 LOCAL: Calculating time for ongoing delivery scenario');
      }

      double totalSeconds = 0;
      for (int i = 0; i < relevantUpdates.length - 1; i++) {
        final currentTime = relevantUpdates[i].time!;
        final nextTime = relevantUpdates[i + 1].time!;
        final diffInSeconds = nextTime.difference(currentTime).inSeconds;
        totalSeconds += diffInSeconds;

        debugPrint(
          'LOCAL: Status: ${relevantUpdates[i].title} -> ${relevantUpdates[i + 1].title}',
        );
        debugPrint(
          'LOCAL: Time: ${formatTime(currentTime)} -> ${formatTime(nextTime)}',
        );
        debugPrint(
          'LOCAL: Difference: ${diffInSeconds ~/ 60} minutes ${diffInSeconds % 60} seconds\n',
        );
      }

      final totalMinutes = (totalSeconds / 60).round();

      debugPrint(
        '✅ LOCAL: Total delivery time calculated: $totalMinutes minutes ($totalSeconds seconds)',
      );

      // Cache the calculated time in the delivery data model
      deliveryData.totalDeliveryTime =
          '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
      deliveryDataBox.put(deliveryData);

      return totalMinutes;
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to calculate delivery time: $e');
      throw CacheException(message: e.toString());
    }
  }
}
