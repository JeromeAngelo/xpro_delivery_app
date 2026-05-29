import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin SetInvoiceIntoUnloadingImpl on DeliveryDataRemoteBase {
  Future<DeliveryDataModel> setInvoiceIntoUnloading(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 Setting invoice to unloading for delivery data: $deliveryDataId',
      );

      // Step 1: Get delivery data with invoices to extract invoice IDs
      final deliveryRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId, expand: 'invoices');

      // Step 2: Extract invoice IDs from the delivery data
      List<String> invoiceIds = [];
      if (deliveryRecord.expand['invoices'] != null) {
        final invoicesData = deliveryRecord.expand['invoices'];
        if (invoicesData is List) {
          invoiceIds = invoicesData!.map((invoice) => invoice.id).toList();
          debugPrint('📋 Found ${invoiceIds.length} invoices: $invoiceIds');
        }
      }

      if (invoiceIds.isEmpty) {
        debugPrint('⚠️ No invoices found for delivery data: $deliveryDataId');
      } else {
        // Step 3: Update invoiceStatus collection for all matching invoices
        for (String invoiceId in invoiceIds) {
          debugPrint('🔄 Updating invoiceStatus for invoice: $invoiceId');

          try {
            // Find invoiceStatus records where invoiceData field matches this invoice ID
            final invoiceStatusRecords = await pocketBaseClient
                .collection('invoiceStatus')
                .getFullList(filter: 'invoiceData = "$invoiceId"');

            debugPrint(
              '📊 Found ${invoiceStatusRecords.length} invoiceStatus records for invoice: $invoiceId',
            );

            // Update all matching invoiceStatus records
            for (var statusRecord in invoiceStatusRecords) {
              await pocketBaseClient
                  .collection('invoiceStatus')
                  .update(
                    statusRecord.id,
                    body: {
                      'tripStatus': 'unloading',
                      'updated': DateTime.now().toUtc().toIso8601String(),
                    },
                  );

              debugPrint(
                '✅ Updated invoiceStatus record: ${statusRecord.id} to unloading',
              );
            }
          } catch (e) {
            debugPrint(
              '❌ Error updating invoiceStatus for invoice $invoiceId: $e',
            );
            // Continue with other invoices even if one fails
          }
        }
      }

      // Step 4: Update the delivery data with unloading status
      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'isUnloading': true,
              'invoiceStatus': 'unloading',
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint(
        '✅ Successfully set delivery data invoice status to unloading',
      );

      // Step 5: Get the updated record with expanded relations
      final updatedRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand:
                'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      return processDeliveryDataRecord(updatedRecord);
    } catch (e) {
      debugPrint('❌ Failed to set invoice to unloading: ${e.toString()}');
      throw ServerException(
        message: 'Failed to set invoice to unloading: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
