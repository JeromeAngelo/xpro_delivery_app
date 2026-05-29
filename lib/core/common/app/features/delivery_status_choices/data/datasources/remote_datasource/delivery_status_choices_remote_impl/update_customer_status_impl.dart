import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/remote_datasource/delivery_status_choices_remote_impl/delivery_status_choices_remote_base.dart';
import '../../../../../../../../errors/exceptions.dart';

mixin UpdateCustomerStatusImpl on DeliveryStatusChoicesRemoteBase {
  Future<String> updateCustomerStatus(
    String deliveryDataId,
    DeliveryStatusChoicesModel status,
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
      // 🆕 0️⃣-A IDEMPOTENCY CHECK: Prevent ANY duplicate remote creation
      // ---------------------------------------------------
      try {
        final deliveryRecord = await pocketBaseClient
            .collection('deliveryData')
            .getOne(deliveryDataId, expand: 'deliveryUpdates');

        final existingUpdates =
            deliveryRecord.expand['deliveryUpdates'] as List? ?? [];

        // Check if this exact status already exists (ANY state: pending, syncing, or synced)
        for (final update in existingUpdates) {
          final updateStatusId = update.data?['statusChoicePbId']?.toString();
          final updateTitle = update.data?['title']?.toString() ?? '';

          if (updateStatusId == status.id) {
            debugPrint(
              '🚫 IDEMPOTENCY: Status "${status.title}" already exists in remote for delivery $deliveryDataId',
            );
            debugPrint('   📋 Existing update ID: ${update.id}');
            debugPrint('   📋 Existing title: $updateTitle');
            debugPrint(
              '   ✅ Returning existing ID instead of creating duplicate',
            );
            return update.id; // ✅ Return existing instead of creating new
          }
        }

        debugPrint('✅ Idempotency check passed - no duplicate status found');
      } catch (e) {
        debugPrint('⚠️ Idempotency check failed (will attempt creation): $e');
        // Continue with creation if idempotency check fails
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

      // Return created delivery update id to caller so local records can be reconciled
      return deliveryUpdateRecord.id;
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
