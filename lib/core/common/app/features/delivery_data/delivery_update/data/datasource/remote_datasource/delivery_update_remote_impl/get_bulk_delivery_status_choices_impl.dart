import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetBulkDeliveryStatusChoicesImpl on DeliveryUpdateRemoteBase {
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  ) async {
    final Map<String, List<DeliveryUpdateModel>> result = {};

    try {
      debugPrint(
        '🚚 Fetching bulk delivery status choices for customers: $customerIds',
      );

      for (final customerId in customerIds) {
        try {
          final customerRecord = await pocketBaseClient
              .collection('deliveryData')
              .getOne(customerId, expand: 'deliveryUpdates');

          final deliveryUpdates =
              customerRecord.expand['deliveryUpdates'] as List?;
          final latestStatus =
              deliveryUpdates?.isNotEmpty == true
                  ? deliveryUpdates!.last.data['title'].toString().toLowerCase()
                  : '';

          debugPrint(
            '📍 Latest status for customer $customerId: $latestStatus',
          );

          final allStatuses =
              await pocketBaseClient
                  .collection('deliveryStatusChoices')
                  .getFullList();

          // Handle different states
          List<DeliveryUpdateModel> filteredStatuses = [];
          if (latestStatus == 'in transit') {
            filteredStatuses = filterStatusChoices(allStatuses, [
              'arrived',
              'mark as undelivered',
            ]);
          } else if (latestStatus == 'waiting for customer') {
            filteredStatuses = filterStatusChoices(allStatuses, [
              'unloading',
              'invoices in queue',
              'mark as undelivered',
            ]);
          } else if (latestStatus == 'invoices in queue') {
            filteredStatuses = filterStatusChoices(allStatuses, [
              'unloading',
              'mark as undelivered',
            ]);
          } else if (latestStatus == 'unloading') {
            filteredStatuses = filterStatusChoices(allStatuses, [
              'mark as received',
            ]);
          } else if (latestStatus == 'mark as received') {
            filteredStatuses = filterStatusChoices(allStatuses, [
              'end delivery',
            ]);
          } else if (latestStatus == 'arrived') {
            filteredStatuses = filterStatusChoices(allStatuses, [
              'unloading',
              'mark as undelivered',
              'waiting for customer',
              'invoices in queue',
            ]);
          } else if (latestStatus == 'mark as undelivered' ||
              latestStatus == 'end delivery') {
            filteredStatuses = [];
          } else {
            // Default logic: remove already assigned
            final assignedTitles =
                deliveryUpdates
                    ?.map(
                      (record) => record.data['title'].toString().toLowerCase(),
                    )
                    .toSet() ??
                {};

            filteredStatuses =
                allStatuses
                    .where(
                      (status) =>
                          !assignedTitles.contains(
                            status.data['title'].toString().toLowerCase(),
                          ),
                    )
                    .map(
                      (record) => DeliveryUpdateModel.fromJson(record.toJson()),
                    )
                    .toList();
          }

          result[customerId] = filteredStatuses;
          debugPrint(
            '✅ Added ${filteredStatuses.length} statuses for $customerId',
          );
        } catch (e) {
          debugPrint('❌ Failed to fetch statuses for $customerId: $e');
          result[customerId] = [];
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error in bulk status fetch: ${e.toString()}');
      throw ServerException(
        message:
            'Failed to fetch bulk delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
