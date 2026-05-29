import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/local_datasource/checklist_local_impl/checklist_local_base.dart';

mixin WatchChecklistByTripIdImpl on ChecklistLocalBase {
  Stream<List<ChecklistModel>> watchChecklistByTripId(String tripId) {
    debugPrint(
      '👀 LOCAL: Watching checklist via Trip relation → tripId=$tripId',
    );

    // -------------------------------------------------------------
    // 1️⃣ Find trip ONCE
    // -------------------------------------------------------------
    final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
    final trip = tripQuery.findFirst();
    tripQuery.close();

    if (trip == null) {
      debugPrint('⚠️ Trip not found in local DB for tripId=$tripId');
      return Stream.value(<ChecklistModel>[]);
    }

    // -------------------------------------------------------------
    // 2️⃣ Watch Checklist box (react to any changes)
    // -------------------------------------------------------------
    return checklistBox.query().watch(triggerImmediately: true).map((_) {
      try {
        final checklistSet = <String, ChecklistModel>{};

        // ---------------------------------------------------------
        // 3️⃣ Pull Checklist from Trip relation
        // ---------------------------------------------------------
        for (final c in trip.checklist) {
          final fullChecklist = checklistBox.get(c.objectBoxId);
          if (fullChecklist != null) {
            checklistSet[fullChecklist.id ?? ''] = fullChecklist;
          }
        }

        if (checklistSet.isEmpty) {
          debugPrint('⚠️ LOCAL: No checklist linked to trip → ${trip.name}');
          return <ChecklistModel>[];
        }

        final output = <ChecklistModel>[];

        // ---------------------------------------------------------
        // 4️⃣ Hydrate nested relations (IF YOU HAVE ANY)
        // ---------------------------------------------------------
        for (final item in checklistSet.values) {
          // Example (only if your checklist has relations):
          // final status = item.statusChoice.target;
          // if (status != null) {
          //   final fullStatus = statusChoiceBox.get(status.objectBoxId);
          //   if (fullStatus != null) {
          //     item.statusChoice.target = fullStatus;
          //     item.statusChoice.targetId = fullStatus.objectBoxId;
          //   }
          // }

          output.add(item);
        }

        debugPrint(
          '✅ LOCAL: Stream emitted ${output.length} checklist items for trip=${trip.name}',
        );

        return output;
      } catch (e, st) {
        debugPrint('❌ watchChecklistByTripId ERROR: $e\n$st');
        return <ChecklistModel>[];
      }
    });
  }
}
