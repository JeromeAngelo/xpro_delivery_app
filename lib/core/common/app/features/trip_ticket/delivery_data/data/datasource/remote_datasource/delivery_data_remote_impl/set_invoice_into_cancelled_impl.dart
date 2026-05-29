import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';

mixin SetInvoiceIntoCancelledImpl on DeliveryDataRemoteBase {
  Future<DeliveryDataModel> setInvoiceIntoCancelled(
    String deliveryDataId,
    String invoiceId,
  ) async {
    try {
      debugPrint(
        '🔄 Cancelling invoice: $invoiceId for delivery: $deliveryDataId',
      );

      /// STEP 1: Get deliveryData with invoices
      final deliveryRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId, expand: 'invoices');

      /// STEP 2: Validate invoice exists in deliveryData
      bool invoiceExists = false;

      if (deliveryRecord.expand['invoices'] != null) {
        final invoicesData = deliveryRecord.expand['invoices'];

        if (invoicesData is List) {
          invoiceExists = invoicesData!.any((inv) => inv.id == invoiceId);
        }
      }

      if (!invoiceExists) {
        debugPrint('❌ Invoice $invoiceId not found in deliveryData');
        throw ServerException(
          message: 'Invoice not found in delivery data',
          statusCode: '404',
        );
      }

      debugPrint('✅ Invoice found in deliveryData');

      /// STEP 3: Find invoiceStatus record using invoiceId
      final invoiceStatusRecords = await pocketBaseClient
          .collection('invoiceStatus')
          .getFullList(filter: 'invoiceData = "$invoiceId"');

      if (invoiceStatusRecords.isEmpty) {
        debugPrint('⚠️ No invoiceStatus found for invoice: $invoiceId');
      }

      /// STEP 4: Update invoiceStatus → cancelled
      for (var statusRecord in invoiceStatusRecords) {
        await pocketBaseClient
            .collection('invoiceStatus')
            .update(
              statusRecord.id,
              body: {
                'tripStatus': 'cancelled', // 🔥 MAIN CHANGE
                'updated': DateTime.now().toUtc().toIso8601String(),
              },
            );

        debugPrint('✅ Updated invoiceStatus: ${statusRecord.id} → cancelled');
      }

      /// STEP 5: OPTIONAL → update deliveryData summary status
      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {'updated': DateTime.now().toUtc().toIso8601String()},
          );

      /// STEP 6: Fetch updated deliveryData with relations
      final updatedRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand:
                'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      debugPrint('✅ Invoice successfully marked as CANCELLED');

      return processDeliveryDataRecord(updatedRecord);
    } catch (e) {
      debugPrint('❌ Failed to cancel invoice: ${e.toString()}');

      throw ServerException(
        message: 'Failed to cancel invoice: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
