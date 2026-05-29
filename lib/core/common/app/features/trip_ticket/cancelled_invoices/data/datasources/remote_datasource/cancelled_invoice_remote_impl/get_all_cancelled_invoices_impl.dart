import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/cancelled_invoice_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetAllCancelledInvoicesImpl on CancelledInvoiceRemoteBase {
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices() async {
    try {
      debugPrint('🔄 Fetching all cancelled invoices');

      final records = await pocketBaseClient
          .collection('cancelledInvoice')
          .getFullList(
            expand:
                'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} cancelled invoices from API');

      List<CancelledInvoiceModel> cancelledInvoices = [];

      for (var record in records) {
        cancelledInvoices.add(processCancelledInvoiceRecord(record));
      }

      debugPrint(
        '✨ Successfully processed ${cancelledInvoices.length} cancelled invoices',
      );
      return cancelledInvoices;
    } catch (e) {
      debugPrint('❌ Failed to fetch all cancelled invoices: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load cancelled invoices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
