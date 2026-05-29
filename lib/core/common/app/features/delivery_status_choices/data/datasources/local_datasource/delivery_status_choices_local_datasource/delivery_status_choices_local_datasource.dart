import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import '../delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import '../delivery_status_choices_local_impl/update_customer_status_impl.dart';
import '../delivery_status_choices_local_impl/get_delivery_status_choices_impl.dart';
import '../delivery_status_choices_local_impl/get_all_bulk_delivery_status_choices_impl.dart';
import '../delivery_status_choices_local_impl/bulk_update_delivery_status_impl.dart';
import '../delivery_status_choices_local_impl/save_all_delivery_status_choices_impl.dart';
import '../delivery_status_choices_local_impl/set_end_delivery_impl.dart';
import '../delivery_status_choices_local_impl/revert_update_customer_status_impl.dart';
import '../delivery_status_choices_local_impl/mark_syncing_impl.dart';
import '../delivery_status_choices_local_impl/mark_synced_impl.dart';
import '../delivery_status_choices_local_impl/mark_failed_impl.dart';
import '../delivery_status_choices_local_impl/get_pending_sync_list_impl.dart';

abstract class DeliveryStatusChoicesLocalDatasource {
  /// Gets the delivery status choices from the local storage.
  Future<void> saveAllDeliveryStatusChoices(
    List<DeliveryStatusChoicesModel?> rawChoices,
  );

  Future<List<DeliveryStatusChoicesModel>> getDeliveryStatusChoices(
    String deliveryDataId, // ✅ PocketBase ID
  );

  Future<void> updateCustomerStatus(
    String deliveryDataPbId, // DeliveryData PB ID
    DeliveryStatusChoicesModel statusChoice, // ✅ FULL STATUS MODEL
  );

  Future<void> revertUpdateCustomerStatus(
    String deliveryDataPbId, // DeliveryData PB ID
    DeliveryStatusChoicesModel statusChoice, // ✅ FULL STATUS MODEL
  );
  Future<void> setEndDelivery(DeliveryDataEntity deliveryData);

  /// Bulk versions for offline use

  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds);

  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesModel statusChoice,
  );

  /// 🆕 Expose ObjectBox box for sync worker purposes
  Box<DeliveryStatusChoicesModel> get deliveryStatusChoicesBox;

  /// 🆕 Background sync helper methods
  Future<void> markSyncing(DeliveryStatusChoicesModel status);
  Future<void> markSynced(DeliveryStatusChoicesModel status);
  Future<void> markFailed(DeliveryStatusChoicesModel status, String error);
  Future<List<DeliveryStatusChoicesModel>> getPendingSyncList();
}

class DeliveryStatusChoicesLocalDatasourceImpl
    extends DeliveryStatusChoicesLocalBase
    with
        UpdateCustomerStatusImpl,
        GetDeliveryStatusChoicesImpl,
        GetAllBulkDeliveryStatusChoicesImpl,
        BulkUpdateDeliveryStatusImpl,
        SaveAllDeliveryStatusChoicesImpl,
        SetEndDeliveryImpl,
        RevertUpdateCustomerStatusImpl,
        MarkSyncingImpl,
        MarkSyncedImpl,
        MarkFailedImpl,
        GetPendingSyncListImpl
    implements DeliveryStatusChoicesLocalDatasource {
  const DeliveryStatusChoicesLocalDatasourceImpl({required super.objectBoxStore});
}
