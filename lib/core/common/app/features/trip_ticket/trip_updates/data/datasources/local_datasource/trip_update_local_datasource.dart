import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../../../services/objectbox.dart';
import '../../../../trip/data/models/trip_models.dart';

abstract class TripUpdateLocalDatasource {
  Future<List<TripUpdateModel>> getTripUpdates(String tripId);
  Future<void> createTripUpdate({
    required String tripId,
    required String description,
    required String image,
    required String latitude,
    required String longitude,
    required TripUpdateStatus status,
  });
  Future<void> cacheTripUpdates(List<TripUpdateModel> updates);
  Box<TripUpdateModel> get tripUpdateBox;

}
class TripUpdateLocalDatasourceImpl implements TripUpdateLocalDatasource {
  @override
  Box<TripUpdateModel> get tripUpdateBox => objectBoxStore.tripUpdatesBox;
    Box<TripModel> get tripBox => objectBoxStore.tripBox;


  List<TripUpdateModel>? _cachedUpdates;

  final ObjectBoxStore objectBoxStore;

  TripUpdateLocalDatasourceImpl(this.objectBoxStore);
@override
Future<List<TripUpdateModel>> getTripUpdates(String tripId) async {
  try {
    debugPrint('📥 LOCAL: Fetching TripUpdates for trip: $tripId');

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
    // 2️⃣ Get TripUpdates linked to this trip
    // -------------------------------------------------------------
    final tripUpdateSet = <String, TripUpdateModel>{}; // deduplicate by PB ID
    for (final t in trip.tripUpdates) {
      final fullUpdate = tripUpdateBox.get(t.objectBoxId);
      if (fullUpdate != null) {
        tripUpdateSet[fullUpdate.id ?? ""] = fullUpdate;
      }
    }

    if (tripUpdateSet.isEmpty) {
      debugPrint("⚠️ No TripUpdates found for trip: ${trip.name}");
      return [];
    }

    final output = <TripUpdateModel>[];

    // -------------------------------------------------------------
    // 3️⃣ Load nested relations safely
    // -------------------------------------------------------------
    for (final update in tripUpdateSet.values) {
      debugPrint('📄 Loading relations for TripUpdate → ${update.id}');

      // 🔗 Trip relation
      final t = update.trip.target;
      if (t != null) {
        final fullTrip = tripBox.get(t.objectBoxId);
        if (fullTrip != null) {
          update.trip.target = fullTrip;
          update.tripId = fullTrip.id;
          debugPrint('🔗 Trip loaded → ${fullTrip.name}');
        }
      }

      // Add to final output
      output.add(update);
    }

    debugPrint(
      "📦 Found ${output.length} TripUpdates linked to trip: ${trip.name}",
    );

    return output;
  } catch (e, st) {
    debugPrint('❌ getTripUpdates ERROR: $e\n$st');
    throw CacheException(message: e.toString());
  }
}

@override
Future<void> createTripUpdate({
  required String tripId,
  required String description,
  required String image,
  required String latitude,
  required String longitude,
  required TripUpdateStatus status,
}) async {
  try {
    debugPrint('📥 LOCAL: Creating new TripUpdate');
    debugPrint('🏷️ Trip ID: $tripId');

    // -------------------------------------------------------------
    // 1️⃣ Find Trip first
    // -------------------------------------------------------------
    final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
    final trip = tripQuery.findFirst();
    tripQuery.close();

    if (trip == null) {
      debugPrint('⚠️ Trip not found for TripUpdate creation: $tripId');
      return;
    }

    // -------------------------------------------------------------
    // 2️⃣ Create TripUpdate model
    // -------------------------------------------------------------
    final newUpdate = TripUpdateModel(
      id: '', // no PB ID yet (local-first)
      collectionName: 'tripUpdates',
      status: status,
      date: DateTime.now(),
      image: image,
      description: description,
      latitude: latitude,
      longitude: longitude,
      tripData: trip,
      tripId: trip.id,
      hasTrip: true,
      hasPendingSync: true,
    )
      ..syncStatus = SyncStatus.pending.name
      ..retryCount = 0
      ..lastSyncAttemptAt = null
      ..nextRetryAt = null
      ..version = 0;

    // -------------------------------------------------------------
    // 3️⃣ Store locally
    // -------------------------------------------------------------
    final newId = tripUpdateBox.put(newUpdate);
    final stored = tripUpdateBox.get(newId)!;

    debugPrint(
      '✅ LOCAL: TripUpdate stored → OBX: ${stored.objectBoxId}, Status: ${stored.status}',
    );

    // -------------------------------------------------------------
    // 4️⃣ Attach to Trip (toMany)
    // -------------------------------------------------------------
    trip.tripUpdates.add(stored);
    tripBox.put(trip);

    debugPrint(
      '🔗 TripUpdate linked → Trip: ${trip.name}, '
      'TripUpdates count: ${trip.tripUpdates.length}',
    );

    // -------------------------------------------------------------
    // 5️⃣ Normalize via sync function (dedupe & safety)
    // -------------------------------------------------------------
    await _syncTripUpdatesForTrip(trip);


    debugPrint(
      '🟢 TripUpdate creation & sync complete → Trip: ${trip.name}',
    );
  } catch (e, st) {
    debugPrint('❌ createTripUpdate ERROR: $e\n$st');
    throw CacheException(message: e.toString());
  }
}

  Future<void> _syncTripUpdatesForTrip(TripModel trip) async {
  final List<TripUpdateModel> updatedTripUpdates = [];

  for (var update in trip.tripUpdates) {
    debugPrint(
      '📝 Syncing TripUpdate → Trip: ${trip.name}, PB: ${update.pocketbaseId}, db: ${update.objectBoxId}, Status: ${update.status}',
    );

    final existing = tripUpdateBox
        .query(TripUpdateModel_.pocketbaseId.equals(update.pocketbaseId))
        .build()
        .findFirst();

    TripUpdateModel updated;

    if (existing != null) {
      final full = tripUpdateBox.get(existing.objectBoxId);
      if (full != null) {
        // Update fields
        full.status = update.status;
        full.date = update.date;
        full.image = update.image;
        full.description = update.description;
        full.latitude = update.latitude;
        full.longitude = update.longitude;
        full.collectionId = update.collectionId;
        full.collectionName = update.collectionName;
        full.trip.target = trip; // ensure relation
        full.tripId = trip.id;

        tripUpdateBox.put(full);
        updated = full;
        debugPrint(
          '🔁 TripUpdate updated → PB: ${updated.pocketbaseId} (OBX: ${updated.objectBoxId})',
        );
      } else {
        continue;
      }
    } else {
      // New record
      update.trip.target = trip;
      update.tripId = trip.id;
      final newId = tripUpdateBox.put(update);
      updated = tripUpdateBox.get(newId)!;
      debugPrint(
        '✅ New TripUpdate saved → PB: ${updated.pocketbaseId} (OBX: ${updated.objectBoxId})',
      );
    }

    updatedTripUpdates.add(updated);
  }

  // Assign fully updated TripUpdates to trip
  trip.tripUpdates.clear();
  trip.tripUpdates.addAll(updatedTripUpdates);
  tripBox.put(trip);

  debugPrint(
    '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, '
    'TripUpdates count: ${trip.tripUpdates.length}',
  );
}


  @override
  Future<void> cacheTripUpdates(List<TripUpdateModel> updates) async {
    try {
      debugPrint('💾 LOCAL: Caching ${updates.length} updates');
      await _autoSave(updates);
      debugPrint('✅ LOCAL: Cache updated successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Cache error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _autoSave(List<TripUpdateModel> updates) async {
    try {
      debugPrint('🔍 Processing ${updates.length} updates');

      tripUpdateBox.removeAll();
      debugPrint('🧹 Cleared previous updates');

      final uniqueUpdates =
          updates
              .fold<Map<String, TripUpdateModel>>({}, (map, update) {
                if (update.id != null && update.description != null) {
                  map[update.id!] = update;
                }
                return map;
              })
              .values
              .toList();

      tripUpdateBox.putMany(uniqueUpdates);
      _cachedUpdates = uniqueUpdates;

      debugPrint('📊 Stored ${uniqueUpdates.length} unique valid updates');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  /// 🆕 Fetch all TripUpdates pending sync
Future<List<TripUpdateModel>> getPendingTripUpdates() async {
  final query =
      tripUpdateBox
          .query(
            TripUpdateModel_.syncStatus.equals(SyncStatus.pending.name),
          )
          .build();

  final pending = query.find();
  query.close();

  debugPrint('LOCAL 🔄 Pending TripUpdates sync count: ${pending.length}');
  return pending;
}

/// 🆕 Mark TripUpdate as syncing (in-progress)
Future<void> markTripUpdateSyncing(TripUpdateModel update) async {
  final updated = update.copyWith(
    hasPendingSync: false,
  )
    ..syncStatus = SyncStatus.syncing.name
    ..lastSyncAttemptAt = DateTime.now();

  tripUpdateBox.put(updated);

  debugPrint(
    'LOCAL 🔄 TripUpdate marked syncing → OBX=${update.objectBoxId}',
  );
}

/// 🆕 Mark TripUpdate as successfully synced
Future<void> markTripUpdateSynced(
  TripUpdateModel update,
  String remoteId,
) async {
  final updated = update.copyWith(
    id: remoteId,
    hasPendingSync: false,
  )
    ..syncStatus = SyncStatus.synced.name
    ..retryCount = 0
    ..lastSyncError = null
    ..updatedBy = null;

  tripUpdateBox.put(updated);

  debugPrint(
    'LOCAL ✅ TripUpdate synced → OBX=${update.objectBoxId}, PB=$remoteId',
  );
}

/// 🆕 Mark TripUpdate as failed sync (with retry & backoff)
Future<void> markTripUpdateFailed(
  TripUpdateModel update,
  String error,
) async {
  final retryCount = update.retryCount + 1;

  update
    ..syncStatus = SyncStatus.failed.name
    ..retryCount = retryCount
    ..lastSyncError = error
    ..nextRetryAt = DateTime.now().add(
      Duration(seconds: 2 * retryCount * 2),
    );

  tripUpdateBox.put(update);

  debugPrint(
    'LOCAL ⚠️ TripUpdate sync failed → OBX=${update.objectBoxId}, retry=$retryCount',
  );
}

/// 🆕 Generic pending list (pending + failed)
Future<List<TripUpdateModel>> getPendingSyncList() async {
  final all = tripUpdateBox.getAll();
  return all
      .where(
        (u) =>
            u.syncStatus == SyncStatus.pending.name ||
            u.syncStatus == SyncStatus.failed.name,
      )
      .toList();
}

}
