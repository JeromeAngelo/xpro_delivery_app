import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

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
}

class TripUpdateLocalDatasourceImpl implements TripUpdateLocalDatasource {
  final Box<TripUpdateModel> _tripUpdateBox;
  List<TripUpdateModel>? _cachedUpdates;

  TripUpdateLocalDatasourceImpl(this._tripUpdateBox);

  @override
  Future<List<TripUpdateModel>> getTripUpdates(String tripId) async {
    try {
      debugPrint('📦 LOCAL: Fetching trip updates for trip: $tripId');
      final updates = _tripUpdateBox
          .query(TripUpdateModel_.tripId.equals(tripId))
          .build()
          .find();
      debugPrint('✅ LOCAL: Found ${updates.length} trip updates');
      return updates;
    } catch (e) {
      debugPrint('❌ LOCAL: Error fetching trip updates: $e');
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
      debugPrint('📥 LOCAL: Creating new trip update');
      debugPrint('🏷️ Trip ID: $tripId');
      debugPrint('📍 Location: $latitude, $longitude');
      debugPrint('📝 Description: $description');
      debugPrint('🔄 Status: $status');

      final newUpdate = TripUpdateModel(
        tripId: tripId,
        description: description,
        image: image,
        latitude: latitude,
        longitude: longitude,
        date: DateTime.now(),
        status: status,
      );

      final id = _tripUpdateBox.put(newUpdate);
      debugPrint('🆔 LOCAL: Stored with ID: $id');

      // Update cache
      _cachedUpdates = _tripUpdateBox.getAll();

      final storedCount = _tripUpdateBox.count();
      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('   📦 Total Updates: $storedCount');
      debugPrint('   🔄 Latest Update Time: ${newUpdate.date}');
      debugPrint('✅ LOCAL: Update stored successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Storage error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
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

      _tripUpdateBox.removeAll();
      debugPrint('🧹 Cleared previous updates');

      final uniqueUpdates = updates
          .fold<Map<String, TripUpdateModel>>(
            {},
            (map, update) {
              if (update.id != null && update.description != null) {
                map[update.id!] = update;
              }
              return map;
            },
          )
          .values
          .toList();

      _tripUpdateBox.putMany(uniqueUpdates);
      _cachedUpdates = uniqueUpdates;

      debugPrint('📊 Stored ${uniqueUpdates.length} unique valid updates');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
  
}
