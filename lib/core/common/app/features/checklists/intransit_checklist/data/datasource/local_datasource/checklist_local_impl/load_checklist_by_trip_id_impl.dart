import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/local_datasource/checklist_local_impl/checklist_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadChecklistByTripIdImpl on ChecklistLocalBase {
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId) async {
    try {
      debugPrint("📥 LOCAL loadChecklistByTripId() tripId = $tripId");

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint("⚠️ Trip not found in local DB for tripId: $tripId");
        return [];
      }

      // -------------------------------------------------------------
      // 2️⃣ Get Checklist linked to this trip (via relation)
      // -------------------------------------------------------------
      final checklistSet = <String, ChecklistModel>{}; // dedupe by PB ID

      for (final c in trip.checklist) {
        final fullChecklist = checklistBox.get(c.objectBoxId);
        if (fullChecklist != null) {
          checklistSet[fullChecklist.id ?? ""] = fullChecklist;
        }
      }

      if (checklistSet.isEmpty) {
        debugPrint("⚠️ No checklist found for trip: ${trip.name}");
        return [];
      }

      final output = <ChecklistModel>[];

      // -------------------------------------------------------------
      // 3️⃣ Load relations safely
      // -------------------------------------------------------------
      for (final checklist in checklistSet.values) {
        debugPrint("📄 Loading relations for Checklist → ${checklist.id}");

        // 🚚 Trip relation
        final t = checklist.trip.target;
        if (t != null) {
          final fullTrip = tripBox.get(t.objectBoxId);
          if (fullTrip != null) {
            checklist.trip.target = fullTrip;
            checklist.trip.targetId = fullTrip.objectBoxId;
            debugPrint("🚚 Trip loaded → ${fullTrip.name}");
          }
        }

        output.add(checklist);
      }

      debugPrint(
        "📦 Found ${output.length} checklist items linked to trip: ${trip.name}",
      );

      return output;
    } catch (e, st) {
      debugPrint("❌ loadChecklistByTripId ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }
}
