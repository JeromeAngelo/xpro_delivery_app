import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import '../../../../../../../../enums/sync_status_enums.dart';

import '../../../../../../../../services/objectbox.dart';

abstract class DeliveryStatusChoicesLocalBase {
  final ObjectBoxStore objectBoxStore;

  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<DeliveryStatusChoicesModel> get deliveryStatusChoicesBox =>
      objectBoxStore.deliveryStatusBox;
  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;

  const DeliveryStatusChoicesLocalBase({required this.objectBoxStore});

  /// Removes null items and removes duplicates by PocketBase id.
  List<DeliveryStatusChoicesModel> sanitizeChoices(
    List<DeliveryStatusChoicesModel?> rawList,
  ) {
    final cleaned = <DeliveryStatusChoicesModel>[];

    final seenIds = <String>{};

    for (final item in rawList) {
      if (item == null) continue; // remove nulls
      if (item.id == null) continue; // must have PB id

      if (seenIds.contains(item.id)) {
        debugPrint('⚠️ Duplicate ignored → ${item.title} (${item.id})');
        continue;
      }

      seenIds.add(item.id!);
      cleaned.add(item);
    }

    debugPrint('🧹 Sanitized: ${cleaned.length} unique status choices kept.');
    return cleaned;
  }

  /// Fetch all DeliveryStatusChoices pending sync
  Future<List<DeliveryStatusChoicesModel>> getPendingStatusChoices() async {
    final query =
        deliveryStatusChoicesBox
            .query(
              DeliveryStatusChoicesModel_.syncStatus.equals(
                SyncStatus.pending.name,
              ),
            )
            .build();
    final pending = query.find();
    query.close();
    debugPrint('LOCAL 🔄 Pending sync count: ${pending.length}');
    return pending;
  }
}
