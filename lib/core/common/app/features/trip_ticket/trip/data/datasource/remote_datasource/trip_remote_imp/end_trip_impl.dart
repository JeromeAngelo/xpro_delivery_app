import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin EndTripImpl on TripRemoteBase {
  Future<TripModel> endTrip(String tripId) async {
    try {
      debugPrint('🔄 Starting trip end flow for ID: $tripId');

      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }
      debugPrint('🎯 Using trip ID: $actualTripId');

      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      Map<String, dynamic> userData = jsonDecode(storedUserData!);
      debugPrint('📦 Parsed user data: $userData');

      final userId = userData['id'];
      if (userId == null || userId.toString().isEmpty) {
        throw const ServerException(
          message: 'Invalid user ID',
          statusCode: '400',
        );
      }
      debugPrint('👤 Using user ID: $userId');

      final userRecord = await pocketBaseClient
          .collection('users')
          .getOne(userId);
      debugPrint('✅ Found user record: ${userRecord.id}');

      const delay = Duration(milliseconds: 500);

      final tripRecord = await pocketBaseClient
          .collection('tripticket')
          .getOne(
            actualTripId,
            expand:
                'customers,deliveryTeam,deliveryTeam.personels,deliveryTeam.deliveryVehicle,deliveryTeam.checklist,personels,deliveryVehicle,checklist,deliveryData.customer,deliveryData.invoices,deliveryData.deliveryUpdates',
          );

      // Update trip status
      await Future.delayed(delay);
      await pocketBaseClient
          .collection('tripticket')
          .update(
            actualTripId,
            body: {
              'isEndTrip': true,
              'timeEndTrip': DateTime.now().toIso8601String(),
              'isAccepted': false,
            },
          );
      debugPrint('✅ Trip status updated');

      // Clear user assignment
      await Future.delayed(delay);
      await pocketBaseClient
          .collection('users')
          .update(
            userId,
            body: {'tripNumberId': null, 'trip': null, 'deliveryTeam': null},
          );
      debugPrint('✅ User assignment cleared');

      // Clear vehicle assignment
      if (tripRecord.expand['vehicle'] is List) {
        final vehicleId = (tripRecord.expand['vehicle'] as List).first.id;
        await pocketBaseClient
            .collection('vehicle')
            .update(vehicleId, body: {'deliveryTeam': null, 'trip': null});
        debugPrint('✅ Vehicle assignment cleared');
      }

      // Clear personnel assignments and update isAssigned status
      final personnelsList = tripRecord.expand['personels'] as List? ?? [];
      debugPrint(
        '🔄 Processing ${personnelsList.length} personnel assignments',
      );

      for (var personnel in personnelsList) {
        final personnelRecord = personnel as RecordModel;
        await pocketBaseClient
            .collection('personels')
            .update(
              personnelRecord.id,
              body: {'deliveryTeam': null, 'trip': null, 'isAssigned': false},
            );
        debugPrint(
          '✅ Personnel ${personnelRecord.id} assignment cleared and isAssigned set to false',
        );
      }

      // Additionally, process any personnel IDs directly from tripticket data if expand failed
      final personnelsFromData = tripRecord.data['personels'];
      if (personnelsFromData != null) {
        List<String> personnelIds = [];

        if (personnelsFromData is List) {
          personnelIds = personnelsFromData.cast<String>();
        } else if (personnelsFromData is String &&
            personnelsFromData.isNotEmpty) {
          personnelIds = [personnelsFromData];
        }

        debugPrint(
          '🔄 Processing ${personnelIds.length} additional personnel IDs from data',
        );

        for (String personnelId in personnelIds) {
          try {
            // Check if this personnel ID wasn't already processed in the expand
            final alreadyProcessed = personnelsList.any(
              (p) => (p as RecordModel).id == personnelId,
            );

            if (!alreadyProcessed) {
              await pocketBaseClient
                  .collection('personels')
                  .update(
                    personnelId,
                    body: {
                      'deliveryTeam': null,
                      'trip': null,
                      'isAssigned': false,
                    },
                  );
              debugPrint(
                '✅ Additional personnel $personnelId assignment cleared and isAssigned set to false',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Failed to update personnel $personnelId: $e');
            // Continue processing other personnel even if one fails
          }
        }
      }

      // ------------------------------------------------------------------
      // Calculate trip total time before mapping
      // ------------------------------------------------------------------
      final tempTripForCalculation = TripModel.fromJson(tripRecord.toJson());
      await calculateAndStoreTripTotalTime(tempTripForCalculation);

      final mappedData = {
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        ...tripRecord.data,
        'isEndTrip': true,
        'timeEndTrip': DateTime.now().toIso8601String(),
        'tripTotalTime': tempTripForCalculation.tripTotalTime,
        'trip_update_list': mapTripUpdates(tripRecord),
        'personels': mapPersonels(tripRecord),
        'checklist': mapChecklist(tripRecord),
      };

      // Clear stored trip data
      await prefs.remove('user_trip_data');
      debugPrint('🧹 Cleared cached trip data');

      // ✅ STEP — Sync user again from remote (expand) then cache locally
      // ---------------------------------------------------------
      final syncedUser = await retry(
        () => syncUserData(userId),
        label: 'syncUserData users/$userId (expand)',
        maxAttempts: 4,
      );

      debugPrint('✅ Remote user re-synced after trip assignment');
      debugPrint('   👤 name=${syncedUser.name}');
      debugPrint('   🎫 tripNumberId=${syncedUser.tripNumberId}');
      debugPrint('   🛣 trip=${syncedUser.trip.target?.id ?? 'NO TRIP'}');

      debugPrint('✅ Trip end process completed');
      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error in endTrip: $e');
      throw ServerException(
        message: 'Failed to end trip: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
