import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/remote_datasource/delivery_status_choices_remote_impl/delivery_status_choices_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/remote_datasource/delivery_status_choices_remote_impl/update_customer_status_impl.dart';
import '../../../../../../../../errors/exceptions.dart';

mixin BulkUpdateDeliveryStatusImpl
    on DeliveryStatusChoicesRemoteBase, UpdateCustomerStatusImpl {
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesModel statusId,
  ) async {
    try {
      debugPrint(
        '🔄 Processing bulk status update - Customers: $customerIds, Status: ${statusId.id}',
      );

      if (statusId.id == null || statusId.id!.isEmpty) {
        debugPrint('⚠️ Invalid status ID provided');
        throw const ServerException(
          message: 'Invalid status ID',
          statusCode: '400',
        );
      }

      // ---------------------------------------------------
      // 🆕 BULK DEDUPLICATION: Block if ANY update with this status exists
      // ---------------------------------------------------
      final customersToUpdate = <String>[];
      final skippedCustomers = <String>[];

      for (final customerId in customerIds) {
        try {
          final deliveryRecord = await pocketBaseClient
              .collection('deliveryData')
              .getOne(customerId, expand: 'deliveryUpdates');

          final existingUpdates =
              deliveryRecord.expand['deliveryUpdates'] as List? ?? [];

          // Block if this status already exists (ANY state: pending, syncing, or synced)
          final hasDuplicate = existingUpdates.any((update) {
            final updateStatusId = update.data?['statusChoicePbId']?.toString();
            return updateStatusId == statusId.id;
          });

          if (hasDuplicate) {
            skippedCustomers.add(customerId);
            debugPrint(
              '   ⚠️ Skipping $customerId - duplicate pending "${statusId.title}" exists',
            );
          } else {
            customersToUpdate.add(customerId);
          }
        } catch (e) {
          debugPrint('   ⚠️ Could not check duplicates for $customerId: $e');
          customersToUpdate.add(customerId); // Try anyway
        }
      }

      debugPrint(
        '📊 Processing ${customersToUpdate.length} customers (${skippedCustomers.length} duplicates skipped)',
      );

      if (customersToUpdate.isEmpty) {
        debugPrint('✅ All customers already have this status - skipping');
        return;
      }

      final currentTime = DateTime.now().toUtc().toIso8601String();

      for (final customerId in customersToUpdate) {
        try {
          debugPrint('➡️ Updating customer: $customerId');

          final deliveryUpdateRecord = await pocketBaseClient
              .collection('deliveryUpdate')
              .create(
                body: {
                  'deliveryData': customerId,
                  'status': statusId.id,
                  'title': statusId.title,
                  'subtitle': statusId.subtitle,
                  'created': currentTime,
                  'time': currentTime,
                  'isAssigned': true,
                },
              );

          debugPrint(
            '📝 Created delivery update: ${deliveryUpdateRecord.id} for $customerId',
          );

          await pocketBaseClient
              .collection('deliveryData')
              .update(
                customerId,
                body: {
                  'deliveryUpdates+': [deliveryUpdateRecord.id],
                },
              );

          debugPrint('✅ Attached update to deliveryData for $customerId');

          // Create notification
          final deliveryDataRecord = await pocketBaseClient
              .collection('deliveryData')
              .getOne(customerId);
          final tripId = deliveryDataRecord.data['trip'];

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

          debugPrint('✅ Notification created for $customerId');
        } catch (e) {
          debugPrint('⚠️ Failed to update customer $customerId: $e');
          // continue to next customer
        }
      }

      debugPrint(
        '🎉 Bulk update completed for ${customersToUpdate.length} customers (${skippedCustomers.length} skipped)',
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
