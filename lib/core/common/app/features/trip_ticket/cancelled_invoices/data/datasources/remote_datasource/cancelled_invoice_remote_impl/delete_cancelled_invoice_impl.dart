import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/cancelled_invoice_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin DeleteCancelledInvoiceImpl on CancelledInvoiceRemoteBase {
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId) async {
    try {
      debugPrint('🔄 Deleting cancelled invoice: $cancelledInvoiceId');

      await pocketBaseClient
          .collection('cancelledInvoice')
          .delete(cancelledInvoiceId);

      debugPrint('✅ Successfully deleted cancelled invoice');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete cancelled invoice: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete cancelled invoice: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
