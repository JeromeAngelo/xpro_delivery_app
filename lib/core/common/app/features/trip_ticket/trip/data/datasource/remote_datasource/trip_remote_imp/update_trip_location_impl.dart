import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin UpdateTripLocationImpl on TripRemoteBase {
  Future<TripModel> updateTripLocation(
    String tripId,
    double latitude,
    double longitude, {
    double? accuracy,
    String? source,
    double? totalDistance,
  }) async {
    try {
      debugPrint('🔄 REMOTE: Updating enhanced trip location for ID: $tripId');
      debugPrint(
        '📍 Coordinates: Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}',
      );
      debugPrint(
        '🎯 Accuracy: ${accuracy?.toStringAsFixed(2) ?? 'Unknown'} meters',
      );
      debugPrint('📡 Source: ${source ?? 'GPS_Enhanced'}');

      // Extract trip ID if it's a JSON string
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Using trip ID: $actualTripId');

      RecordModel? tripRecord;

      // Try fetching by actual PB trip ID
      try {
        tripRecord = await pocketBaseClient
            .collection('tripticket')
            .getOne(
              actualTripId,
              expand:
                  'customers,deliveryTeam,deliveryTeam.personels,deliveryTeam.deliveryVehicle,deliveryTeam.checklist,personels,deliveryVehicle,checklist,deliveryData.customer,deliveryData.invoices,deliveryData.deliveryUpdates',
            );
      } catch (e) {
        debugPrint('⚠️ Failed to get trip by PB ID: $e');
        // Fallback: try finding by tripNumberId
        debugPrint('🔍 Attempting fallback by tripNumberId...');
        final filterRecords = await pocketBaseClient
            .collection('tripticket')
            .getFullList(filter: 'tripNumberId="$actualTripId"');

        if (filterRecords.isEmpty) {
          debugPrint('❌ No trip found with tripNumberId=$actualTripId');
          throw ServerException(
            message: 'Trip not found using tripNumberId: $actualTripId',
            statusCode: '404',
          );
        }

        tripRecord = filterRecords.first;
        actualTripId = tripRecord.id;
        debugPrint('✅ Fallback succeeded, using PB ID: $actualTripId');
      }

      // Update the trip with new coordinates and accuracy info
      final updatedRecord = await pocketBaseClient
          .collection('tripticket')
          .update(
            actualTripId,
            body: {
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
              'locationAccuracy': accuracy?.toString() ?? '0',
              'locationSource': source ?? 'GPS_Enhanced',
              'updated': DateTime.now().toIso8601String(),
            },
          );

      // Use total distance passed from the LocationService
      final distanceToRecord = totalDistance ?? 0.0;
      debugPrint(
        '📊 REMOTE: Using total distance for recording: ${distanceToRecord.toStringAsFixed(3)} km',
      );

      // Create enhanced record in tripCoordinatesUpdates collection
      await createTripCoordinateUpdate(
        actualTripId,
        latitude,
        longitude,
        accuracy: accuracy,
        source: source,
        totalDistance: distanceToRecord,
      );

      debugPrint('✅ Trip location updated successfully');

      // Prepare TripModel from updated record
      final mappedData = prepareTripDataSafely(
        tripRecord,
        updatedRecord,
        latitude,
        longitude,
      );
      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error updating trip location: $e');
      throw ServerException(
        message: 'Failed to update trip location: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
