import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/cancelled_invoice_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadCancelledInvoiceByIdImpl on CancelledInvoiceRemoteBase {
  Future<CancelledInvoiceModel> loadCancelledInvoiceById(String id) async {
    try {
      debugPrint('🔄 Loading cancelled invoice by ID: $id');

      final record = await pocketBaseClient
          .collection('cancelledInvoice')
          .getOne(
            id,
            expand:
                'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer',
          );

      debugPrint('✅ Retrieved cancelled invoice from API: ${record.id}');

      return processCancelledInvoiceRecord(record);
    } catch (e) {
      debugPrint('❌ Failed to load cancelled invoice by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load cancelled invoice by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
