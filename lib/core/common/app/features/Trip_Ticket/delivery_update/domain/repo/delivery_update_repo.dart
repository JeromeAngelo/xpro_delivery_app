import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
abstract class DeliveryUpdateRepo {
  const DeliveryUpdateRepo();

  // Core delivery status operations
  ResultFuture<List<DeliveryUpdateEntity>> getDeliveryStatusChoices(String customerId);
  ResultFuture<List<DeliveryUpdateEntity>> getLocalDeliveryStatusChoices(String customerId);
  ResultFuture<void> updateDeliveryStatus(String customerId, String statusId);
  
  // Completion and initialization
  ResultFuture<void> completeDelivery(String customerId, {
    required List<InvoiceModel> invoices,
    required List<TransactionModel> transactions,
    required List<ReturnModel> returns,
    required List<DeliveryUpdateModel> deliveryStatus,
  });
  // Enhanced status check function
  ResultFuture<DataMap> checkEndDeliverStatus(String tripId);
  ResultFuture<DataMap> checkLocalEndDeliverStatus(String tripId);
  ResultFuture<void> initializePendingStatus(List<String> customerIds);
  
  // Status creation
  ResultFuture<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  });

   // Add this new function
  ResultFuture<void> updateQueueRemarks(
    String customerId, 
    String queueCount,
  );
}


