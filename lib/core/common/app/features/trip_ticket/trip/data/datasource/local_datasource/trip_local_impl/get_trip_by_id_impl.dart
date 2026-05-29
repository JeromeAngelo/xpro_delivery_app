import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../models/trip_models.dart';

mixin GetTripByIdImpl on TripLocalBase {
  Future<TripModel> getTripById(String id) async {
    debugPrint('📱 Loading trip from local storage by ID: $id');

    final trip =
        tripBox.query(TripModel_.pocketbaseId.equals(id)).build().findFirst();

    if (trip == null) {
      debugPrint('❌ Trip not found in local storage: $id');
      throw const CacheException(message: 'Trip not found in local storage');
    }

    debugPrint('✅ Loaded trip: ${trip.tripNumberId}');
    return trip;
  }
}
