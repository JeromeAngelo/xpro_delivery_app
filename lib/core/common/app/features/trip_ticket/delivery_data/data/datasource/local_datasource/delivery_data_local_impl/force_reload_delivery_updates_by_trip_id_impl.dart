import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin ForceReloadDeliveryUpdatesByTripIdImpl on DeliveryDataLocalBase {
  Future<List<DeliveryDataModel>> forceReloadDeliveryUpdatesByTripId(
    String tripId,
  ) async {
    try {
      final tid = tripId.trim();
      debugPrint('⚡ LOCAL: Force reloading delivery updates for tripId=$tid');
      final sw = Stopwatch()..start();

      // 1️⃣ Load deliveries for the trip
      final deliveries = await getDeliveryDataByTripId(tid);

      if (deliveries.isEmpty) {
        debugPrint('🔁 LOCAL: No deliveries found for tripId=$tid');
        return [];
      }

      // 2️⃣ BATCH QUERY: Get all updates for all deliveries in one go
      final deliveryPbIds =
          deliveries
              .map((d) => (d.pocketbaseId).trim())
              .where((id) => id.isNotEmpty)
              .toList();

      if (deliveryPbIds.isEmpty) {
        debugPrint('⚠️ LOCAL: No valid delivery PB IDs found');
        return deliveries;
      }

      // 🚀 Build efficient query for all deliveries at once
      final updatesMap = <String, List<DeliveryUpdateModel>>{};
      for (final pbId in deliveryPbIds) {
        final q =
            deliveryUpdateBox
                .query(DeliveryUpdateModel_.deliveryDataPbId.equals(pbId))
                .build();
        final found = q.find();
        q.close();
        if (found.isNotEmpty) {
          updatesMap[pbId] = found;
        }
      }

      // 3️⃣ BATCH PERSIST: Collect changes before writing to DB
      final toUpdate = <DeliveryDataModel>[];

      for (final delivery in deliveries) {
        final deliveryPbId = (delivery.pocketbaseId).trim();

        if (deliveryPbId.isEmpty || !updatesMap.containsKey(deliveryPbId)) {
          continue;
        }

        final found = updatesMap[deliveryPbId]!;

        // ✨ OPTIMIZED: Inline sort + dedup without intermediate collections
        if (found.isEmpty) {
          if (delivery.deliveryUpdates.isNotEmpty) {
            delivery.deliveryUpdates.clear();
            toUpdate.add(delivery);
          }
          continue;
        }

        // Sort updates efficiently (in-place with already-loaded data)
        found.sort((a, b) {
          final ta = a.lastLocalUpdatedAt ?? a.updated ?? a.time;
          final tb = b.lastLocalUpdatedAt ?? b.updated ?? b.time;
          if (ta == null && tb == null) return 0;
          if (ta == null) return -1;
          if (tb == null) return 1;
          return ta.compareTo(tb);
        });

        // Deduplicate without creating intermediate lists
        final dedupFound = deduplicateDeliveryUpdates(found);

        // ⚡ FAST COMPARISON: Use set-based comparison instead of list sorting
        bool needsUpdate = false;
        if (delivery.deliveryUpdates.length != dedupFound.length) {
          needsUpdate = true;
        } else {
          // Only compare if lengths match
          final currentIdSet =
              delivery.deliveryUpdates.map((e) => e.objectBoxId).toSet();
          final foundIdSet = dedupFound.map((e) => e.objectBoxId).toSet();
          needsUpdate = currentIdSet != foundIdSet;
        }

        if (needsUpdate) {
          delivery.deliveryUpdates
            ..clear()
            ..addAll(dedupFound);
          toUpdate.add(delivery);
        }
      }

      // 🚀 BATCH WRITE: Single database operation for all updates
      if (toUpdate.isNotEmpty) {
        deliveryDataBox.putMany(toUpdate);
        sw.stop();
        debugPrint(
          '⚡ LOCAL: Batch updated ${toUpdate.length} deliveries in ${sw.elapsedMilliseconds}ms',
        );
      } else {
        sw.stop();
        debugPrint(
          '✅ LOCAL: All delivery updates already up-to-date (${deliveries.length} checked)',
        );
      }

      return deliveries;
    } catch (e, st) {
      debugPrint('❌ forceReloadDeliveryUpdatesByTripId ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
