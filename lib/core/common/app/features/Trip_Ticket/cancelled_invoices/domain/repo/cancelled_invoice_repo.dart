import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';


abstract class CancelledInvoiceRepo {
  const CancelledInvoiceRepo();

  /// Load cancelled invoices by trip ID from remote
  ResultFuture<List<CancelledInvoiceEntity>> loadCancelledInvoicesByTripId(String tripId);

  /// Load cancelled invoices by trip ID from local storage
  ResultFuture<List<CancelledInvoiceEntity>> loadLocalCancelledInvoicesByTripId(String tripId);

    ResultFuture<CancelledInvoiceEntity> loadCancelledInvoicesById(String id);

    ResultFuture<CancelledInvoiceEntity> loadLocalCancelledInvoicesById(String id);


 /// Create cancelled invoice
  ResultFuture<CancelledInvoiceEntity> createCancelledInvoice(
    CancelledInvoiceEntity cancelledInvoice,
    String deliveryDataId,
  );


  /// Delete cancelled invoice
  ResultFuture<bool> deleteCancelledInvoice(String cancelledInvoiceId);
}
