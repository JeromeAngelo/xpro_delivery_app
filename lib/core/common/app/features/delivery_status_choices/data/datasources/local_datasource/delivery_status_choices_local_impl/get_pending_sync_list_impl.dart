import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import '../../../../../../../../enums/sync_status_enums.dart';

mixin GetPendingSyncListImpl on DeliveryStatusChoicesLocalBase {
  Future<List<DeliveryStatusChoicesModel>> getPendingSyncList() async {
    final all = deliveryStatusChoicesBox.getAll();
    return all
        .where(
          (s) =>
              s.syncStatus == SyncStatus.pending.name ||
              s.syncStatus == SyncStatus.failed.name,
        )
        .toList();
  }
}
