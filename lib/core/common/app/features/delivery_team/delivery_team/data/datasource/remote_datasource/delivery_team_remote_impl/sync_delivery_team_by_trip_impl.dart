import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/remote_datasource/delivery_team_remote_impl/delivery_team_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import '../../../models/delivery_team_model.dart';

mixin SyncDeliveryTeamByTripImpl on DeliveryTeamRemoteBase {
  Future<DeliveryTeamModel> syncDeliveryTeamByTrip(String tripId) async {
    try {
      debugPrint('🔄 Starting delivery team load with trip ID: $tripId');

      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Extracted trip ID: $actualTripId');

      // ✅ Directly use the actual trip record ID (not tripNumberId)
      final pocketBaseTripId = actualTripId;

      // Fetch delivery team by actual trip record ID
      final result = await pocketBaseClient
          .collection('deliveryTeam')
          .getFullList(
            expand: 'personels,tripTicket,deliveryVehicle',
            filter:
                'tripTicket.id = "$pocketBaseTripId"', // ✅ FIXED: use actual trip record ID
          );

      if (result.isEmpty) {
        throw const ServerException(
          message: 'No delivery team found for this trip',
          statusCode: '404',
        );
      }

      final record = result.first;
      final deliveryTeamModel = processDeliveryTeamRecord(record);

      debugPrint('✅ Delivery team data processed successfully');
      return deliveryTeamModel;
    } catch (e) {
      debugPrint('❌ Error in delivery team load: $e');
      throw ServerException(
        message: 'Failed to load delivery team: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
