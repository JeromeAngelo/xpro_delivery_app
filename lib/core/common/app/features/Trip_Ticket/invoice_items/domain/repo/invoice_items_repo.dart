

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class InvoiceItemsRepo {
  const InvoiceItemsRepo();

  // Get invoice items by invoice data ID
  ResultFuture<List<InvoiceItemsEntity>> getInvoiceItemsByInvoiceDataId(String invoiceDataId);

    ResultFuture<List<InvoiceItemsEntity>> getLocalInvoiceItemsByInvoiceDataId(String invoiceDataId);

  // Get all invoice items
  ResultFuture<List<InvoiceItemsEntity>> getAllInvoiceItems();

    ResultFuture<List<InvoiceItemsEntity>> getAllLocalInvoiceItems();

  
  // Update invoice item by ID
  ResultFuture<InvoiceItemsEntity> updateInvoiceItemById(InvoiceItemsEntity invoiceItem);
}
