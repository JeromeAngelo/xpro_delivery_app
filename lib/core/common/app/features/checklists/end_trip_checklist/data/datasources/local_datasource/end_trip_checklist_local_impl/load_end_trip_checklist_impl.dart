import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadEndTripChecklistImpl on EndTripChecklistLocalBase {
  Future<List<EndTripChecklistModel>> loadEndTripChecklist(
    String tripId,
  ) async {
    try {
      final tid = tripId.trim();
      debugPrint("📥 LOCAL loadEndTripChecklist() tripId = $tid");

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tid)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint("⚠️ Trip not found in local DB for tripId: $tid");
        return [];
      }

      // Make sure relation is loaded (optional but helps with lazy ToMany)
      // trip.endTripChecklist.load();

      // -------------------------------------------------------------
      // 2️⃣ Get EndTripChecklist linked to this trip (via relation)
      // -------------------------------------------------------------
      final checklistSet = <String, EndTripChecklistModel>{}; // dedupe by PB id

      for (final c in trip.endTripChecklist) {
        // ✅ ObjectBox persisted ID
        final obxId = c.objectBoxId; // <-- use @Id() field

        if (obxId == 0) {
          debugPrint(
            "⚠️ Skipping endTripChecklist item because OBX id is 0 "
            "(not persisted). PB id=${c.id}",
          );
          continue;
        }

        final fullChecklist = endTripChecklistBox.get(obxId);
        if (fullChecklist == null) continue;

        final key =
            (fullChecklist.id ?? '').trim(); // PB id string (your "id" field)
        if (key.isEmpty) continue;

        checklistSet[key] = fullChecklist;
      }

      if (checklistSet.isEmpty) {
        debugPrint("⚠️ No end-trip checklist found for trip: ${trip.name}");
        return [];
      }

      final output = <EndTripChecklistModel>[];

      // -------------------------------------------------------------
      // 3️⃣ Load relations safely
      // -------------------------------------------------------------
      for (final checklist in checklistSet.values) {
        debugPrint(
          "📄 Loading relations for EndTripChecklist → ${checklist.id}",
        );

        // 🚚 Trip relation
        final t = checklist.trip.target;
        if (t != null) {
          final tripObxId = t.objectBoxId;

          if (tripObxId != 0) {
            final fullTrip = tripBox.get(tripObxId);
            if (fullTrip != null) {
              checklist.trip.target = fullTrip;
              checklist.trip.targetId = fullTrip.objectBoxId;
              debugPrint("🚚 Trip loaded → ${fullTrip.name}");
            }
          } else {
            // If relation target exists but isn't persisted
            debugPrint(
              "⚠️ Trip relation exists but OBX id is 0 for checklist=${checklist.id}",
            );
          }
        }

        output.add(checklist);
      }

      debugPrint(
        "📦 Found ${output.length} end-trip checklist items linked to trip: ${trip.name}",
      );

      return output;
    } catch (e, st) {
      debugPrint("❌ loadEndTripChecklist ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }
}
