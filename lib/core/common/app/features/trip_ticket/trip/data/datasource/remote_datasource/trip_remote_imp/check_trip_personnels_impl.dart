import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin CheckTripPersonnelsImpl on TripRemoteBase {
  Future<List<String>> checkTripPersonnels(String tripId) async {
    try {
      debugPrint('🔍 REMOTE: Checking trip personnels for tripId: $tripId');

      // Step 1: Get the current logged-in user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData == null) {
        throw const ServerException(
          message: 'No user data found. Please log in again.',
          statusCode: '401',
        );
      }

      final userData = jsonDecode(storedUserData);
      final currentUserId = userData['id'];
      debugPrint('👤 Current logged-in user ID: $currentUserId');

      // Step 2: Get the tripticket record with expanded personnel data to get more details
      final tripRecord = await pocketBaseClient
          .collection('tripticket')
          .getOne(tripId, expand: 'personels');

      // Step 3: Extract personnel IDs from the "personels" field as a list
      final personnelIds = tripRecord.data['personels'] as List? ?? [];
      debugPrint(
        '👥 Found ${personnelIds.length} personnel IDs in trip: $personnelIds',
      );

      if (personnelIds.isEmpty) {
        throw const ServerException(
          message: 'No personnel assigned to this trip',
          statusCode: '404',
        );
      }

      // Step 4: Check each personnel record to find matching user ID
      bool userFound = false;
      List<String> matchedPersonnelIds = [];

      debugPrint('🔍 Starting personnel verification...');
      debugPrint('   Looking for user ID: $currentUserId');
      debugPrint('   Total personnel to check: ${personnelIds.length}');

      for (int i = 0; i < personnelIds.length; i++) {
        String personnelId = personnelIds[i];
        try {
          debugPrint(
            '🔍 [${'$i'.padLeft(2)}/${personnelIds.length}] Checking personnel ID: $personnelId',
          );

          // Get the personnel record from "personel" collection
          final personnelRecord = await pocketBaseClient
              .collection('personels')
              .getOne(personnelId);

          final personnelData = personnelRecord.data;
          final personnelUserId = personnelData['user'];
          final personnelName = personnelData['name'] ?? 'Unknown';
          final personnelRole = personnelData['role'] ?? 'Unknown';

          debugPrint('   Personnel Details:');
          debugPrint('     - ID: $personnelId');
          debugPrint('     - Name: $personnelName');
          debugPrint('     - Role: $personnelRole');
          debugPrint('     - User ID: $personnelUserId');
          debugPrint('     - User ID Type: ${personnelUserId.runtimeType}');
          debugPrint(
            '     - Current User ID Type: ${currentUserId.runtimeType}',
          );

          // Convert both to strings for comparison to handle type mismatches
          final personnelUserIdStr = personnelUserId?.toString();
          final currentUserIdStr = currentUserId?.toString();

          debugPrint(
            '     - Personnel User ID (String): "$personnelUserIdStr"',
          );
          debugPrint('     - Current User ID (String): "$currentUserIdStr"');

          // Check if this personnel's user ID matches the current user
          if (personnelUserIdStr != null &&
              currentUserIdStr != null &&
              personnelUserIdStr == currentUserIdStr) {
            debugPrint(
              '✅ MATCH FOUND! Personnel $personnelId ($personnelName) belongs to current user',
            );
            debugPrint(
              '   ✓ Personnel User ID: "$personnelUserIdStr" == Current User ID: "$currentUserIdStr"',
            );
            userFound = true;
            matchedPersonnelIds.add(personnelId);
          } else {
            debugPrint(
              '❌ No match for personnel $personnelId ($personnelName)',
            );
            debugPrint(
              '   ✗ Personnel User ID: "$personnelUserIdStr" != Current User ID: "$currentUserIdStr"',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error checking personnel $personnelId: $e');
          debugPrint(
            '   This personnel record may be corrupted or inaccessible',
          );
          continue; // Continue checking other personnel
        }
      }

      debugPrint('🔍 Personnel verification summary:');
      debugPrint('   - Total personnel checked: ${personnelIds.length}');
      debugPrint('   - Matches found: ${matchedPersonnelIds.length}');
      debugPrint('   - User authorized: $userFound');

      if (!userFound) {
        final errorMessage =
            'User $currentUserId is not assigned as personnel to this trip.\n'
            'Trip has ${personnelIds.length} personnel assigned, but none match your user ID.\n'
            'Please contact your supervisor to verify your assignment to this trip.';

        debugPrint('❌ AUTHORIZATION FAILED: $errorMessage');
        throw ServerException(message: errorMessage, statusCode: '403');
      }

      debugPrint(
        '✅ REMOTE: User authorized! Found ${matchedPersonnelIds.length} matching personnel records',
      );
      debugPrint('   Matched Personnel IDs: $matchedPersonnelIds');

      return matchedPersonnelIds;
    } catch (e) {
      debugPrint('❌ REMOTE: Error checking trip personnels: $e');
      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Failed to check trip personnels: $e',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }
}
