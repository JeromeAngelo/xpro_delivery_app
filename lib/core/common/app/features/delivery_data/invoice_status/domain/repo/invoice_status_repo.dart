import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_status/domain/entity/invoice_status_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class InvoiceStatusRepo {
  const InvoiceStatusRepo();

  // Get invoice status by invoice ID
  ResultFuture<List<InvoiceStatusEntity>> getInvoiceStatusByInvoiceId(String invoiceId);
}
