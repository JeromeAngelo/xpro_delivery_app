import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../../../services/objectbox.dart';
import '../../../../../trip_ticket/trip/data/models/trip_models.dart';


abstract class ChecklistLocalDatasource {
  Future<List<ChecklistModel>> getChecklist();
  Future<bool> checkItem(String id);
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId);
  Future<void> cacheChecklist(List<ChecklistModel> checklist);
    Stream<List<ChecklistModel>> watchChecklistByTripId(String tripId);

}

class ChecklistLocalDatasourceImpl implements ChecklistLocalDatasource {
  Box<ChecklistModel> get checklistBox => objectBoxStore.checklistBox;
  List<ChecklistModel>? _cachedChecklist;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  final ObjectBoxStore objectBoxStore;
  ChecklistLocalDatasourceImpl(this.objectBoxStore);
  @override
  Future<List<ChecklistModel>> getChecklist() async {
    try {
      return checklistBox.getAll();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> checkItem(String id) async {
    try {
      final itemId = id.trim();
      if (itemId.isEmpty) return false;

      // ✅ SAFEST: use query with string compare
      final q =
          checklistBox
              .query(ChecklistModel_.pocketbaseId.equals(itemId))
              .build();

      final checklist = q.findFirst();
      q.close();

      if (checklist == null) {
        debugPrint('⚠️ Checklist item not found locally: $itemId');
        return false;
      }

      final current = checklist.isChecked ?? false;

      // ✅ toggle properly
      checklist.isChecked = current;
      checklistBox.put(checklist);

      debugPrint(
        '✅ Updated checklist item: ${checklist.objectName} | Checked: ${checklist.isChecked}',
      );

      return checklist.isChecked ?? false;
    } catch (e, st) {
      debugPrint('❌ Local checkItem error: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }


String _two(int n) => n.toString().padLeft(2, '0');

/// ISO8601 WITH timezone offset (ex: 2026-02-09T11:20:00+08:00)
String _isoWithOffset(DateTime dt) {
  final local = dt; // device local time
  final o = local.timeZoneOffset;
  final sign = o.isNegative ? '-' : '+';
  final hh = _two(o.inHours.abs());
  final mm = _two((o.inMinutes.abs()) % 60);

  // dt.toIso8601String() for local has no offset → we append it
  final base = local.toIso8601String(); // "YYYY-MM-DDTHH:mm:ss.mmm"
  return '$base$sign$hh:$mm';
}

/// device "now" saved as local time with offset (PH device => +08:00)
String nowDeviceIso() => _isoWithOffset(DateTime.now());

  @override
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

  @override
  Future<void> cacheChecklist(List<ChecklistModel> checklist) async {
    try {
      debugPrint('💾 Caching ${checklist.length} checklist items');
      checklistBox.removeAll();
      checklistBox.putMany(checklist);
      _cachedChecklist = checklist;
      debugPrint('✅ Checklist cached successfully');
    } catch (e) {
      debugPrint('❌ Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
  
  @override
Stream<List<ChecklistModel>> watchChecklistByTripId(String tripId) {
  debugPrint('👀 LOCAL: Watching checklist via Trip relation → tripId=$tripId');

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
