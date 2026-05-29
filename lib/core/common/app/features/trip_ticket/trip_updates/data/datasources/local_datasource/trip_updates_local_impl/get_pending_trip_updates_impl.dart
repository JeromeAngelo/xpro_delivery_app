import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';

mixin GetPendingTripUpdatesImpl on TripUpdateLocalBase {
  Future<List<TripUpdateModel>> getPendingTripUpdates() async {
    final query =
        tripUpdateBox
            .query(TripUpdateModel_.syncStatus.equals(SyncStatus.pending.name))
            .build();

    final pending = query.find();
    query.close();

    debugPrint('LOCAL 🔄 Pending TripUpdates sync count: ${pending.length}');
    return pending;
  }
}
