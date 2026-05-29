import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';

mixin GetPendingSyncListImpl on CancelledInvoiceLocalBase {
  Future<List<CancelledInvoiceModel>> getPendingSyncList() async {
    final all = cancelledInvoiceBox.getAll();

    return all
        .where(
          (ci) =>
              ci.syncStatus == SyncStatus.pending.name ||
              ci.syncStatus == SyncStatus.failed.name,
        )
        .toList();
  }
}
