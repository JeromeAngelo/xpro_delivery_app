import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkFailedImpl on CancelledInvoiceLocalBase {
  Future<void> markFailed(
    CancelledInvoiceModel cancelledInvoice,
    String error,
  ) async {
    final retryCount = (cancelledInvoice.retryCount) + 1;

    final updated = cancelledInvoice.copyWith(
      syncStatus: SyncStatus.pending.name,
      retryCount: retryCount,
      lastSyncError: error,
      nextRetryAt: DateTime.now().add(
        Duration(seconds: 2 * retryCount * 2), // exponential backoff
      ),
    );

    cancelledInvoiceBox.put(updated);

    debugPrint(
      'LOCAL ⚠️ CancelledInvoice sync failed → '
      'id=${cancelledInvoice.id}, retryCount=$retryCount',
    );
  }
}
