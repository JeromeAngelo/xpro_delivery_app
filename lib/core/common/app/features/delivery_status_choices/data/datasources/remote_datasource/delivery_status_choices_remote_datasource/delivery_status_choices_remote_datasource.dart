import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import '../delivery_status_choices_remote_impl/delivery_status_choices_remote_base.dart';
import '../delivery_status_choices_remote_impl/sync_all_delivery_status_choices_impl.dart';
import '../delivery_status_choices_remote_impl/get_all_assigned_delivery_status_choices_impl.dart';
import '../delivery_status_choices_remote_impl/update_customer_status_impl.dart';
import '../delivery_status_choices_remote_impl/revert_update_customer_status_impl.dart';
import '../delivery_status_choices_remote_impl/get_all_bulk_delivery_status_choices_impl.dart';
import '../delivery_status_choices_remote_impl/bulk_update_delivery_status_impl.dart';
import '../delivery_status_choices_remote_impl/set_end_delivery_impl.dart';

abstract class DeliveryStatusChoicesRemoteDataSource {
  Future<List<DeliveryStatusChoicesModel>> syncAllDeliveryStatusChoices();
  Future<List<DeliveryStatusChoicesModel>> getAllAssignedDeliveryStatusChoices(
    String customerId,
  );
  Future<void> setEndDelivery(DeliveryDataEntity deliveryData);

  Future<String> updateCustomerStatus(
    String deliveryDataId, // DeliveryData PB ID
    DeliveryStatusChoicesModel status, // ✅ FULL MODEL
  );

  Future<String> revertUpdateCustomerStatus(
    String deliveryDataId, // DeliveryData PB ID
    DeliveryStatusChoicesModel status, // ✅ FULL MODEL
  );

  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds);
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesModel statusId,
  );
}

class DeliveryStatusChoicesRemoteDataSourceImpl
    extends DeliveryStatusChoicesRemoteBase
    with
        SyncAllDeliveryStatusChoicesImpl,
        GetAllAssignedDeliveryStatusChoicesImpl,
        UpdateCustomerStatusImpl,
        RevertUpdateCustomerStatusImpl,
        GetAllBulkDeliveryStatusChoicesImpl,
        BulkUpdateDeliveryStatusImpl,
        SetEndDeliveryImpl
    implements DeliveryStatusChoicesRemoteDataSource {
  const DeliveryStatusChoicesRemoteDataSourceImpl(super.pocketBaseClient);
}
