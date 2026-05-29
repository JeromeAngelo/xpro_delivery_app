import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin EndTripImpl on TripLocalBase {
  Future<void> endTrip(String tripId) async {
    final safeTripId = tripId.trim();

    try {
      debugPrint(
        '🧹 Starting complete data cleanup (endTrip) tripId=$safeTripId',
      );

      final prefs = await SharedPreferences.getInstance();

      // ------------------------------------------------------------------
      // 0) Guard: still allow cleanup even if tripId is empty
      // ------------------------------------------------------------------
      if (safeTripId.isEmpty) {
        debugPrint(
          '⚠️ endTrip called with empty tripId — will still cleanup safely',
        );
      }

      // ------------------------------------------------------------------
      // 0.5) CALCULATE TRIP TOTAL TIME
      // ------------------------------------------------------------------
      final trip = tripBox.query().build().findFirst();
      if (trip != null) {
        await calculateAndStoreTripTotalTime(trip);
      }

      // ------------------------------------------------------------------
      // 1) CLEAR USER TRIP ASSIGNMENT (OBJECTBOX + PREFS VIA saveUser)
      //    ✅ Only clear if user is actually assigned to THIS trip (or if tripId empty -> clear all)
      // ------------------------------------------------------------------
      final users = userBox.getAll();

      if (users.isEmpty) {
        debugPrint('ℹ️ No local users found in ObjectBox');
      } else {
        for (final user in users) {
          try {
            // Determine user trip match safely
            final userTripPbId = (user.trip.target?.id ?? '').toString().trim();
            final shouldClear =
                safeTripId.isEmpty || userTripPbId == safeTripId;

            debugPrint(
              '👤 User=${user.pocketbaseId} '
              '| userTrip=$userTripPbId '
              '| shouldClear=$shouldClear',
            );

            if (!shouldClear) continue;

            // ✅ Clear ToOne safely
            user.trip
              ..target = null
              ..targetId = 0;

            // ✅ Clear other trip fields safely (only if they exist in your model)
            user.tripId = null;
            user.tripNumberId = null;

            // ✅ Persist using your unified offline-first function
            await saveUser(user);

            debugPrint(
              '✅ Cleared trip assignment + synced user: ${user.pocketbaseId}',
            );
          } catch (e) {
            // Do NOT crash cleanup because of one user record
            debugPrint(
              '⚠️ Failed to clear trip for user=${user.pocketbaseId}: $e',
            );
          }
        }
      }

      // ------------------------------------------------------------------
      // 2) REMOVE OLD TRIP-RELATED SHARED PREF KEYS
      // ------------------------------------------------------------------
      await prefs.remove('trip');
      await prefs.remove('tripNumberId');
      await prefs.remove('tripId');
      debugPrint('✅ Removed trip-related SharedPref keys');

      // ------------------------------------------------------------------
      // 3) CLEAR ALL OBJECTBOX TABLES (trip-scoped)
      //    NOTE: do this AFTER saveUser so user write is not lost
      // ------------------------------------------------------------------
      tripBox.removeAll();
      deliveryTeamBox.removeAll();
      personnelBox.removeAll();
      checklistBox.removeAll();
      deliveryUpdateBox.removeAll();
      endTripChecklistBox.removeAll();
      deliveryDataBox.removeAll();
      vehicleBox.removeAll();
      otpBox.removeAll();
      endTripOtpBox.removeAll();

      debugPrint('✅ Cleared all ObjectBox trip-scoped data');

      // ------------------------------------------------------------------
      // 4) CLEAR IN-MEMORY CACHE
      // ------------------------------------------------------------------
      cachedTrip = null;
      trackingId = null;

      // ------------------------------------------------------------------
      // 5) CLEAR OTHER SHARED PREFERENCES CACHES
      // ------------------------------------------------------------------
      await prefs.remove('user_trip_data');
      await prefs.remove('trip_cache');
      await prefs.remove('delivery_status_cache');
      await prefs.remove('customer_cache');
      await prefs.remove('active_trip');
      await prefs.remove('last_trip_id');
      await prefs.remove('last_trip_number');

      // ------------------------------------------------------------------
      // 6) VERIFICATION LOGS
      // ------------------------------------------------------------------
      final tripCount = tripBox.count();
      final userDataAfterCleanup = prefs.getString('user_data');

      if (userDataAfterCleanup != null) {
        try {
          final parsed = jsonDecode(userDataAfterCleanup);
          debugPrint('✅ Verification - User data after cleanup:');
          debugPrint('   👤 Name: ${parsed['name']}');
          debugPrint('   📧 Email: ${parsed['email']}');
          debugPrint('   🎫 Trip Number: ${parsed['tripNumberId']}');
          debugPrint('   🎫 Trip: ${parsed['trip']}');
        } catch (e) {
          debugPrint('⚠️ Verification - Failed to parse user_data: $e');
        }
      } else {
        debugPrint(
          '⚠️ Verification - user_data is missing in SharedPreferences',
        );
      }

      debugPrint('✅ Verification - Trip count after cleanup: $tripCount');
      debugPrint('✅ endTrip cleanup completed successfully');
    } catch (e) {
      debugPrint('❌ Error clearing data (endTrip): $e');
      throw CacheException(message: e.toString());
    }
  }
}
