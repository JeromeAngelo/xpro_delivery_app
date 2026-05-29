import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/remote_datasource/delivery_status_choices_remote_impl/delivery_status_choices_remote_base.dart';
import '../../../../../../../../errors/exceptions.dart';

mixin GetAllAssignedDeliveryStatusChoicesImpl
    on DeliveryStatusChoicesRemoteBase {
  Future<List<DeliveryStatusChoicesModel>> getAllAssignedDeliveryStatusChoices(
    String customerId,
  ) async {
    try {
      debugPrint(
        '🚚 Fetching delivery status choices for customer: $customerId',
      );

      final customerRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(customerId, expand: 'deliveryUpdates');

      final deliveryUpdates = customerRecord.expand['deliveryUpdates'] as List?;
      final latestStatus =
          deliveryUpdates?.isNotEmpty == true
              ? deliveryUpdates!.last.data['title'].toString().toLowerCase()
              : '';

      debugPrint('📍 Latest status for customer $customerId: $latestStatus');

      final allStatuses =
          await pocketBaseClient
              .collection('deliveryStatusChoices')
              .getFullList();

      // Log available status choices
      for (var status in allStatuses) {
        debugPrint(
          '🏷️ Available Status - ID: ${status.id}, Title: ${status.data['title']}',
        );
      }

      // Apply status rules
      final allowedTitles = <String>[];
      switch (latestStatus) {
        case 'in transit':
          allowedTitles.addAll(['arrived', 'mark as undelivered']);
          break;
        case 'waiting for customer':
          allowedTitles.addAll([
            'unloading',
            'mark as undelivered',
            'invoices in queue',
          ]);
          break;
        case 'invoices in queue':
          allowedTitles.addAll(['unloading', 'mark as undelivered']);
          break;

        case 'arrived':
          allowedTitles.addAll([
            'unloading',
            'mark as undelivered',
            'waiting for customer',
            'invoices in queue',
          ]);
        case 'unloading':
          allowedTitles.addAll(['mark as received']);

          break;
        case 'mark as received':
          allowedTitles.addAll(['end delivery']);

          break;
        case 'mark as undelivered':
        case 'end delivery':
          return [];
      }

      final assignedTitles =
          deliveryUpdates
              ?.map((record) => record.data['title'].toString().toLowerCase())
              .toSet() ??
          {};

      debugPrint('📋 Already assigned titles: $assignedTitles');

      // Filter allowed and not assigned yet
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
              .map((record) {
                final statusId = record.id;
                debugPrint(
                  '🏷️ Processing status - ID: $statusId, Title: ${record.data['title']}',
                );

                return DeliveryStatusChoicesModel(
                  id: statusId,
                  title: record.data['title'],
                  subtitle: record.data['subtitle'],
                  collectionId: record.collectionId,
                  collectionName: record.collectionName,
                );
              })
              .toList();

      return filteredStatuses;
    } catch (e) {
      debugPrint('❌ Error fetching delivery status choices: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
