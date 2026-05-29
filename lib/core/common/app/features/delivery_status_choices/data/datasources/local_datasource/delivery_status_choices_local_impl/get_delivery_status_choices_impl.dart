import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin GetDeliveryStatusChoicesImpl on DeliveryStatusChoicesLocalBase {
  Future<List<DeliveryStatusChoicesModel>> getDeliveryStatusChoices(
    String deliveryDataId,
  ) async {
    try {
      final ddId = deliveryDataId.trim();
      debugPrint(
        'LOCAL 🔄 Fetching status choices for DeliveryData PB ID: $ddId',
      );

      // ---------------------------------------------------
      // Helpers
      // ---------------------------------------------------
      String norm(dynamic v) {
        final s = (v ?? '').toString().trim().toLowerCase();
        if (s.isEmpty) return '';
        // collapse multi-spaces to single
        return s.replaceAll(RegExp(r'\s+'), ' ');
      }

      DateTime bestTime(DeliveryUpdateModel u) {
        return u.lastLocalUpdatedAt ??
            u.updated ??
            u.time ??
            u.created ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      // ---------------------------------------------------
      // 0️⃣ Resolve DeliveryData
      // ---------------------------------------------------
      final ddQuery =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(ddId))
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

      // ---------------------------------------------------
      // 1️⃣ Load DeliveryUpdates (current history)
      // ---------------------------------------------------
      final updates = <DeliveryUpdateModel>[];

      for (final rel in deliveryData.deliveryUpdates) {
        final full = deliveryUpdateBox.get(rel.objectBoxId);
        if (full != null) {
          updates.add(full);
          debugPrint(
            '    📝 ${full.title} | time=${full.time} | updated=${full.updated}',
          );
        }
      }

      // ---------------------------------------------------
      // 2️⃣ Determine latest status (robust)
      // ---------------------------------------------------
      updates.sort((a, b) {
        final at = bestTime(a);
        final bt = bestTime(b);
        final cmp = at.compareTo(bt);
        if (cmp != 0) return cmp;

        // tie-breaker to stabilize ordering
        return a.objectBoxId.compareTo(b.objectBoxId);
      });

      final latestStatus = updates.isNotEmpty ? norm(updates.last.title) : '';
      debugPrint('LOCAL 📍 Latest status: "$latestStatus"');

      // If no status yet, treat as "in transit" start (optional)
      final effectiveLatest =
          latestStatus.isEmpty ? 'in transit' : latestStatus;

      // ---------------------------------------------------
      // 3️⃣ Load cached DeliveryStatusChoices
      // ---------------------------------------------------
      final allStatuses = deliveryStatusChoicesBox.getAll();
      if (allStatuses.isEmpty) {
        debugPrint('LOCAL ⚠️ No cached deliveryStatusChoices found');
        return [];
      }

      // ---------------------------------------------------
      // 4️⃣ Determine allowed transitions (match your rules)
      // ---------------------------------------------------
      final allowedTitles = <String>[];

      switch (effectiveLatest) {
        case 'in transit':
          allowedTitles.addAll(['arrived', 'mark as undelivered']);
          break;

        case 'arrived':
          allowedTitles.addAll([
            'unloading',
            'mark as undelivered',
            'waiting for customer',
            'invoices in queue',
          ]);
          break;

        case 'waiting for customer':
          allowedTitles.addAll([
            'unloading',
            'mark as undelivered',
            'invoices in queue',
          ]);
          break;

        case 'invoices in queue':
          allowedTitles.addAll(['unloading', 'mark as undelivered']);
          break;
        case 'unloading':
          allowedTitles.addAll(['mark as received']);
          break;
        case 'mark as received':
          allowedTitles.addAll(['end delivery']);
          break;
        case 'mark as undelivered':
        case 'end delivery':
          return [];

        default:
          debugPrint(
            'LOCAL ⚠️ Unknown latest status "$effectiveLatest" - using safe fallback',
          );
          allowedTitles.addAll(['mark as undelivered']);
          break;
      }

      // ---------------------------------------------------
      // ✅ FIX 5️⃣ Exclude only CURRENT status (not full history)
      // ---------------------------------------------------
      final blockedTitles = <String>{};
      if (effectiveLatest.isNotEmpty) blockedTitles.add(effectiveLatest);

      // ---------------------------------------------------
      // 6️⃣ FILTER + DEDUP
      // ---------------------------------------------------
      final Map<String, DeliveryStatusChoicesModel> unique = {};

      for (final status in allStatuses) {
        if (status.id == null || status.title == null) continue;

        final titleLower = norm(status.title);

        if (!allowedTitles.contains(titleLower)) continue;
        if (blockedTitles.contains(titleLower)) continue;

        // Dedup by PB id
        if (unique.containsKey(status.id)) {
          debugPrint('⚠️ Duplicate filtered out → ${status.title}');
          continue;
        }

        debugPrint(
          'LOCAL 🟢 Allowed → ${status.title} (${status.collectionName})',
        );

        unique[status.id!] = DeliveryStatusChoicesModel(
          id: status.id,
          title: status.title,
          subtitle: status.subtitle,
          collectionId: status.collectionId,
          collectionName: status.collectionName,
        );
      }

      // Optional: keep same order as allowedTitles list
      final result =
          unique.values.toList()..sort((a, b) {
            final ia = allowedTitles.indexOf(norm(a.title));
            final ib = allowedTitles.indexOf(norm(b.title));
            return ia.compareTo(ib);
          });

      debugPrint('LOCAL ✅ Final choices count: ${result.length}');
      return result;
    } catch (e, st) {
      debugPrint('LOCAL ❌ Error in getDeliveryStatusChoices: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
