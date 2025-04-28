import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class InvoiceRepo {
  const InvoiceRepo();

  ResultFuture<List<InvoiceEntity>> getInvoices();
  ResultFuture<List<InvoiceEntity>> loadLocalInvoices();
  ResultFuture<List<InvoiceEntity>> getInvoicesByTripId(String tripId);
  ResultFuture<List<InvoiceEntity>> getInvoicesByCustomerId(String customerId);
  ResultFuture<List<InvoiceEntity>> loadLocalInvoicesByTripId(String tripId);
  ResultFuture<List<InvoiceEntity>> loadLocalInvoicesByCustomerId(String customerId);
  ResultFuture<List<InvoiceEntity>> setAllInvoicesCompleted(String tripId);
  ResultFuture<InvoiceEntity> setInvoiceUnloaded(String invoiceId);
}
