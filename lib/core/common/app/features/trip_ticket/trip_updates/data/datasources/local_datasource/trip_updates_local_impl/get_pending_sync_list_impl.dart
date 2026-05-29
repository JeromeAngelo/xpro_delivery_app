import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';

mixin GetPendingSyncListImpl on TripUpdateLocalBase {
  Future<List<TripUpdateModel>> getPendingSyncList() async {
    final all = tripUpdateBox.getAll();
    return all
        .where(
          (u) =>
              u.syncStatus == SyncStatus.pending.name ||
              u.syncStatus == SyncStatus.failed.name,
        )
        .toList();
  }
}
