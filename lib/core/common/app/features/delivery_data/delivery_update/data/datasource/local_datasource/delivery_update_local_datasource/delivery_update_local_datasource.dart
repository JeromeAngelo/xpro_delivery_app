import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../delivery_update_local_impl/delivery_update_local_base.dart';
import '../delivery_update_local_impl/get_delivery_status_choices_impl.dart';
import '../delivery_update_local_impl/update_delivery_status_impl.dart';
import '../delivery_update_local_impl/complete_delivery_impl.dart';
import '../delivery_update_local_impl/get_bulk_delivery_status_choices_impl.dart';
import '../delivery_update_local_impl/save_delivery_status_choices_impl.dart';
import '../delivery_update_local_impl/save_delivery_update_choices_impl.dart';
import '../delivery_update_local_impl/bulk_update_delivery_status_impl.dart';
import '../delivery_update_local_impl/create_delivery_status_impl.dart';
import '../delivery_update_local_impl/update_queue_remarks_impl.dart';
import '../delivery_update_local_impl/check_end_deliver_status_impl.dart';
import '../delivery_update_local_impl/initialize_pending_status_impl.dart';
import '../delivery_update_local_impl/mark_syncing_impl.dart';
import '../delivery_update_local_impl/mark_synced_impl.dart';
import '../delivery_update_local_impl/mark_failed_impl.dart';
import '../delivery_update_local_impl/get_pending_sync_list_impl.dart';

abstract class DeliveryUpdateLocalDatasource {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(
    String deliveryDataId,
  );
  Future<void> updateDeliveryStatus(
    String deliveryDataPbId,
    DeliveryStatusChoicesModel statusChoice,
  );
  Future<void> completeDelivery(DeliveryDataEntity deliveryData);
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  );

  Future<void> saveDeliveryStatusChoices(
    String customerId,
    List<DeliveryUpdateModel> choices,
  );
  Future<void> saveDeliveryUpdateChoices(
    String customerId,
    List<DeliveryUpdateModel> updates,
  );
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  );
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  });
  Future<void> updateQueueRemarks(
    String statusId,
    String remarks,
    String image,
  );
  Future<DataMap> checkEndDeliverStatus(String tripId);
  Future<void> initializePendingStatus(List<String> customerIds);
  Box<DeliveryUpdateModel> get deliveryUpdateBox;

  /// Background sync helper methods
  Future<void> markSyncing(DeliveryUpdateModel status);
  Future<void> markSynced(DeliveryUpdateModel status);
  Future<void> markFailed(DeliveryUpdateModel status, String error);
  Future<List<DeliveryUpdateModel>> getPendingSyncList();
}

class DeliveryUpdateLocalDatasourceImpl extends DeliveryUpdateLocalBase
    with
        GetDeliveryStatusChoicesImpl,
        UpdateDeliveryStatusImpl,
        CompleteDeliveryImpl,
        GetBulkDeliveryStatusChoicesImpl,
        SaveDeliveryStatusChoicesImpl,
        SaveDeliveryUpdateChoicesImpl,
        BulkUpdateDeliveryStatusImpl,
        CreateDeliveryStatusImpl,
        UpdateQueueRemarksImpl,
        CheckEndDeliverStatusImpl,
        InitializePendingStatusImpl,
        MarkSyncingImpl,
        MarkSyncedImpl,
        MarkFailedImpl,
        GetPendingSyncListImpl
    implements DeliveryUpdateLocalDatasource {
  DeliveryUpdateLocalDatasourceImpl(super.objectBoxStore);
}
