import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetDeliveryStatusChoicesImpl on DeliveryUpdateRemoteBase {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(
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

      // Handle In Transit status
      if (latestStatus == 'in transit') {
        final allowedTitles = ['arrived', 'mark as undelivered'];
        return filterStatusChoices(allStatuses, allowedTitles);
      }
      if (latestStatus == 'waiting for customer') {
        final allowedTitles = [
          'unloading',
          'mark as undelivered',
          'invoices in queue',
        ];
        return filterStatusChoices(allStatuses, allowedTitles);
      }

      if (latestStatus == 'invoices in queue') {
        final allowedTitles = ['unloading', 'mark as undelivered'];
        return filterStatusChoices(allStatuses, allowedTitles);
      }

      // Handle Waiting for customers

      // Handle Unloading
      if (latestStatus == 'unloading') {
        final allowedTitles = ['mark as received'];
        return filterStatusChoices(allStatuses, allowedTitles);
      }

      if (latestStatus == 'mark as received') {
        final allowedTitles = ['end delivery'];
        return filterStatusChoices(allStatuses, allowedTitles);
      }

      // Handle Arrived status
      if (latestStatus == 'arrived') {
        final allowedTitles = [
          'unloading',
          'mark as undelivered',
          'waiting for customer',
          'invoices in queue',
        ];
        return filterStatusChoices(allStatuses, allowedTitles);
      }

      if (latestStatus == 'mark as undelivered') {
        return [];
      }

      if (latestStatus == 'end delivery') {
        return [];
      }

      final assignedTitles =
          deliveryUpdates
              ?.map((record) => record.data['title'].toString().toLowerCase())
              .toSet() ??
          {};

      debugPrint('📋 Already assigned titles: $assignedTitles');

      return allStatuses
          .where(
            (status) =>
                !assignedTitles.contains(
                  status.data['title'].toString().toLowerCase(),
                ),
          )
          .map((record) => DeliveryUpdateModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching delivery status choices: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
