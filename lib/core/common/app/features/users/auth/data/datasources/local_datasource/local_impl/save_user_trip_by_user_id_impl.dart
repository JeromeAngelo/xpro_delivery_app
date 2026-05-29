import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin SaveUserTripByUserIdImpl on AuthLocalBase {
  Future<void> saveUserTripByUserId(String userId, TripModel trip) async {
    try {
      debugPrint("💾 LOCAL SYNC: Saving trip for user ID: $userId");

      // ---------------------------------------------------------
      // STEP 0 — Check if the user already has a Trip
      // ---------------------------------------------------------
      final existingUser =
          box
              .query(LocalUsersModel_.pocketbaseId.equals(userId))
              .build()
              .findFirst();

      TripModel? existingTrip;

      if (existingUser != null && existingUser.trip.target != null) {
        existingTrip = existingUser.trip.target;
        debugPrint(
          "🔍 Existing trip detected → OBX ID: ${existingTrip?.objectBoxId}",
        );
      }

      // ---------------------------------------------------------
      // STEP 1 — If a trip exists, remove duplicates BEFORE syncing
      // ---------------------------------------------------------
      if (existingTrip != null) {
        debugPrint("🧹 Running duplicate cleanup BEFORE syncing trip...");
        await removeDuplicateTrips();
      }

      // ---------------------------------------------------------
      // STEP 2 — Check if incoming trip exists (reuse OBX ID)
      // ---------------------------------------------------------
      final dbTrip =
          tripBox
              .query(TripModel_.id.equals(trip.id ?? ""))
              .build()
              .findFirst();

      if (dbTrip != null) {
        trip.objectBoxId = dbTrip.objectBoxId;
        debugPrint("🔄 Trip exists → Reusing OBX ID: ${trip.objectBoxId}");
      }

      // ---------------------------------------------------------
      // STEP 3 — Clean related data before inserting new relation data
      // ---------------------------------------------------------
      await cleanDeliveryData();
      await cleanDeliveryTeam();
      await cleanPersonnel(); //← if needed
      await cleanTripUpdates();
      await cleanCancelledInvoices();
      await cleanInTransitOtp();
      await cleanEndTripOtp();
      await cleanDeliveryCollections();
      await cleanEndTripChecklist();
      await cleanChecklistData();
      // ---------------------------------------------------------
      // STEP 4 — Sync related data
      // ---------------------------------------------------------
      await syncDeliveryDataForTrip(trip);
      await syncDeliveryTeamForTrip(trip);
      await syncVehicleForTrip(trip);
      await syncPersonnelsForTrip(trip); //← if needed
      await syncTripUpdatesForTrip(trip);
      await syncCancelledInvoicesForTrip(trip);
      await syncInTransitOtpForTrip(trip);
      await syncEndTripOtpForTrip(trip);
      await syncCollectionsForTrip(trip);
      await syncEndTripChecklistForTrip(trip);
      await syncIntransitChecklistForTrip(trip);
      // ---------------------------------------------------------
      // STEP 5 — Save Trip to ObjectBox
      // ---------------------------------------------------------
      final tripObxId = tripBox.put(trip);
      debugPrint(
        "🟦 Trip saved → OBX ID: $tripObxId | Name: ${trip.name}  Delivery Team Ids: ${trip.deliveryTeam.target?.id} DeliveryData Length ${trip.deliveryData.length}",
      );

      // ---------------------------------------------------------
      // STEP 6 — Link Trip to User
      // ---------------------------------------------------------
      LocalUsersModel? user = existingUser;

      if (user == null) {
        debugPrint("⚠️ User not found. Creating new user entry...");
        user = LocalUsersModel(id: userId);
      }

      user.trip.target = trip;
      box.put(user);

      debugPrint(
        "👤 User synced → PB ID: $userId | Trip OBX: ${trip.objectBoxId}",
      );
      debugPrint("✅ LOCAL SYNC COMPLETE → saveUserTripByUserId()");
    } catch (e) {
      debugPrint("❌ ERROR: saveUserTripByUserId() → $e");
      throw CacheException(message: e.toString());
    }
  }
}
