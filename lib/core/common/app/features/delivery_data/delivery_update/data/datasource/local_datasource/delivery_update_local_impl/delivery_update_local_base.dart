import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../../services/objectbox.dart';

abstract class DeliveryUpdateLocalBase {
  final ObjectBoxStore objectBoxStore;

  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;
  Box<DeliveryStatusChoicesModel> get deliveryStatusChoicesBox =>
      objectBoxStore.deliveryStatusBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;

  DeliveryUpdateLocalBase(this.objectBoxStore);

  Future<void> autoSave(DeliveryUpdateModel update) async {
    try {
      if (update.title == null || update.id!.isEmpty) {
        debugPrint('⚠️ Skipping invalid delivery update');
        return;
      }

      debugPrint('🔍 Processing update: ${update.title} (ID: ${update.id})');

      final existingUpdate =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.id.equals(update.id ?? ''))
              .build()
              .findFirst();

      if (existingUpdate != null) {
        debugPrint('🔄 Updating existing status: ${update.title}');
        update.objectBoxId = existingUpdate.objectBoxId;
      } else {
        debugPrint('➕ Adding new status: ${update.title}');
      }

      deliveryUpdateBox.put(update);
      final totalUpdates = deliveryUpdateBox.count();
      debugPrint('📊 Current total valid updates: $totalUpdates');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  List<DeliveryUpdateModel> filterLocalStatusChoices(
    List<DeliveryStatusChoicesModel> allStatuses,
    List<String> allowedTitles,
    int deliveryDataObxId,
  ) {
    return allStatuses
        .where((status) => allowedTitles.contains(status.title!.toLowerCase()))
        .map((status) {
          debugPrint(
            'LOCAL 🟢 Allowed → ${status.title} collection ${status.collectionName}',
          );

          final update = DeliveryUpdateModel(
            title: status.title,
            subtitle: status.subtitle,
          );

          update.deliveryData.targetId = deliveryDataObxId;

          return update;
        })
        .toList();
  }
}
