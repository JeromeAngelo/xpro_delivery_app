import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheTripUpdatesImpl on TripUpdateLocalBase {
  Future<void> cacheTripUpdates(List<TripUpdateModel> updates) async {
    try {
      debugPrint('💾 LOCAL: Caching ${updates.length} updates');
      await autoSave(updates);
      debugPrint('✅ LOCAL: Cache updated successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Cache error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
