import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GenerateEndTripChecklistImpl on EndTripChecklistLocalBase {
  Future<List<EndTripChecklistModel>> generateEndTripChecklist(
    String tripId,
  ) async {
    try {
      debugPrint("🧾 LOCAL generateEndTripChecklist() tripId = $tripId");

      // -------------------------------------------------------------
      // 1️⃣ Load trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint("❌ Trip not found for tripId: $tripId");
        throw CacheException(message: "Trip not found locally");
      }

      // -------------------------------------------------------------
      // 2️⃣ Prevent duplicate checklist generation
      // -------------------------------------------------------------
      if (trip.endTripChecklist.isNotEmpty) {
        debugPrint(
          "⚠️ End-trip checklist already exists for trip: ${trip.name}",
        );
        return trip.endTripChecklist
            .map((c) => endTripChecklistBox.get(c.dbId))
            .whereType<EndTripChecklistModel>()
            .toList();
      }

      // -------------------------------------------------------------
      // 3️⃣ Define checklist templates
      // -------------------------------------------------------------
      const templates = ['Collections', 'Pushcarts', 'Remittance'];

      final generated = <EndTripChecklistModel>[];

      // -------------------------------------------------------------
      // 4️⃣ Create + link checklist items
      // -------------------------------------------------------------
      for (final name in templates) {
        final checklist = EndTripChecklistModel(
          objectName: name,
          isChecked: false,
          status: 'pending',
          tripId: trip.id,
        );

        // Link relation
        checklist.trip.target = trip;

        // Save checklist
        endTripChecklistBox.put(checklist);

        // Link checklist to trip
        trip.endTripChecklist.add(checklist);

        generated.add(checklist);
      }

      // -------------------------------------------------------------
      // 5️⃣ Persist trip relation
      // -------------------------------------------------------------
      tripBox.put(trip);

      debugPrint(
        "✅ Generated ${generated.length} end-trip checklist items for trip: ${trip.name}",
      );

      return generated;
    } catch (e, st) {
      debugPrint("❌ generateEndTripChecklist ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }
}
