

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class InvoiceDataRepo {
  const InvoiceDataRepo();

  // Get all invoice data
  ResultFuture<List<InvoiceDataEntity>> getAllInvoiceData();
  
  // Get invoice data by ID
  ResultFuture<InvoiceDataEntity> getInvoiceDataById(String id);
  
  // Get invoice data by delivery ID
  ResultFuture<List<InvoiceDataEntity>> getInvoiceDataByDeliveryId(String deliveryId);

   
  // Get invoice data by customer ID
  ResultFuture<List<InvoiceDataEntity>> getInvoiceDataByCustomerId(String customerId);
  
  // Add invoice data to delivery
  ResultFuture<bool> addInvoiceDataToDelivery({
    required String invoiceId,
    required String deliveryId,
  });

    // Add invoice data to invoice status
  ResultFuture<bool> addInvoiceDataToInvoiceStatus({
    required String invoiceId,
    required String invoiceStatusId,
  });
}
