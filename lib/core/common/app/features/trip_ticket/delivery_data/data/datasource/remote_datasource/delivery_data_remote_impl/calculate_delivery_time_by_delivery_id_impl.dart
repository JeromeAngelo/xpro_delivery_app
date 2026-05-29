import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin CalculateDeliveryTimeByDeliveryIdImpl on DeliveryDataRemoteBase {
  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId) async {
    try {
      debugPrint('⏱️ Calculating delivery time for delivery data: $deliveryId');

      final record = await pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryId, expand: 'deliveryUpdates');

      final deliveryUpdates = record.expand['deliveryUpdates'] as List? ?? [];
      if (deliveryUpdates.isEmpty) {
        debugPrint(
          '⚠️ No delivery updates found for delivery data: $deliveryId',
        );

        // Update with 0 time
        await updateDeliveryDataTotalTime(deliveryId, 0);
        return 0;
      }

      final sortedUpdates =
          deliveryUpdates.map((update) {
              final data = update.data;
              return DeliveryUpdateModel.fromJson({
                'id': update.id,
                'collectionId': update.collectionId,
                'collectionName': update.collectionName,
                'title': data['title'],
                'subtitle': data['subtitle'],
                'time': data['time'],
                'customer': data['customer'],
                'isAssigned': data['isAssigned'],
              });
            }).toList()
            ..sort((a, b) => a.time!.compareTo(b.time!));

      final arrivedIndex = sortedUpdates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'arrived',
      );

      if (arrivedIndex == -1) {
        debugPrint(
          '⚠️ No "arrived" status found for delivery data: $deliveryId',
        );

        // Update with 0 time
        await updateDeliveryDataTotalTime(deliveryId, 0);
        return 0;
      }

      // Check for undelivered status
      final undeliveredIndex = sortedUpdates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as undelivered',
      );

      // Get end delivery status
      final endDeliveryIndex = sortedUpdates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'end delivery',
      );

      // Get mark as received status
      final receivedIndex = sortedUpdates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as received',
      );

      // Determine relevant updates based on delivery scenario
      List<DeliveryUpdateModel> relevantUpdates;
      if (undeliveredIndex != -1) {
        // Undelivered scenario - calculate until mark as undelivered
        relevantUpdates = sortedUpdates.sublist(
          arrivedIndex,
          undeliveredIndex + 1,
        );
        debugPrint('📊 Calculating time for undelivered scenario');
      } else if (receivedIndex != -1) {
        // Received scenario - calculate until mark as received
        relevantUpdates = sortedUpdates.sublist(
          arrivedIndex,
          receivedIndex + 1,
        );
        debugPrint('📊 Calculating time for received scenario');
      } else if (endDeliveryIndex != -1) {
        // Normal delivery - include end delivery
        relevantUpdates = sortedUpdates.sublist(
          arrivedIndex,
          endDeliveryIndex + 1,
        );
        debugPrint('📊 Calculating time for normal delivery scenario');
      } else {
        // Fallback to all updates from arrived
        relevantUpdates = sortedUpdates.sublist(arrivedIndex);
        debugPrint('📊 Calculating time for ongoing delivery scenario');
      }

      int totalSeconds = 0;
      for (int i = 0; i < relevantUpdates.length - 1; i++) {
        final currentTime = relevantUpdates[i].time!;
        final nextTime = relevantUpdates[i + 1].time!;
        final diffInSeconds = nextTime.difference(currentTime).inSeconds;
        totalSeconds += diffInSeconds;

        debugPrint(
          'Status: ${relevantUpdates[i].title} -> ${relevantUpdates[i + 1].title}',
        );
        debugPrint(
          'Time: ${formatTime(currentTime)} -> ${formatTime(nextTime)}',
        );
        debugPrint(
          'Difference: ${diffInSeconds ~/ 60} minutes ${diffInSeconds % 60} seconds\n',
        );
      }

      final totalMinutes = (totalSeconds / 60).round();

      debugPrint(
        '✅ Total delivery time calculated: $totalMinutes minutes ($totalSeconds seconds)',
      );

      // Update the deliveryData record with the calculated time
      final formattedTime = await updateDeliveryDataTotalTime(
        deliveryId,
        totalSeconds,
      );
      debugPrint('✅ Formatted delivery time persisted: $formattedTime');

      return totalMinutes;
    } catch (e) {
      debugPrint('❌ Failed to calculate delivery time: $e');
      throw ServerException(
        message: 'Failed to calculate delivery time: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
