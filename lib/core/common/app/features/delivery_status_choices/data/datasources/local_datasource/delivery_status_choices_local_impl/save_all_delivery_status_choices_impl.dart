import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin SaveAllDeliveryStatusChoicesImpl on DeliveryStatusChoicesLocalBase {
  Future<void> saveAllDeliveryStatusChoices(
    List<DeliveryStatusChoicesModel?> rawChoices,
  ) async {
    try {
      debugPrint('💽 [LOCAL SAVE] Saving Delivery Status Choices...');

      // ---------------------------------------------------
      // 0️⃣ CLEAN INPUT (nulls + duplicates from API)
      // ---------------------------------------------------
      final incomingChoices = sanitizeChoices(rawChoices);

      // ---------------------------------------------------
      // 1️⃣ REMOVE DUPLICATES ALREADY IN OBJECTBOX
      // ---------------------------------------------------
      final allLocal = deliveryStatusChoicesBox.getAll();
      final Map<String, List<DeliveryStatusChoicesModel>> grouped = {};

      for (final item in allLocal) {
        if (item.id == null) continue;
        grouped.putIfAbsent(item.id!, () => []).add(item);
      }

      for (final entry in grouped.entries) {
        if (entry.value.length > 1) {
          debugPrint(
            '🧨 Removing ${entry.value.length - 1} duplicate(s) for PB ID: ${entry.key}',
          );

          // Keep the first, remove the rest
          final duplicates = entry.value.skip(1);
          for (final dup in duplicates) {
            deliveryStatusChoicesBox.remove(dup.objectBoxId);
            debugPrint('🗑️ Removed duplicate OBX ID: ${dup.objectBoxId}');
          }
        }
      }

      // ---------------------------------------------------
      // 2️⃣ UPSERT CLEAN CHOICES
      // ---------------------------------------------------
      final Map<String, DeliveryStatusChoicesModel> uniqueMap = {};

      for (final choice in incomingChoices) {
        debugPrint(
          '📌 Saving StatusChoice → ${choice.title} | PB: ${choice.id}',
        );

        final existing =
            deliveryStatusChoicesBox
                .query(DeliveryStatusChoicesModel_.id.equals(choice.id!))
                .build()
                .findFirst();

        DeliveryStatusChoicesModel fresh;

        if (existing != null) {
          debugPrint(
            '🔁 Existing found → updating OBX: ${existing.objectBoxId}',
          );

          fresh = deliveryStatusChoicesBox.get(existing.objectBoxId)!;

          fresh
            ..id = choice.id
            ..collectionName = choice.collectionName
            ..title = choice.title
            ..subtitle = choice.subtitle
            ..created = choice.created
            ..updated = choice.updated;
        } else {
          debugPrint('➕ Creating new deliveryStatusChoice → PB: ${choice.id}');

          fresh =
              DeliveryStatusChoicesModel()
                ..id = choice.id
                ..title = choice.title
                ..subtitle = choice.subtitle
                ..collectionName = choice.collectionName
                ..created = choice.created
                ..updated = choice.updated;
        }

        final obxId = deliveryStatusChoicesBox.put(fresh);
        uniqueMap[fresh.id!] = deliveryStatusChoicesBox.get(obxId)!;

        debugPrint('   ✔ Saved OBX: $obxId → ${fresh.title}');
      }

      debugPrint(
        '✅ [LOCAL SAVE COMPLETE] ${uniqueMap.length} UNIQUE status choices saved.',
      );
    } catch (e, st) {
      debugPrint(
        '❌ [LOCAL SAVE ERROR] Failed to save delivery status choices: $e',
      );
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }
}
