import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
abstract class DeliveryUpdateRepo {
  const DeliveryUpdateRepo();

  // Core delivery status operations
  ResultFuture<List<DeliveryUpdateEntity>> getDeliveryStatusChoices(String customerId);
  ResultFuture<List<DeliveryUpdateEntity>> getLocalDeliveryStatusChoices(String customerId);
  ResultFuture<void> updateDeliveryStatus(String customerId, String statusId);
  
  // Completion and initialization
   // Completion and initialization - Updated to use delivery data
  ResultFuture<void> completeDelivery(DeliveryDataEntity deliveryData);
  // Enhanced status check function
  ResultFuture<DataMap> checkEndDeliverStatus(String tripId);
  ResultFuture<DataMap> checkLocalEndDeliverStatus(String tripId);
  ResultFuture<void> initializePendingStatus(List<String> customerIds);
  ResultFuture<Map<String, List<DeliveryUpdateEntity>>> getBulkDeliveryStatusChoices(List<String> customerIds);

  
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
    String statusId, 
    String remarks,
    String image,
  );

  // Pin arrived location function
  ResultFuture<void> pinArrivedLocation(String deliveryId);

   // ✅ New bulk update function
  ResultFuture<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  );
}


