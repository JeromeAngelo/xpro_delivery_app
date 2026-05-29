import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';

mixin MarkSyncingImpl on CancelledInvoiceLocalBase {
  Future<void> markSyncing(CancelledInvoiceModel cancelledInvoice) async {
    final updated = cancelledInvoice.copyWith(
      syncStatus: SyncStatus.syncing.name,
      lastSyncAttemptAt: DateTime.now(),
    );

    cancelledInvoiceBox.put(updated);

    debugPrint('LOCAL 🔄 CancelledInvoice syncing → id=${cancelledInvoice.id}');
  }
}
