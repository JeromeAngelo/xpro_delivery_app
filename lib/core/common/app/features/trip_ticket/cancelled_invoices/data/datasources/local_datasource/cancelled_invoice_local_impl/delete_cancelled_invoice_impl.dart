import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin DeleteCancelledInvoiceImpl on CancelledInvoiceLocalBase {
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId) async {
    try {
      debugPrint('📱 LOCAL: Deleting cancelled invoice: $cancelledInvoiceId');

      final cancelledInvoice =
          cancelledInvoiceBox
              .query(CancelledInvoiceModel_.id.equals(cancelledInvoiceId))
              .build()
              .findFirst();

      if (cancelledInvoice == null) {
        debugPrint(
          '⚠️ LOCAL: Cancelled invoice not found: $cancelledInvoiceId',
        );
        return false;
      }

      final success = cancelledInvoiceBox.remove(cancelledInvoice.objectBoxId);

      if (success) {
        debugPrint('✅ LOCAL: Successfully deleted cancelled invoice');
      } else {
        debugPrint('❌ LOCAL: Failed to delete cancelled invoice');
      }

      return success;
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Failed to delete cancelled invoice: ${e.toString()}',
      );
      throw CacheException(message: e.toString());
    }
  }
}
