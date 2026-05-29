import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin GetAllBulkDeliveryStatusChoicesImpl on DeliveryStatusChoicesLocalBase {
  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds) async {
    final Map<String, List<DeliveryStatusChoicesModel>> result = {};

    try {
      debugPrint(
        'LOCAL 🔄 Bulk fetching status choices for customers: $customerIds',
      );

      // ---------------------------------------------------
      // Helpers
      // ---------------------------------------------------
      String norm(dynamic v) {
        final s = (v ?? '').toString().trim().toLowerCase();
        if (s.isEmpty) return '';
        return s.replaceAll(RegExp(r'\s+'), ' ');
      }

      DateTime bestTime(DeliveryUpdateModel u) {
        return u.lastLocalUpdatedAt ??
            u.updated ??
            u.time ??
            u.created ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      // Load cached choices once
      final allStatuses = deliveryStatusChoicesBox.getAll();
      if (allStatuses.isEmpty) {
        debugPrint('LOCAL ⚠️ No cached deliveryStatusChoices found (bulk)');
        for (final id in customerIds) {
          result[id] = [];
        }
        return result;
      }

      for (final rawCustomerId in customerIds) {
        final customerId = rawCustomerId.trim();

        try {
          debugPrint('LOCAL 🔄 Bulk: resolving DeliveryData for $customerId');

          // ---------------------------------------------------
          // 0️⃣ Resolve DeliveryData
          // ---------------------------------------------------
          final ddQuery =
              deliveryDataBox
                  .query(DeliveryDataModel_.pocketbaseId.equals(customerId))
                  .build();
          final deliveryData = ddQuery.findFirst();
          ddQuery.close();

          if (deliveryData == null) {
            debugPrint('LOCAL ⚠️ DeliveryData not found for $customerId');
            result[customerId] = [];
            continue;
          }

          // ---------------------------------------------------
          // 1️⃣ Load DeliveryUpdates
          // ---------------------------------------------------
          final updates = <DeliveryUpdateModel>[];
          for (final rel in deliveryData.deliveryUpdates) {
            final full = deliveryUpdateBox.get(rel.objectBoxId);
            if (full != null) updates.add(full);
          }

          // ---------------------------------------------------
          // 2️⃣ Determine latest status (robust)
          // ---------------------------------------------------
          updates.sort((a, b) {
            final at = bestTime(a);
            final bt = bestTime(b);
            final cmp = at.compareTo(bt);
            if (cmp != 0) return cmp;
            return a.objectBoxId.compareTo(b.objectBoxId);
          });

          final latestStatus =
              updates.isNotEmpty ? norm(updates.last.title) : '';
          final effectiveLatest =
              latestStatus.isEmpty ? 'in transit' : latestStatus;

          debugPrint(
            'LOCAL 📍 Bulk: latest status for $customerId = "$effectiveLatest"',
          );

          // ---------------------------------------------------
          // 3️⃣ Determine allowed transitions (MATCH single function)
          // ---------------------------------------------------
          final allowedTitles = <String>[];

          switch (effectiveLatest) {
            case 'in transit':
              allowedTitles.addAll(['arrived']);
              break;

            case 'arrived':
              allowedTitles.addAll([
                'unloading',
                'waiting for customer',
                'invoices in queue',
              ]);
              break;

            case 'waiting for customer':
              allowedTitles.addAll(['unloading', 'invoices in queue']);
              break;

            case 'invoices in queue':
              allowedTitles.addAll(['unloading']);
              break;

            case 'unloading':
              allowedTitles.addAll(['']);
              break;
            case 'mark as received':
              allowedTitles.addAll(['']);
              break;
            case 'mark as undelivered':
            case 'end delivery':
              result[customerId] = [];
              continue;

            default:
              debugPrint(
                'LOCAL ⚠️ Bulk: unknown status "$effectiveLatest" for $customerId',
              );
              allowedTitles.addAll(['mark as undelivered']);
              break;
          }

          // ---------------------------------------------------
          // ✅ FIX: Block only CURRENT status (not full history)
          // ---------------------------------------------------
          final blockedTitles = <String>{};
          if (effectiveLatest.isNotEmpty) blockedTitles.add(effectiveLatest);

          // ---------------------------------------------------
          // 4️⃣ Filter + dedup
          // ---------------------------------------------------
          final Map<String, DeliveryStatusChoicesModel> unique = {};

          for (final status in allStatuses) {
            if (status.id == null || status.title == null) continue;

            final titleLower = norm(status.title);

            if (!allowedTitles.contains(titleLower)) continue;
            if (blockedTitles.contains(titleLower)) continue;

            if (unique.containsKey(status.id)) continue;

            unique[status.id!] = DeliveryStatusChoicesModel(
              id: status.id,
              title: status.title,
              subtitle: status.subtitle,
              collectionId: status.collectionId,
              collectionName: status.collectionName,
            );
          }

          // Keep order same as allowedTitles
          final out =
              unique.values.toList()..sort((a, b) {
                final ia = allowedTitles.indexOf(norm(a.title));
                final ib = allowedTitles.indexOf(norm(b.title));
                return ia.compareTo(ib);
              });

          result[customerId] = out;

          debugPrint(
            'LOCAL ✅ Bulk: prepared ${out.length} choices for $customerId',
          );
        } catch (e, st) {
          debugPrint('LOCAL ❌ Bulk: failed for $customerId: $e\n$st');
          result[customerId] = [];
        }
      }

      return result;
    } catch (e, st) {
      debugPrint('LOCAL ❌ Error in bulk fetch: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
