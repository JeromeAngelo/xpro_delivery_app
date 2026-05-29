import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

mixin AcceptTripImpl on TripLocalBase {
  Future<(TripModel, String)> acceptTrip(String inputTripId) async {
    debugPrint('🔄 Processing trip acceptance locally (INLINE SYNC)');

    // ------------------------------------------------------------
    // STEP 1 — Load current user (OBX → Prefs fallback)
    // ------------------------------------------------------------
    LocalUsersModel? currentUser;

    final users = userBox.getAll();

    if (users.isNotEmpty) {
      currentUser = users.first;
      debugPrint(
        '👤 User loaded from ObjectBox → '
        'Name: ${currentUser.name}, PB: ${currentUser.pocketbaseId}',
      );
    } else {
      debugPrint('⚠️ No local user, restoring from SharedPreferences');

      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData == null) {
        throw const CacheException(message: 'No user found locally');
      }

      currentUser = LocalUsersModel.fromJson(jsonDecode(storedUserData));
      userBox.put(currentUser);

      debugPrint('🆕 User restored & saved to ObjectBox');
    }

    final userId = currentUser.pocketbaseId;
    if (userId == null || userId.isEmpty) {
      throw const CacheException(message: 'Invalid user pocketbaseId');
    }

    try {
      debugPrint("💾 LOCAL SYNC: Saving trip for user ID: $userId");

      // ------------------------------------------------------------
      // STEP 2 — Load FULL trip from cache (must include trip.checklist)
      // ------------------------------------------------------------
      final prefs = await SharedPreferences.getInstance();
      final cachedTripRaw = prefs.getString('user_trip_data');

      if (cachedTripRaw == null) {
        throw const CacheException(
          message: 'user_trip_data not found (no trip payload to sync)',
        );
      }

      final cachedTripJson = jsonDecode(cachedTripRaw);
      TripModel trip = TripModel.fromJson(cachedTripJson);

      debugPrint('✅ Loaded trip from cache: ${trip.id}');
      debugPrint(
        '📋 Trip checklist count (trip.checklist): ${trip.checklist.length}',
      );

      // ---------------------------------------------------------
      // STEP 3 — Detect existing user + trip
      // ---------------------------------------------------------
      final existingUser =
          userBox
              .query(LocalUsersModel_.pocketbaseId.equals(userId))
              .build()
              .findFirst();

      final existingTrip = existingUser?.trip.target;

      if (existingTrip != null) {
        debugPrint(
          "🔍 Existing trip detected → OBX ID: ${existingTrip.objectBoxId}",
        );
        debugPrint("🧹 Running duplicate cleanup BEFORE syncing trip...");
        await removeDuplicateTrips();
      }

      // ---------------------------------------------------------
      // STEP 4 — Reuse OBX ID if trip already exists
      // ---------------------------------------------------------
      final dbTrip =
          tripBox
              .query(TripModel_.id.equals(trip.id ?? ''))
              .build()
              .findFirst();

      if (dbTrip != null) {
        trip.objectBoxId = dbTrip.objectBoxId;
        debugPrint("🔄 Trip exists → Reusing OBX ID: ${trip.objectBoxId}");
      }

      // ---------------------------------------------------------
      // ✅ STEP 4.5 — IMPORTANT: Ensure trip has OBX ID BEFORE linking relations
      // ---------------------------------------------------------
      if (trip.objectBoxId == 0) {
        final preId = tripBox.put(trip);
        trip = tripBox.get(preId)!; // use managed instance
        debugPrint(
          "🟦 Trip pre-saved (before syncing relations) → OBX ID: $preId",
        );
      } else {
        // Make sure we use the persisted instance for relation linking
        final persisted = tripBox.get(trip.objectBoxId);
        if (persisted != null) trip = persisted;
        debugPrint("🟦 Trip already has OBX ID → ${trip.objectBoxId}");
      }

      // ---------------------------------------------------------
      // STEP 5 — CLEAN related data (trip-scoped)
      // ---------------------------------------------------------
      await cleanDeliveryData();
      await cleanDeliveryTeam();
      await cleanPersonnel();
      await cleanTripUpdates();
      //   await cleanChecklistData();

      // ---------------------------------------------------------
      // STEP 6 — SYNC related entities UNDER TRIP
      // ---------------------------------------------------------
      await syncDeliveryDataForTrip(trip);
      await syncDeliveryTeamForTrip(trip);
      await syncVehicleForTrip(trip);
      await syncPersonnelsForTrip(trip);
      await syncOtpForTrip(trip);
      await syncEndTripOtpForTrip(trip);
      await syncTripUpdatesForTrip(trip);

      // ✅ IMPORTANT: Trip checklist (NOT delivery team checklist)
      await syncIntransitChecklistForTrip(trip);
      await syncEndTripChecklistForTrip(trip);

      // ---------------------------------------------------------
      // STEP 7 — Save Trip (final save)
      // ---------------------------------------------------------
      final tripObxId = tripBox.put(trip);
      debugPrint("🟦 Trip saved → OBX ID: $tripObxId | Trip ID: ${trip.id}");
      // ---------------------------------------------------------
      // STEP 8 — Link Trip to User + Save user offline-first
      // ---------------------------------------------------------
      final user = existingUser ?? currentUser;

      // ✅ Ensure tripNumberId is set (this fixes Homepage conditions)
      user.tripNumberId = (trip.tripNumberId ?? '').toString().trim();

      // ✅ Link trip (ToOne)
      user.trip.target = trip;

      // ✅ Persist + SharedPrefs sync using your function
      await saveUser(user);

      debugPrint(
        "👤 User synced (offline-first) → PB ID: $userId "
        "| Trip OBX: ${trip.objectBoxId} | tripNumberId=${user.tripNumberId}",
      );

      // ---------------------------------------------------------
      // STEP 9 — Optional SharedPreferences sync (non-authoritative)
      // ---------------------------------------------------------
      try {
        await prefs.setString(
          'user_data',
          jsonEncode({
            'id': userId,
            'email': currentUser.email,
            'name': currentUser.name,
            'trip': {'id': trip.id, 'tripNumberId': trip.tripNumberId},
            'tokenKey': currentUser.token,
          }),
        );
      } catch (_) {}

      // ---------------------------------------------------------
      // STEP 10 — Cache tracking info
      // ---------------------------------------------------------
      cachedTrip = trip;
      trackingId = 'local_tracking_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('✅ acceptTrip (INLINE SYNC) COMPLETE');
      return (trip, trackingId!);
    } catch (e) {
      debugPrint('❌ acceptTrip ERROR → $e');
      throw CacheException(message: e.toString());
    }
  }
}
