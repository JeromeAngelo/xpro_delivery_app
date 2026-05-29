import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/get_delivery_status_choices_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/sync_delivery_status_choices_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/update_delivery_status_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/complete_delivery_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/check_end_deliver_status_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/initialize_pending_status_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/get_bulk_delivery_status_choices_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/bulk_update_delivery_status_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/create_delivery_status_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/update_queue_remarks_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/pin_arrived_location_impl.dart';

abstract class DeliveryUpdateDatasource {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(String customerId);
  Future<List<DeliveryUpdateModel>> syncDeliveryStatusChoices(
    String customerId,
  );

  Future<void> updateDeliveryStatus(
    String deliveryDataId, // DeliveryData PB ID
    DeliveryStatusChoicesModel status, // ✅ FULL MODEL
  );
  Future<void> completeDelivery(DeliveryDataEntity deliveryData);
  Future<DataMap> checkEndDeliverStatus(String tripId);
  Future<void> initializePendingStatus(List<String> customerIds);
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
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
  Future<void> pinArrivedLocation(String deliveryId);
}

class DeliveryUpdateDatasourceImpl extends DeliveryUpdateRemoteBase
    with
        GetDeliveryStatusChoicesImpl,
        SyncDeliveryStatusChoicesImpl,
        UpdateDeliveryStatusImpl,
        CompleteDeliveryImpl,
        CheckEndDeliverStatusImpl,
        InitializePendingStatusImpl,
        GetBulkDeliveryStatusChoicesImpl,
        BulkUpdateDeliveryStatusImpl,
        CreateDeliveryStatusImpl,
        UpdateQueueRemarksImpl,
        PinArrivedLocationImpl
    implements DeliveryUpdateDatasource {
  DeliveryUpdateDatasourceImpl({required super.pocketBaseClient});
}
