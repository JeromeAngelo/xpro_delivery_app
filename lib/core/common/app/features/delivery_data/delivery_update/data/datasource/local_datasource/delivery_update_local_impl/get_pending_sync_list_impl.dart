import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import '../../../../../../../../../enums/sync_status_enums.dart';

mixin GetPendingSyncListImpl on DeliveryUpdateLocalBase {
  Future<List<DeliveryUpdateModel>> getPendingSyncList() async {
    final query =
        deliveryUpdateBox
            .query(
              DeliveryUpdateModel_.syncStatus.equals(SyncStatus.pending.name),
            )
            .build();
    final pending = query.find();
    query.close();
    debugPrint('LOCAL 🔄 Pending sync count: ${pending.length}');
    return pending;
  }
}
