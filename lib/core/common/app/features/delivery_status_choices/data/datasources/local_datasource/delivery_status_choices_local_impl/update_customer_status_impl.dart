import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import '../../../../../../../../enums/sync_status_enums.dart';

mixin UpdateCustomerStatusImpl on DeliveryStatusChoicesLocalBase {
  Future<void> updateCustomerStatus(
    String deliveryDataPbId,
    DeliveryStatusChoicesModel statusChoice,
  ) async {
    try {
      debugPrint('🔵 START: updateDeliveryStatus()');
      debugPrint('   📌 DeliveryData PB ID: $deliveryDataPbId');
      debugPrint('   🏷️ Status: ${statusChoice.title} (${statusChoice.id})');

      // ---------------------------------------------------
      // 0️⃣ VALIDATE
      // ---------------------------------------------------
      if (statusChoice.id == null || statusChoice.id!.trim().isEmpty) {
        debugPrint('❌ Status PB ID is EMPTY → DATA INTEGRITY ISSUE');
        return;
      }

      // ---------------------------------------------------
      // 🆕 0️⃣-A DEDUPLICATION: Block if ANY update with this status exists
      // ---------------------------------------------------
      try {
        final duplicateQuery =
            deliveryUpdateBox
                .query(
                  DeliveryUpdateModel_.deliveryDataPbId.equals(
                    deliveryDataPbId,
                  ),
                )
                .build();
        final existingUpdates = duplicateQuery.find();
        duplicateQuery.close();

        // Block if ANY update with the SAME statusChoicePbId already exists
        for (final existing in existingUpdates) {
          if (existing.statusChoicePbId == statusChoice.id) {
            debugPrint(
              '🚫 DEDUP: Status "${statusChoice.title}" already exists for delivery $deliveryDataPbId (sync=${existing.syncStatus})',
            );
            debugPrint('   📋 Existing OBX ID: ${existing.objectBoxId}');
            debugPrint('   ✅ Skipping to prevent duplicate in PocketBase');
            return;
          }
        }
        debugPrint('✅ No duplicate found — proceeding with status update');
      } catch (e) {
        debugPrint('⚠️ Duplicate check failed (non-blocking): $e');
      }

      // ---------------------------------------------------
      // 1️⃣ Resolve DeliveryData locally
      // ---------------------------------------------------
      final deliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataPbId))
              .build()
              .findFirst();

      if (deliveryData == null) {
        debugPrint('❌ DeliveryData not found locally');
        return;
      }

      debugPrint('✅ DeliveryData resolved → OBX ID: ${deliveryData.id}');

      // ---------------------------------------------------
      // 2️⃣ CREATE NEW DeliveryUpdate (COPY DATA)
      // ---------------------------------------------------
      final now = DateTime.now();
      final adjustedTime = now.add(const Duration(seconds: 30));
      final newUpdate = DeliveryStatusChoicesModel(
        id: statusChoice.id,
        title: statusChoice.title,
        subtitle: statusChoice.subtitle,
        deliveryDataId: deliveryDataPbId,
        syncStatus: SyncStatus.pending.name,
        retryCount: 0,
        lastLocalUpdatedAt: adjustedTime,
      );

      // ---------------------------------------------------
      // 3️⃣ LINK RELATIONS (CRITICAL)
      // ---------------------------------------------------
      final deliveryUpdate = DeliveryUpdateModel(
        title: newUpdate.title,
        subtitle: newUpdate.subtitle,
        time: adjustedTime,
        isAssigned: true,
        id: '', // ⏳ will be set after remote sync
      );

      // Link the delivery update to the delivery data and mark as pending
      deliveryUpdate.deliveryData.target = deliveryData;
      deliveryUpdate.deliveryDataPbId = deliveryDataPbId;
      deliveryUpdate.statusChoicePbId = statusChoice.id;
      deliveryUpdate.syncStatus = SyncStatus.pending.name;
      deliveryUpdate.retryCount = 0;
      deliveryUpdate.customer = deliveryData.pocketbaseId;
      // Mark local last-updated timestamp so UI can prefer this update
      deliveryUpdate.lastLocalUpdatedAt = adjustedTime;

      // Add to the parent relation and persist
      deliveryData.deliveryUpdates.add(deliveryUpdate);

      // ---------------------------------------------------
      // 4️⃣ SAVE (child → parent)
      // ---------------------------------------------------
      final obxId = deliveryUpdateBox.put(deliveryUpdate);
      // Ensure the parent is aware of the child's persisted instance
      deliveryDataBox.put(deliveryData);

      // Optional: save statusChoice locally for offline sync
      deliveryStatusChoicesBox.put(newUpdate);

      debugPrint('✅ Local DeliveryUpdate CREATED');
      debugPrint('   • Update OBX ID: $obxId');
      debugPrint('   • Update PB ID: ${deliveryUpdate.id}');
      debugPrint('   • Title: ${deliveryUpdate.title}');
      debugPrint('   • Subtitle: ${deliveryUpdate.subtitle}');
      debugPrint('   • Time: ${deliveryUpdate.time}');
      debugPrint('   • Total updates: ${deliveryData.deliveryUpdates.length}');

      // ---------------------------------------------------
      // ✅ Verification: read back persisted deliveryData and child updates
      // ---------------------------------------------------
      try {
        final refreshed = deliveryDataBox.get(deliveryData.objectBoxId);
        if (refreshed == null) {
          debugPrint(
            '🔍 Verification: refreshed deliveryData NOT FOUND for OBX ID: ${deliveryData.objectBoxId}',
          );
        } else {
          debugPrint(
            '🔍 Verification: refreshed deliveryData OBX=${refreshed.objectBoxId} relationCount=${refreshed.deliveryUpdates.length}',
          );

          bool foundNew = false;

          // Directly fetch the saved update by obxId (more reliable than comparing times)
          try {
            final saved = deliveryUpdateBox.get(obxId);
            if (saved != null) {
              debugPrint(
                '   • saved update fetched by OBX=$obxId title=${saved.title} sync=${saved.syncStatus} lastLocal=${saved.lastLocalUpdatedAt} time=${saved.time}',
              );
              // Check if it's part of the refreshed relations
              for (final rel in refreshed.deliveryUpdates) {
                if (rel.objectBoxId == saved.objectBoxId) {
                  foundNew = true;
                  debugPrint(
                    '     ↳ This saved entry is present in refreshed relations (OBX=${saved.objectBoxId})',
                  );
                  break;
                }
              }
            } else {
              debugPrint(
                '   • saved update OBX=$obxId NOT found in deliveryUpdateBox',
              );
            }
          } catch (e, st) {
            debugPrint('   • error fetching saved update by obxId: $e\n$st');
          }

          // Also enumerate relations for visibility
          for (final rel in refreshed.deliveryUpdates) {
            final full = deliveryUpdateBox.get(rel.objectBoxId);
            if (full == null) {
              debugPrint(
                '   • relation entry OBX=${rel.objectBoxId} -> MISSING in box',
              );
              continue;
            }
            debugPrint(
              '   • persisted update OBX=${full.objectBoxId} title=${full.title} sync=${full.syncStatus} lastLocal=${full.lastLocalUpdatedAt} time=${full.time}',
            );
          }

          debugPrint(
            '🔍 Verification: newly created update present in refreshed relations? $foundNew',
          );
        }
      } catch (e, st) {
        debugPrint(
          '🔍 Verification: error while checking persisted relations: $e\n$st',
        );
      }
    } catch (e, st) {
      debugPrint('❌ ERROR in updateDeliveryStatus(): $e');
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }
}
