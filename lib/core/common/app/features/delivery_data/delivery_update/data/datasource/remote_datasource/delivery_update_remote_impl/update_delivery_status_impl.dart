import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin UpdateDeliveryStatusImpl on DeliveryUpdateRemoteBase {
  Future<void> updateDeliveryStatus(
    String deliveryDataId, // DeliveryData PB ID
    DeliveryStatusChoicesModel status, // ✅ FULL MODEL
  ) async {
    try {
      debugPrint(
        '🔄 Processing status update - DeliveryData: $deliveryDataId, '
        'Status: ${status.title} (${status.id})',
      );

      // ---------------------------------------------------
      // 0️⃣ VALIDATE
      // ---------------------------------------------------
      if (status.id!.isEmpty) {
        debugPrint('⚠️ Invalid status PB ID provided');
        throw const ServerException(
          message: 'Invalid status ID',
          statusCode: '400',
        );
      }

      // ---------------------------------------------------
      // 1️⃣ CREATE DeliveryUpdate (COPY DATA)
      // ---------------------------------------------------
      final currentTime = DateTime.now().toUtc().toIso8601String();

      final deliveryUpdateRecord = await pocketBaseClient
          .collection('deliveryUpdate')
          .create(
            body: {
              'deliveryData': deliveryDataId,
              'status': status.id, // 🔑 PB relation
              'title': status.title, // 📋 copied
              'subtitle': status.subtitle, // 📋 copied
              'created': currentTime,
              'time': currentTime,
              'isAssigned': true,
            },
          );

      debugPrint('📝 Created delivery update: ${deliveryUpdateRecord.id}');

      // ---------------------------------------------------
      // 2️⃣ ATTACH DeliveryUpdate → DeliveryData
      // ---------------------------------------------------
      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Successfully updated deliveryData');

      // ---------------------------------------------------
      // 3️⃣ CREATE NOTIFICATION (REMOTE ONLY)
      // ---------------------------------------------------
      final deliveryDataRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId);

      final tripId = deliveryDataRecord.data['trip'];

      debugPrint('📦 Found trip for notification: $tripId');

      await pocketBaseClient
          .collection('notifications')
          .create(
            body: {
              'delivery': deliveryDataRecord.id,
              'status': deliveryUpdateRecord.id,
              'trip': tripId,
              'type': 'deliveryUpdate',
              'created': currentTime,
            },
          );

      debugPrint('✅ Successfully created notification');
    } catch (e) {
      debugPrint('❌ Operation failed: ${e.toString()}');
      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Operation failed: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }
}
