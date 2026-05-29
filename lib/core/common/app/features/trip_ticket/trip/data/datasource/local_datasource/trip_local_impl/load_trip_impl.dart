import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../models/trip_models.dart';

mixin LoadTripImpl on TripLocalBase {
  @override
  Future<TripModel> loadTrip() async {
    debugPrint('📱 Attempting to load trip from local storage');

    if (cachedTrip != null) {
      debugPrint('📦 Returning cached trip: ${cachedTrip!.tripNumberId}');
      return cachedTrip!;
    }

    final trips = tripBox.getAll();
    debugPrint('📊 Found ${trips.length} trips in local storage');

    if (trips.isEmpty) {
      throw const CacheException(message: 'No trips found in local storage');
    }

    cachedTrip = trips.first;
    debugPrint('💾 Loaded trip: ${cachedTrip!.tripNumberId}');
    return cachedTrip!;
  }
}
