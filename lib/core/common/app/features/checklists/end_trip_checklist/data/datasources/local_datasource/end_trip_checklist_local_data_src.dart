import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../../../services/objectbox.dart';
import '../../../../../trip_ticket/trip/data/models/trip_models.dart';
abstract class EndTripChecklistLocalDataSource {
  Future<List<EndTripChecklistModel>> generateEndTripChecklist(String tripId);
  Future<bool> checkEndTripChecklistItem(String id);
  Future<List<EndTripChecklistModel>> loadEndTripChecklist(String tripId);
  Future<void> cacheChecklists(List<EndTripChecklistModel> checklists);
  /// 🆕 Background sync helper methods
  Future<void> markSyncing(EndTripChecklistModel status);
  Future<void> markSynced(EndTripChecklistModel status);
  Future<void> markFailed(EndTripChecklistModel status, String error);
  Future<List<EndTripChecklistModel>> getPendingSyncList();
}

class EndTripChecklistLocalDataSourceImpl implements EndTripChecklistLocalDataSource {
  Box<EndTripChecklistModel> get endTripChecklistBox =>
      objectBoxStore.endTripChecklistBox;
      Box<TripModel> get tripBox => objectBoxStore.tripBox;
  List<EndTripChecklistModel>? _cachedChecklists;
 final ObjectBoxStore objectBoxStore;
  EndTripChecklistLocalDataSourceImpl(this.objectBoxStore,);

  Future<void> _autoSave(List<EndTripChecklistModel> checklists) async {
    try {
      debugPrint('🔍 Processing ${checklists.length} checklist items');
      
      // Clear existing data
      endTripChecklistBox.removeAll();
      debugPrint('🧹 Cleared previous checklist items');
      
      // Filter out duplicates by ID
      final uniqueChecklists = checklists.fold<Map<String, EndTripChecklistModel>>(
        {},
        (map, checklist) {
          map[checklist.id ?? ''] = checklist;
          return map;
        },
      ).values.toList();
      
      endTripChecklistBox.putMany(uniqueChecklists);
      _cachedChecklists = uniqueChecklists;
      debugPrint('📊 Stored ${uniqueChecklists.length} unique valid checklist items');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  
@override
Future<List<EndTripChecklistModel>> generateEndTripChecklist(String tripId) async {
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
      debugPrint("⚠️ End-trip checklist already exists for trip: ${trip.name}");
      return trip.endTripChecklist
          .map((c) => endTripChecklistBox.get(c.dbId))
          .whereType<EndTripChecklistModel>()
          .toList();
    }

    // -------------------------------------------------------------
    // 3️⃣ Define checklist templates
    // -------------------------------------------------------------
    const templates = [
      'Collections',
      'Pushcarts',
      'Remittance',
    ];

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

@override
Future<bool> checkEndTripChecklistItem(String id) async {
  try {
    debugPrint('🔄 LOCAL: Updating checklist item $id');
    
    final items = endTripChecklistBox.getAll();
    final item = items.firstWhere(
      (item) => item.id == id,
      orElse: () {
        debugPrint('⚠️ LOCAL: Item not found with ID: $id');
        throw const CacheException(message: 'Checklist item not found', statusCode: 404);
      },
    );
    
    item.isChecked = true;
    item.status = 'completed';
    item.timeCompleted = DateTime.now();
    
    endTripChecklistBox.put(item);
    debugPrint('✅ LOCAL: Item updated successfully');
    return true;
    
  } catch (e) {
    debugPrint('❌ LOCAL: Update failed - $e');
    throw CacheException(message: e.toString());
  }
}

@override
Future<List<EndTripChecklistModel>> loadEndTripChecklist(String tripId) async {
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

      final key = (fullChecklist.id ?? '').trim(); // PB id string (your "id" field)
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
      debugPrint("📄 Loading relations for EndTripChecklist → ${checklist.id}");

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
          debugPrint("⚠️ Trip relation exists but OBX id is 0 for checklist=${checklist.id}");
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


  @override
  Future<void> cacheChecklists(List<EndTripChecklistModel> checklists) async {
    try {
      debugPrint('💾 Caching checklists from remote');
      await _autoSave(checklists);
      debugPrint('✅ Checklists cached successfully');
    } catch (e) {
      debugPrint('❌ Failed to cache checklists: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<List<EndTripChecklistModel>> getPendingSyncList() async {
    final all = endTripChecklistBox.getAll();
    return all
        .where(
          (s) =>
              s.syncStatus == SyncStatus.pending.name ||
              s.syncStatus == SyncStatus.failed.name,
        )
        .toList();
  }
  
  @override
  Future<void> markFailed(EndTripChecklistModel status, String error) async{
    final retryCount = (status.retryCount) + 1;
    final updated = status.copyWith(
      syncStatus: SyncStatus.pending.name,
      retryCount: retryCount,
      lastSyncError: error,
      nextRetryAt: DateTime.now().add(
        Duration(seconds: 2 * retryCount * 2),
      ), // exponential backoff
    );
    endTripChecklistBox.put(updated);
    debugPrint(
      'LOCAL ⚠️ Sync failed → ${status.objectName}, retryCount=$retryCount',
    );
  }
  
  @override
  Future<void> markSynced(EndTripChecklistModel status)async {
     final updated = status.copyWith(
      syncStatus: SyncStatus.synced.name,
      retryCount: 0,
      lastSyncError: null,
    );
    endTripChecklistBox.put(updated);
    debugPrint('LOCAL ✅ Synced → ${status.objectName}');
  }
  
  @override
  Future<void> markSyncing(EndTripChecklistModel status)async {
   final updated = status.copyWith(
      syncStatus: SyncStatus.syncing.name,
      lastSyncAttemptAt: DateTime.now(),
    );
    endTripChecklistBox.put(updated);
    debugPrint('LOCAL 🔄 Marked syncing → ${status.objectName}');
  }
}
