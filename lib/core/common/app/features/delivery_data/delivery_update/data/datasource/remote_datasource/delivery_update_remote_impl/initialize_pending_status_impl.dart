import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin InitializePendingStatusImpl on DeliveryUpdateRemoteBase {
  Future<void> initializePendingStatus(List<String> customerIds) async {
    try {
      debugPrint('🔄 Initializing pending status for customers');

      final pendingStatus = await pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFirstListItem('title = "Pending"');

      for (final customerId in customerIds) {
        // Check if customer already has a pending status
        final customerRecord = await pocketBaseClient
            .collection('customers')
            .getOne(customerId, expand: 'deliveryStatus');

        final existingStatuses =
            customerRecord.expand['deliveryStatus'] as List? ?? [];
        final hasPendingStatus = existingStatuses.any(
          (status) => status.data['title'] == 'Pending',
        );

        if (!hasPendingStatus) {
          final currentTime = DateTime.now().toUtc().toIso8601String();
          final deliveryUpdateRecord = await pocketBaseClient
              .collection('deliveryUpdate')
              .create(
                body: {
                  'customer': customerId,
                  'deliveryData': customerId,
                  'status': pendingStatus.id,
                  'title': pendingStatus.data['title'],
                  'subtitle': pendingStatus.data['subtitle'],
                  'created': currentTime,
                  'time': currentTime,
                  'isAssigned': true,
                },
              );

          await pocketBaseClient
              .collection('deliveryData')
              .update(
                customerId,
                body: {
                  'deliveryStatus': [deliveryUpdateRecord.id],
                },
              );
        }
      }

      debugPrint('✅ Successfully initialized pending status');
    } catch (e) {
      debugPrint('❌ Failed to initialize pending status: $e');
      throw ServerException(
        message: 'Failed to initialize pending status: $e',
        statusCode: '500',
      );
    }
  }
}
