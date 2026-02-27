import '../../../../../../typedefs/typedefs.dart';
import '../entity/invoice_status_entity.dart';

  abstract class InvoiceStatusRepo {
    const InvoiceStatusRepo();


    ResultFuture<List<InvoiceStatusEntity>> getAllInvoiceStatuses();
    ResultFuture<InvoiceStatusEntity> getInvoiceStatusById(String id);
   // ResultFuture<void> deleteInvoiceStatus(String id);

    // Future<void> addInvoiceStatus(InvoiceStatusEntity invoiceStatus);
  //  ResultFuture<void> updateInvoiceStatus(InvoiceStatusEntity invoiceStatus);
    // ✅ Exporters
  ResultFuture<List<int>> exportInvoiceStatusesCsvBytes();
  ResultFuture<List<int>> exportInvoiceStatusesExcelBytes();
  }