import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetAllCancelledInvoicesImpl on CancelledInvoiceLocalBase {
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices() async {
    try {
      debugPrint('📱 LOCAL: Fetching all cancelled invoices');

      final cancelledInvoices = cancelledInvoiceBox.getAll();

      debugPrint('📊 Storage Stats:');
      debugPrint(
        'Total stored cancelled invoices: ${cancelledInvoiceBox.count()}',
      );
      debugPrint('Found cancelled invoices: ${cancelledInvoices.length}');

      // Set up relations for each cancelled invoice
      for (final cancelledInvoice in cancelledInvoices) {
        setupRelations(cancelledInvoice);
      }

      cachedCancelledInvoicesList = cancelledInvoices;
      return cancelledInvoices;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
