import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheCancelledInvoicesImpl on CancelledInvoiceLocalBase {
  Future<void> cacheCancelledInvoices(
    List<CancelledInvoiceModel> cancelledInvoices,
  ) async {
    try {
      debugPrint('💾 LOCAL: Starting cancelled invoices caching process...');
      debugPrint(
        '📥 LOCAL: Received ${cancelledInvoices.length} cancelled invoices to cache',
      );

      await cleanupCancelledInvoices();
      await autoSave(cancelledInvoices);

      final cachedCount = cancelledInvoiceBox.count();
      debugPrint(
        '✅ LOCAL: Cache verification: $cachedCount cancelled invoices stored',
      );

      cachedCancelledInvoicesList = cancelledInvoices;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
