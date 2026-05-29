import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin BulkUpdateDeliveryStatusImpl on DeliveryUpdateRemoteBase {
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  ) async {
    try {
      debugPrint(
        '🔄 Processing bulk status update - Customers: $customerIds, Status: $statusId',
      );

      // Validate status ID
      if (statusId.isEmpty) {
        debugPrint('⚠️ Invalid status ID provided');
        throw const ServerException(
          message: 'Invalid status ID',
          statusCode: '400',
        );
      }

      // Get the status record once (reuse for all customers)
      final statusRecord = await pocketBaseClient
          .collection('deliveryStatusChoices')
          .getOne(statusId);

      final title = statusRecord.data['title'];
      final subtitle = statusRecord.data['subtitle'];

      debugPrint('✅ Retrieved status: $title');

      final currentTime = DateTime.now().toUtc().toIso8601String();

      // Iterate over all customers
      for (final customerId in customerIds) {
        try {
          debugPrint('➡️ Updating customer: $customerId');

          // Create delivery update record for this customer
          final deliveryUpdateRecord = await pocketBaseClient
              .collection('deliveryUpdate')
              .create(
                body: {
                  'deliveryData': customerId,
                  'status': statusId,
                  'title': title,
                  'subtitle': subtitle,
                  'created': currentTime,
                  'time': currentTime,
                  'isAssigned': true,
                },
              );

          debugPrint(
            '📝 Created delivery update: ${deliveryUpdateRecord.id} for customer $customerId',
          );

          // Update deliveryData record
          await pocketBaseClient
              .collection('deliveryData')
              .update(
                customerId,
                body: {
                  'deliveryUpdates+': [deliveryUpdateRecord.id],
                },
              );

          debugPrint('✅ Successfully updated status for customer: $customerId');
        } catch (e) {
          debugPrint('⚠️ Failed to update customer $customerId: $e');
          // Continue with next customer instead of breaking whole process
        }
      }

      debugPrint(
        '🎉 Bulk update completed for ${customerIds.length} customers',
      );
    } catch (e) {
      debugPrint('❌ Bulk operation failed: ${e.toString()}');
      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Bulk operation failed: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }
}
