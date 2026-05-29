import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/update_customer_status_impl.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin BulkUpdateDeliveryStatusImpl
    on DeliveryStatusChoicesLocalBase, UpdateCustomerStatusImpl {
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesModel statusChoice,
  ) async {
    try {
      debugPrint(
        'LOCAL 🔄 Bulk updating customers: $customerIds with status: ${statusChoice.title}',
      );

      if (statusChoice.id == null || statusChoice.id!.trim().isEmpty) {
        debugPrint('LOCAL ⚠️ Invalid status PB ID provided');
        return;
      }

      // ---------------------------------------------------
      // 🚀 OPTIMIZED BATCH CHECK: Get all updates in ONE query
      // ---------------------------------------------------
      final q =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.deliveryDataPbId.oneOf(customerIds))
              .build();
      final allUpdates = q.find();
      q.close();

      // Group by delivery ID for O(1) lookup
      final Map<String, List<DeliveryUpdateModel>> updatesByDelivery = {};
      for (final update in allUpdates) {
        final key = update.deliveryDataPbId ?? '';
        updatesByDelivery.putIfAbsent(key, () => []).add(update);
      }

      // ---------------------------------------------------
      // 🆕 DEDUPLICATION: Block if ANY update with this status exists
      // ---------------------------------------------------
      final customersToUpdate = <String>[];
      final skippedCustomers = <String>[];
      int skippedByDuplicate = 0;

      for (final customerId in customerIds) {
        final existingUpdates = updatesByDelivery[customerId] ?? [];

        // ✅ Block if ANY record exists with this status (prevents PB duplicates)
        final hasDuplicate = existingUpdates.any(
          (u) => u.statusChoicePbId == statusChoice.id,
        );

        if (hasDuplicate) {
          skippedByDuplicate++;
          debugPrint(
            '🚫 [DEDUP] Blocking $customerId — Status "${statusChoice.title}" already exists (any sync state)',
          );
          skippedCustomers.add(customerId);
        } else {
          customersToUpdate.add(customerId);
        }
      }

      debugPrint(
        'LOCAL 📊 Batch summary: ${customersToUpdate.length} to process | $skippedByDuplicate duplicates blocked',
      );

      // ✨ BATCH PROCESS: Update only new customers
      final stopwatch = Stopwatch()..start();
      int processedCount = 0;
      int failedCount = 0;

      for (final customerId in customersToUpdate) {
        try {
          await updateCustomerStatus(customerId, statusChoice);
          processedCount++;
        } catch (e, st) {
          failedCount++;
          debugPrint(
            'LOCAL ⚠️ Failed to queue update for $customerId: $e\n$st',
          );
        }
      }

      stopwatch.stop();

      debugPrint(
        '✅ Bulk completed in ${stopwatch.elapsedMilliseconds}ms: $processedCount queued, $failedCount failed, ${skippedCustomers.length} duplicates blocked',
      );
    } catch (e, st) {
      debugPrint('LOCAL ❌ Bulk enqueue failed: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
