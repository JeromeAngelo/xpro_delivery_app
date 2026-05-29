import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_impl/trip_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetTripUpdatesImpl on TripUpdateRemoteBase {
  Future<List<TripUpdateModel>> getTripUpdates(String tripId) async {
    try {
      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Using trip ID: $actualTripId');

      final records = await pocketBaseClient
          .collection('tripUpdates')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'trip',
            sort: '-created', // Sort by creation date, newest first
          );

      debugPrint('✅ Retrieved ${records.length} trip updates from API');

      final updates =
          records.map((record) {
            debugPrint('🔄 Processing trip update: ${record.id}');

            // Process the trip update record similar to delivery data processing
            return processTripUpdateRecord(record, actualTripId);
          }).toList();

      debugPrint('✨ Successfully mapped ${updates.length} trip updates');
      return updates;
    } catch (e) {
      debugPrint('❌ Trip updates fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load trip updates: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
