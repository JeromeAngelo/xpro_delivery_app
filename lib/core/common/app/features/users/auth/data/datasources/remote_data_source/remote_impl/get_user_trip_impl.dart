import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/auth_remote_base.dart';

/// Mixin that provides the [getUserTrip] implementation for [AuthRemoteDataSrc].
mixin GetUserTripImpl on AuthRemoteBase {
  Future<TripModel> getUserTrip(String userId) async {
    try {
      debugPrint('🔍 Loading trip for user: $userId');

      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData == null) {
        throw const ServerException(
          message: 'No stored user data found',
          statusCode: '404',
        );
      }

      final userData = jsonDecode(storedUserData);

      // ✅ FIX: Use user's trip relation ID, not tripNumberId
      final userTripPBId = userData['trip'];
      debugPrint('🆔 User relation-based trip PB ID: $userTripPBId');

      if (userTripPBId == null || userTripPBId.toString().isEmpty) {
        throw const ServerException(
          message: 'User has no assigned trip (relation field empty)',
          statusCode: '404',
        );
      }

      // 🔥 DIRECT fetch — do NOT filter by tripNumberId
      final tripRecord = await pocketBaseClient
          .collection('tripticket')
          .getOne(
            userTripPBId,
            expand: 'deliveryData,deliveryTeam,personels,vehicle,checklist',
          );

      debugPrint('🟦 Trip fetched successfully → PB ID: ${tripRecord.id}');

      final mappedData = {
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        ...Map<String, dynamic>.from(tripRecord.data),
        'deliveryData': mapExpandedRecord(tripRecord.expand['deliveryData']),
        'deliveryTeam': mapExpandedRecord(tripRecord.expand['deliveryTeam']),
        'personels': mapExpandedRecord(tripRecord.expand['personels']),
        'deliveryVehicle': mapExpandedRecord(
          tripRecord.expand['deliveryVehicle'],
        ),
        'checklist': mapExpandedRecord(tripRecord.expand['checklist']),
      };

      await prefs.setString('user_trip_data', jsonEncode(mappedData));
      debugPrint('💾 Trip data cached successfully');

      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Failed to fetch user trip: $e');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
