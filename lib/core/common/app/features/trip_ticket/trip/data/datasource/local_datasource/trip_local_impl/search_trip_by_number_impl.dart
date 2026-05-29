import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../models/trip_models.dart';

mixin SearchTripByNumberImpl on TripLocalBase {
  Future<TripModel> searchTripByNumber(String tripNumberId) async {
    debugPrint('🔍 Searching for trip: $tripNumberId');

    final trips = tripBox.getAll().where(
      (trip) => trip.tripNumberId == tripNumberId,
    );

    if (trips.isEmpty) {
      debugPrint('❌ Trip not found: $tripNumberId');
      throw const CacheException(message: 'Trip not found in local storage');
    }

    debugPrint('✅ Found trip: ${trips.first.tripNumberId}');
    return trips.first;
  }
}
