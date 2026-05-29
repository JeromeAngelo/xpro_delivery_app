import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin GetDeliveryStatusChoicesImpl on DeliveryUpdateLocalBase {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        'LOCAL 🔄 Fetching status choices for DeliveryData PB ID: $deliveryDataId',
      );

      final ddQuery =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataId))
              .build();

      final deliveryData = ddQuery.findFirst();
      ddQuery.close();

      if (deliveryData == null) {
        debugPrint('LOCAL ❌ DeliveryData not found locally');
        return [];
      }

      debugPrint(
        'LOCAL ✅ DeliveryData found → OBX ID: ${deliveryData.objectBoxId}',
      );

      final updates = <DeliveryUpdateModel>[];

      for (final u in deliveryData.deliveryUpdates) {
        final fullUpdate = deliveryUpdateBox.get(u.objectBoxId);
        if (fullUpdate != null) {
          updates.add(fullUpdate);
          debugPrint('    📝 ${fullUpdate.title} | time=${fullUpdate.time}');
        }
      }

      if (updates.isEmpty) {
        debugPrint('LOCAL ⚠️ No delivery updates found');
      }

      updates.sort((a, b) {
        final at = a.time ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.time ?? DateTime.fromMillisecondsSinceEpoch(0);
        return at.compareTo(bt);
      });

      final latestStatus =
          updates.isNotEmpty ? updates.last.title?.toLowerCase() ?? '' : '';

      debugPrint('LOCAL 📍 Latest status: "$latestStatus"');

      final allStatuses = deliveryStatusChoicesBox.getAll();

      if (allStatuses.isEmpty) {
        debugPrint('LOCAL ⚠️ No cached deliveryStatusChoices found');
        return [];
      }

      if (latestStatus == 'in transit') {
        return filterLocalStatusChoices(allStatuses, [
          'arrived',
          'mark as undelivered',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'waiting for customer') {
        return filterLocalStatusChoices(allStatuses, [
          'unloading',
          'mark as undelivered',
          'invoices in queue',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'invoices in queue') {
        return filterLocalStatusChoices(allStatuses, [
          'unloading',
          'mark as undelivered',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'unloading') {
        return filterLocalStatusChoices(allStatuses, [
          'mark as received',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'mark as received') {
        return filterLocalStatusChoices(allStatuses, [
          'end delivery',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'arrived') {
        return filterLocalStatusChoices(allStatuses, [
          'unloading',
          'mark as undelivered',
          'waiting for customer',
          'invoices in queue',
        ], deliveryData.objectBoxId);
      }

      if (latestStatus == 'mark as undelivered') return [];
      if (latestStatus == 'end delivery') return [];

      final assignedTitles =
          updates
              .where((u) => u.title != null)
              .map((u) => u.title!.toLowerCase())
              .toSet();

      final filtered =
          allStatuses
              .where((s) => !assignedTitles.contains(s.title!.toLowerCase()))
              .map((s) {
                final update = DeliveryUpdateModel(
                  title: s.title,
                  subtitle: s.subtitle,
                );
                update.deliveryData.target = deliveryData;
                return update;
              })
              .toList();

      debugPrint('LOCAL ✅ Final choices count: ${filtered.length}');
      return filtered;
    } catch (e, st) {
      debugPrint('LOCAL ❌ Error in getDeliveryStatusChoices: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
