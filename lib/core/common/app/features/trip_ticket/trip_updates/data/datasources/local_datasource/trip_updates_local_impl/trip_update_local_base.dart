import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';

abstract class TripUpdateLocalBase {
  final ObjectBoxStore objectBoxStore;
  List<TripUpdateModel>? cachedUpdatesList;

  TripUpdateLocalBase(this.objectBoxStore);

  // ================================================================
  // BOX GETTERS
  // ================================================================
  Box<TripUpdateModel> get tripUpdateBox => objectBoxStore.tripUpdatesBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;

  // ================================================================
  // HELPER METHODS (formerly private, now public for mixin access)
  // ================================================================

  Future<void> syncTripUpdatesForTrip(TripModel trip) async {
    final List<TripUpdateModel> updatedTripUpdates = [];

    for (var update in trip.tripUpdates) {
      debugPrint(
        '📝 Syncing TripUpdate → Trip: ${trip.name}, PB: ${update.pocketbaseId}, db: ${update.objectBoxId}, Status: ${update.status}',
      );

      final existing =
          tripUpdateBox
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

  Future<void> autoSave(List<TripUpdateModel> updates) async {
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
      cachedUpdatesList = uniqueUpdates;

      debugPrint('📊 Stored ${uniqueUpdates.length} unique valid updates');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
