import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin UpdateCancelledInvoiceImpl on CancelledInvoiceLocalBase {
  Future<void> updateCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
  ) async {
    try {
      debugPrint(
        '📱 LOCAL: Updating cancelled invoice: ${cancelledInvoice.id}',
      );

      // Ensure tripId and deliveryDataId are set if relations are assigned
      if (cancelledInvoice.trip.target != null) {
        cancelledInvoice.tripId = cancelledInvoice.trip.target?.pocketbaseId;
      }
      if (cancelledInvoice.deliveryData.target != null) {
        cancelledInvoice.deliveryData.target?.pocketbaseId;
      }

      cancelledInvoiceBox.put(cancelledInvoice);
      debugPrint('✅ LOCAL: Cancelled invoice updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
