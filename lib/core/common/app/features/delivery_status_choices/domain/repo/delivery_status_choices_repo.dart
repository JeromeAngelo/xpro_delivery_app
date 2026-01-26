import '../../../../../../utils/typedefs.dart';
import '../../../trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import '../entity/delivery_status_choices_entity.dart';

abstract class DeliveryStatusChoicesRepo {
  const DeliveryStatusChoicesRepo();
  ResultFuture<List<DeliveryStatusChoicesEntity>>
  syncAllDeliveryStatusChoices();
  // ✅ Change here
  ResultFuture<List<DeliveryStatusChoicesEntity>>
  getAllAssignedDeliveryStatusChoices(String customerId);
  ResultFuture<void> updateDeliveryStatus(
    String deliveryDataId,
    DeliveryStatusChoicesEntity status,
  );

    ResultFuture<Map<String, List<DeliveryStatusChoicesEntity>>> getAllBulkDeliveryStatusChoices(List<String> customerIds);
 ResultFuture<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesEntity status,
  );

    ResultFuture<void> setEndDelivery(DeliveryDataEntity deliveryData);

}
