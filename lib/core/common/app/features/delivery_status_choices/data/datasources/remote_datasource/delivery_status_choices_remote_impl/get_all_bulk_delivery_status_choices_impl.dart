import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/remote_datasource/delivery_status_choices_remote_impl/delivery_status_choices_remote_base.dart';
import '../../../../../../../../errors/exceptions.dart';

mixin GetAllBulkDeliveryStatusChoicesImpl on DeliveryStatusChoicesRemoteBase {
  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds) async {
    final Map<String, List<DeliveryStatusChoicesModel>> result = {};

    try {
      debugPrint(
        '🚚 Fetching bulk delivery status choices for customers: $customerIds',
      );

      // Fetch all status choices once
      final allStatuses =
          await pocketBaseClient
              .collection('deliveryStatusChoices')
              .getFullList();

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

          final allowedTitles = <String>[];
          switch (latestStatus) {
            case 'in transit':
              allowedTitles.addAll(['arrived']);
              break;
            case 'waiting for customer':
              allowedTitles.addAll(['unloading', 'invoices in queue']);
              break;
            case 'invoices in queue':
              allowedTitles.addAll(['unloading']);
              break;
            case 'unloading':
              allowedTitles.addAll(['']);

              break;

            case 'arrived':
              allowedTitles.addAll([
                'unloading',
                'mark as undelivered',
                'waiting for customer',
                'invoices in queue',
              ]);
              break;
            case 'mark as received':
              allowedTitles.addAll(['']);
              break;
            case 'mark as undelivered':
            case 'end delivery':
              result[customerId] = [];
              continue;
          }

          final assignedTitles =
              deliveryUpdates
                  ?.map(
                    (record) => record.data['title'].toString().toLowerCase(),
                  )
                  .toSet() ??
              {};

          debugPrint('📋 Already assigned titles: $assignedTitles');

          final filteredStatuses =
              allStatuses
                  .where(
                    (status) => allowedTitles.contains(
                      status.data['title'].toString().toLowerCase(),
                    ),
                  )
                  .where(
                    (status) =>
                        !assignedTitles.contains(
                          status.data['title'].toString().toLowerCase(),
                        ),
                  )
                  .map(
                    (record) => DeliveryStatusChoicesModel(
                      id: record.id,
                      title: record.data['title'],
                      subtitle: record.data['subtitle'],
                      collectionId: record.collectionId,
                      collectionName: record.collectionName,
                    ),
                  )
                  .toList();

          result[customerId] = filteredStatuses;
          debugPrint(
            '✅ Prepared ${filteredStatuses.length} choices for $customerId',
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
