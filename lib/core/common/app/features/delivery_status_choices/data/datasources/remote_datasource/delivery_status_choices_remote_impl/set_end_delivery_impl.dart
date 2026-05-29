import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/remote_datasource/delivery_status_choices_remote_impl/delivery_status_choices_remote_base.dart';
import '../../../../../../../../errors/exceptions.dart';

mixin SetEndDeliveryImpl on DeliveryStatusChoicesRemoteBase {
  Future<void> setEndDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint(
        '🔄 Processing delivery completion for delivery data: ${deliveryData.id}',
      );

      // ---------------------------------------------------
      // 0️⃣ Validate Delivery ID
      // ---------------------------------------------------
      final deliveryDataId = deliveryData.id;
      if (deliveryDataId == null || deliveryDataId.isEmpty) {
        throw const ServerException(
          message: 'Invalid delivery data ID',
          statusCode: '400',
        );
      }

      // ---------------------------------------------------
      // 1️⃣ Resolve Trip ID (REQUIRED)
      // ---------------------------------------------------
      final tripId = deliveryData.trip.target?.id;
      if (tripId == null || tripId.isEmpty) {
        throw const ServerException(
          message: 'Trip ID not found for delivery data',
          statusCode: '404',
        );
      }

      debugPrint('🚛 Found trip ID: $tripId');

      // ---------------------------------------------------
      // 2️⃣ Create "End Delivery" delivery update (REQUIRED)
      // ---------------------------------------------------
      debugPrint('📝 Adding "End Delivery" status');

      final endDeliveryStatus = await pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFirstListItem('title = "End Delivery"');

      final now =
          DateTime.now()
              .add(const Duration(minutes: 1))
              .toUtc()
              .toIso8601String();

      final deliveryUpdateRecord = await pocketBaseClient
          .collection('deliveryUpdate')
          .create(
            body: {
              'deliveryData': deliveryDataId,
              'status': endDeliveryStatus.id,
              'title': endDeliveryStatus.data['title'],
              'subtitle': endDeliveryStatus.data['subtitle'],
              'created': now,
              'time': now,
              'isAssigned': true,
            },
          );

      debugPrint('✅ End Delivery update created → ${deliveryUpdateRecord.id}');

      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'invoiceStatus': 'delivered',
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      // NOTE: Collection creation has been moved to createDeliveryReceipt
      // in the delivery receipt datasources. It is no longer created here.

      // ---------------------------------------------------
      // 3️⃣ Update User Performance (OPTIONAL — NON-BLOCKING)
      // ---------------------------------------------------
      try {
        debugPrint('📊 Updating user performance');

        final tripTicket = await pocketBaseClient
            .collection('tripticket')
            .getOne(tripId);

        final userId = tripTicket.data['user'];

        if (userId != null && userId.toString().isNotEmpty) {
          final perfRecords = await pocketBaseClient
              .collection('userPerformance')
              .getList(filter: 'user = "$userId"');

          if (perfRecords.items.isNotEmpty) {
            final perf = perfRecords.items.first;

            final success =
                int.tryParse(
                  perf.data['successfulDeliveries']?.toString() ?? '0',
                ) ??
                0;
            final total =
                int.tryParse(perf.data['totalDeliveries']?.toString() ?? '0') ??
                0;

            final newSuccess = success + 1;
            final successRate = total > 0 ? (newSuccess / total) * 100 : 0;

            await pocketBaseClient
                .collection('userPerformance')
                .update(
                  perf.id,
                  body: {
                    'successfulDeliveries': newSuccess.toString(),
                    'successRate': successRate.toStringAsFixed(2),
                    'updated': DateTime.now().toUtc().toIso8601String(),
                  },
                );

            debugPrint('✅ User performance updated');
          } else {
            debugPrint('⚠️ No user performance record found');
          }
        }
      } catch (e) {
        debugPrint('⚠️ User performance update failed (ignored): $e');
      }

      // ---------------------------------------------------
      // 4️⃣ Update Delivery Team (REQUIRED)
      // ---------------------------------------------------
      final teamRecords = await pocketBaseClient
          .collection('deliveryTeam')
          .getList(filter: 'tripTicket = "$tripId"');

      if (teamRecords.items.isEmpty) {
        throw const ServerException(
          message: 'Delivery team not found for this trip',
          statusCode: '404',
        );
      }

      final team = teamRecords.items.first;

      final active =
          int.tryParse(team.data['activeDeliveries']?.toString() ?? '0') ?? 0;
      final total =
          int.tryParse(team.data['totalDelivered']?.toString() ?? '0') ?? 0;

      await pocketBaseClient
          .collection('deliveryTeam')
          .update(
            team.id,
            body: {
              'activeDeliveries': (active - 1).clamp(0, 999999).toString(),
              'totalDelivered': (total + 1).toString(),
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      // ---------------------------------------------------
      // 5️⃣ Update Trip Ticket (REQUIRED)
      // ---------------------------------------------------
      await pocketBaseClient
          .collection('tripticket')
          .update(
            tripId,
            body: {'updated': DateTime.now().toUtc().toIso8601String()},
          );

      debugPrint('🎉 DELIVERY COMPLETED SUCCESSFULLY');
    } catch (e) {
      debugPrint('❌ Failed to complete delivery: $e');
      throw ServerException(
        message: 'Failed to complete delivery: $e',
        statusCode: '500',
      );
    }
  }
}
