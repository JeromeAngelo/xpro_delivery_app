import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

import '../../../../../../../../services/objectbox.dart';
import '../../../../../checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import '../../../../../delivery_data/invoice_items/data/model/invoice_items_model.dart';
import '../../../../../delivery_team/delivery_team/data/models/delivery_team_model.dart';
import '../../../../../delivery_team/personels/data/models/personel_models.dart';
import '../../../../../otp/intransit_otp/data/models/otp_models.dart';
import '../../../../../delivery_data/delivery_update/data/models/delivery_update_model.dart';
import '../../../../../delivery_data/invoice_data/data/model/invoice_data_model.dart';
import '../../../../trip_updates/data/model/trip_update_model.dart';

abstract class TripLocalDatasource {
  Future<TripModel> loadTrip();
  Future<TripModel> searchTripByNumber(String tripNumberId);
  Future<(TripModel, String)> acceptTrip(String tripId);
  Future<void> saveTrip(TripModel trip);
  Future<void> autoSaveTrip(TripModel trip);

  Future<String> calculateTotalTripDistance(String tripId);
  Future<String?> getTrackingId();
  Future<bool> checkEndTripOtpStatus(String tripId);
  Future<TripModel> getTripById(String id);
  Future<void> endTrip(String tripId);
  Future<TripModel> updateTripLocationLocal(
    String tripId,
    double latitude,
    double longitude, {
    double? accuracy,
    String? source,
    double? totalDistance,
  });
}

class TripLocalDatasourceImpl implements TripLocalDatasource {
  final ObjectBoxStore objectBoxStore;

  Box<LocalUsersModel> get userBox => objectBoxStore.userBox;
  Box<InvoiceItemsModel> get invoiceItemsBox => objectBoxStore.invoiceItemsBox;

  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<DeliveryTeamModel> get deliveryTeamBox => objectBoxStore.deliveryTeamBox;

  Box<DeliveryVehicleModel> get vehicleBox => objectBoxStore.deliveryVehicleBox;
  Box<PersonelModel> get personnelBox => objectBoxStore.personelBox;
  Box<ChecklistModel> get checklistBox => objectBoxStore.checklistBox;
  Box<OtpModel> get otpBox => objectBoxStore.intransitOtpBox;
  Box<EndTripOtpModel> get endTripOtpBox => objectBoxStore.endTripOtpBox;

  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;
  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;
  Box<TripUpdateModel> get tripUpdateBox => objectBoxStore.tripUpdatesBox;

  Box<EndTripChecklistModel> get endTripChecklistBox =>
      objectBoxStore.endTripChecklistBox;
  TripModel? _cachedTrip;
  String? _trackingId;

  SharedPreferences? _sharedPreferences;

  TripLocalDatasourceImpl(this.objectBoxStore);

  // ---------------------------------------------------------------
  // LOCAL: Update trip location (ObjectBox only, no PB)
  // ---------------------------------------------------------------
  @override
  Future<TripModel> updateTripLocationLocal(
    String tripId,
    double latitude,
    double longitude, {
    double? accuracy,
    String? source,
    double? totalDistance,
  }) async {
    try {
      debugPrint(
        "\n================= 📍 LOCAL TRIP LOCATION UPDATE =================",
      );
      debugPrint("🆔 tripId: $tripId");
      debugPrint("📍 Lat: ${latitude.toStringAsFixed(6)}");
      debugPrint("📍 Long: ${longitude.toStringAsFixed(6)}");
      debugPrint("🎯 Accuracy: ${accuracy?.toStringAsFixed(2) ?? 'null'}");
      debugPrint("📡 Source: ${source ?? 'GPS_Enhanced'}");
      debugPrint("🛣 TotalDistance: $totalDistance");
      debugPrint(
        "==============================================================\n",
      );

      // 1️⃣ Get Trip from ObjectBox
      final trip = tripBox.get(int.parse(tripId));

      if (trip == null) {
        debugPrint("❌ Local Trip NOT FOUND for ID: $tripId");
        throw Exception("Trip not found in local DB");
      }

      debugPrint(
        "📦 Local Trip loaded → name: ${trip.name}, numberId: ${trip.tripNumberId}",
      );

      // 2️⃣ Update fields locally
      trip.latitude = latitude;
      trip.longitude = longitude;
      trip.accuracy = accuracy ?? 0;
      trip.source = source ?? "GPS_Enhanced";
      trip.updated = DateTime.now().toIso8601String() as DateTime?;

      // Optional: save total distance if you store it locally
      if (totalDistance != null) {
        trip.tripDistance = totalDistance;
      }

      // 3️⃣ Save back to ObjectBox
      tripBox.put(trip);

      debugPrint("💾 Trip location updated locally!");
      debugPrint("🧭 New Location → ${trip.latitude}, ${trip.longitude}");
      debugPrint("🧩 Updated TripModel saved.");
      debugPrint("================= ✅ LOCAL UPDATE DONE =================\n");

      return trip;
    } catch (e, stack) {
      debugPrint("❌ LOCAL updateTripLocation ERROR: $e");
      debugPrint("🪵 STACK: $stack");
      throw Exception("Local update trip location failed: $e");
    }
  }

  @override
  Future<TripModel> loadTrip() async {
    debugPrint('📱 Attempting to load trip from local storage');

    if (_cachedTrip != null) {
      debugPrint('📦 Returning cached trip: ${_cachedTrip!.tripNumberId}');
      return _cachedTrip!;
    }

    final trips = tripBox.getAll();
    debugPrint('📊 Found ${trips.length} trips in local storage');

    if (trips.isEmpty) {
      throw const CacheException(message: 'No trips found in local storage');
    }

    _cachedTrip = trips.first;
    debugPrint('💾 Loaded trip: ${_cachedTrip!.tripNumberId}');
    return _cachedTrip!;
  }

  @override
  Future<TripModel> searchTripByNumber(String tripNumberId) async {
    debugPrint('🔍 Searching for trip: $tripNumberId');

    final trips = tripBox.getAll().where(
      (trip) => trip.tripNumberId == tripNumberId,
    );

    if (trips.isEmpty) {
      debugPrint('❌ Trip not found: $tripNumberId');
      throw const CacheException(message: 'Trip not found in local storage');
    }

    debugPrint('✅ Found trip: ${trips.first.tripNumberId}');
    return trips.first;
  }

  Future<void> saveUserTripByUserId(String userId, TripModel trip) async {
    try {
      debugPrint("💾 LOCAL SYNC: Saving trip for user ID: $userId");

      // ---------------------------------------------------------
      // STEP 0 — Check if the user already has a Trip
      // ---------------------------------------------------------
      final existingUser =
          userBox
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
        await _removeDuplicateTrips();
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

      // // ---------------------------------------------------------
      // // STEP 3 — Clean related data before inserting new relation data
      // // ---------------------------------------------------------
      await _cleanDeliveryData();
      await _cleanDeliveryTeam();
      await _cleanPersonnel(); //← if needed

      await _cleanChecklistData();

      await _cleanChecklistData();
      // ---------------------------------------------------------
      // STEP 4 — Sync related data
      // ---------------------------------------------------------
      await _syncDeliveryDataForTrip(trip);
      await _syncDeliveryTeamForTrip(trip);
      await _syncVehicleForTrip(trip);
      await _syncPersonnelsForTrip(trip); //← if needed
      await _syncEndTripOtpForTrip(trip);
      await _syncEndTripChecklistForTrip(trip);
      await _syncIntransitChecklistForTrip(trip);
      await _syncInTransitOtpForTrip(trip);
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

      user?.trip.target = trip;
      userBox.put(
        user ?? LocalUsersModel(id: userId)
          ..trip.target = trip,
      );

      debugPrint(
        "👤 User synced → PB ID: $userId | Trip OBX: ${trip.objectBoxId}",
      );
      debugPrint("✅ LOCAL SYNC COMPLETE → saveUserTripByUserId()");
    } catch (e) {
      debugPrint("❌ ERROR: saveUserTripByUserId() → $e");
      throw CacheException(message: e.toString());
    }
  }

  @override
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
        await _removeDuplicateTrips();
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
      await _cleanDeliveryData();
      await _cleanDeliveryTeam();
      await _cleanPersonnel();
      await _cleanTripUpdates();
      await _cleanInTransitOtp();
      //   await _cleanChecklistData();

      // ---------------------------------------------------------
      // STEP 6 — SYNC related entities UNDER TRIP
      // ---------------------------------------------------------
      await _syncDeliveryDataForTrip(trip);
      await _syncDeliveryTeamForTrip(trip);
      await _syncVehicleForTrip(trip);
      await _syncPersonnelsForTrip(trip);
      await _syncInTransitOtpForTrip(trip);
      await _syncEndTripOtpForTrip(trip);
      await _syncTripUpdatesForTrip(trip);

      // ✅ IMPORTANT: Trip checklist (NOT delivery team checklist)
      await _syncIntransitChecklistForTrip(trip);
      await _syncEndTripChecklistForTrip(trip);

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
      _cachedTrip = trip;
      _trackingId = 'local_tracking_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('✅ acceptTrip (INLINE SYNC) COMPLETE');
      return (trip, _trackingId!);
    } catch (e) {
      debugPrint('❌ acceptTrip ERROR → $e');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> saveUser(LocalUsersModel user) async {
    try {
      debugPrint(
        '💾 [OFFLINE-FIRST] Saving user data locally for offline use...',
      );

      final existingUser =
          userBox
              .query(LocalUsersModel_.pocketbaseId.equals(user.pocketbaseId!))
              .build()
              .findFirst();

      LocalUsersModel updatedUser;

      if (existingUser != null) {
        debugPrint('🔄 Updating existing user in ObjectBox: ${user.name}');
        updatedUser = existingUser;

        updatedUser.name = user.name;
        updatedUser.email = user.email;
        updatedUser.tripNumberId = user.tripNumberId;
        updatedUser.token = user.token;

        // ✅ ToOne trip relation update
        updatedUser.trip.target = user.trip.target;

        userBox.put(updatedUser);
      } else {
        debugPrint('➕ Adding new user to ObjectBox: ${user.name}');
        userBox.put(user);
        updatedUser = user;
      }

      debugPrint(
        '✅ User saved in ObjectBox → OBX=${updatedUser.objectBoxId} '
        '| PB=${updatedUser.pocketbaseId} | tripNumberId=${updatedUser.tripNumberId}',
      );

      final userData = {
        'id': updatedUser.id,
        'collectionId': updatedUser.collectionId,
        'collectionName': updatedUser.collectionName,
        'email': updatedUser.email,
        'name': updatedUser.name,
        'tripNumberId': updatedUser.tripNumberId,
        'tokenKey': updatedUser.token,
        'savedOffline': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _sharedPreferences?.setString('user_data', jsonEncode(userData));
      await _sharedPreferences?.setString(
        'auth_token',
        updatedUser.token ?? '',
      );

      final tokenPreview =
          (updatedUser.token ?? '').length >= 10
              ? updatedUser.token!.substring(0, 10)
              : (updatedUser.token ?? '');

      debugPrint('✅ User cached in SharedPreferences');
      debugPrint('   👤 ${updatedUser.name} | 📧 ${updatedUser.email}');
      debugPrint('   🎫 tripNumberId=${updatedUser.tripNumberId}');
      debugPrint(
        '   🔑 token=${tokenPreview.isEmpty ? "(empty)" : "$tokenPreview..."}',
      );
    } catch (e) {
      debugPrint('❌ Failed to save user locally: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  /// --- New helper: clear trips that are no longer in remote
  Future<void> _removeDuplicateTrips() async {
    final allTrips = tripBox.getAll();
    final seen = <String>{};
    for (var trip in allTrips) {
      if (trip.id != null) {
        if (seen.contains(trip.id)) {
          tripBox.remove(trip.objectBoxId); // remove duplicate
        } else {
          seen.add(trip.id!);
        }
      }
    }
    debugPrint('Removed duplicate trips, remaining: ${tripBox.count()}');
  }

  Future<void> _syncVehicleForTrip(TripModel trip) async {
    final vehicle = trip.deliveryVehicle.target;
    if (vehicle == null) return;

    debugPrint(
      '🔍 Syncing vehicle for trip "${trip.name}" → PB: ${vehicle.pocketbaseId}, Name: ${vehicle.name}',
    );

    final existingVehicle =
        vehicleBox
            .query(
              DeliveryVehicleModel_.pocketbaseId.equals(vehicle.pocketbaseId),
            )
            .build()
            .findFirst();

    DeliveryVehicleModel updatedVehicle;

    if (existingVehicle != null) {
      // Load existing vehicle from ObjectBox
      final fullVehicle = vehicleBox.get(existingVehicle.objectBoxId);
      if (fullVehicle != null) {
        // ✅ Update the name (and any other fields you want to sync)
        fullVehicle.name = vehicle.name;
        // Add more fields if needed, e.g., type, plateNumber
        vehicleBox.put(fullVehicle);

        updatedVehicle = fullVehicle;

        debugPrint(
          '🔁 Vehicle updated → PB: ${updatedVehicle.pocketbaseId}, Name: ${updatedVehicle.name}, OBX: ${updatedVehicle.objectBoxId}',
        );
      } else {
        debugPrint(
          '⚠️ Could not load full vehicle for PB: ${vehicle.pocketbaseId}',
        );
        return;
      }
    } else {
      // New vehicle
      final newId = vehicleBox.put(vehicle);
      updatedVehicle = vehicleBox.get(newId)!;

      debugPrint(
        '✅ New vehicle saved → PB: ${updatedVehicle.pocketbaseId}, Name: ${updatedVehicle.name}, OBX: $newId',
      );
    }

    // Assign fully updated vehicle to trip
    trip.deliveryVehicle.target = updatedVehicle; // keep this
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, Vehicle OBX ID: ${trip.deliveryVehicle.targetId}, Vehicle Name Using target: ${trip.deliveryVehicle.target?.name}',
    );
  }

  Future<void> _syncDeliveryTeamForTrip(TripModel trip) async {
    final deliveryTeam = trip.deliveryTeam.target;
    if (deliveryTeam == null) return;

    debugPrint(
      '🔍 Syncing DeliveryTeam for trip "${trip.name}" → PB: ${deliveryTeam.pocketbaseId}, Name: ${deliveryTeam.activeDeliveries}',
    );

    final existingTeam =
        deliveryTeamBox
            .query(
              DeliveryTeamModel_.pocketbaseId.equals(deliveryTeam.pocketbaseId),
            )
            .build()
            .findFirst();

    DeliveryTeamModel updatedTeam;

    if (existingTeam != null) {
      // Load existing DeliveryTeam from ObjectBox
      final fullTeam = deliveryTeamBox.get(existingTeam.objectBoxId);
      if (fullTeam != null) {
        // ✅ Update fields
        fullTeam.id = deliveryTeam.id;
        fullTeam.activeDeliveries = deliveryTeam.activeDeliveries;
        fullTeam.totalDelivered = deliveryTeam.totalDelivered;
        fullTeam.undeliveredCustomers = deliveryTeam.undeliveredCustomers;
        fullTeam.totalDistanceTravelled = deliveryTeam.totalDistanceTravelled;

        // Update personnel and checklist
        fullTeam.personels.clear();
        fullTeam.personels.addAll(deliveryTeam.personels);

        fullTeam.checklist.clear();
        fullTeam.checklist.addAll(deliveryTeam.checklist);

        // Update linked trip
        fullTeam.trip.target = trip;

        deliveryTeamBox.put(fullTeam);
        updatedTeam = fullTeam;

        debugPrint(
          '🔁 DeliveryTeam updated → PB: ${updatedTeam.pocketbaseId}, Name: ${updatedTeam.id}, OBX: ${updatedTeam.objectBoxId}',
        );
      } else {
        debugPrint(
          '⚠️ Could not load full DeliveryTeam for PB: ${deliveryTeam.pocketbaseId}',
        );
        return;
      }
    } else {
      // New DeliveryTeam
      final newId = deliveryTeamBox.put(deliveryTeam);
      updatedTeam = deliveryTeamBox.get(newId)!;

      // Ensure trip relation is set
      updatedTeam.trip.target = trip;

      debugPrint(
        '✅ New DeliveryTeam saved → PB: ${updatedTeam.pocketbaseId}, Name: ${updatedTeam.id}, OBX: $newId',
      );
    }

    // Assign fully updated DeliveryTeam to trip
    trip.deliveryTeam.target = updatedTeam; // keep this
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, DeliveryTeam OBX ID: ${trip.deliveryTeam.targetId}, DeliveryTeam Name Using target: ${trip.deliveryTeam.target?.id}',
    );
  }

  Future<void> _syncTripUpdatesForTrip(TripModel trip) async {
    final List<TripUpdateModel> updatedTripUpdates = [];

    for (var update in trip.tripUpdates) {
      debugPrint(
        '📝 Syncing TripUpdate → Trip: ${trip.name}, PB: ${update.pocketbaseId}, db: ${update.objectBoxId}, Status: ${update.status}',
      );

      final existing =
          tripUpdateBox
              .query(TripUpdateModel_.pocketbaseId.equals(update.pocketbaseId))
              .build()
              .findFirst();

      TripUpdateModel updated;

      if (existing != null) {
        final full = tripUpdateBox.get(existing.objectBoxId);
        if (full != null) {
          // Update fields
          full.status = update.status;
          full.date = update.date;
          full.image = update.image;
          full.description = update.description;
          full.latitude = update.latitude;
          full.longitude = update.longitude;
          full.collectionId = update.collectionId;
          full.collectionName = update.collectionName;
          full.trip.target = trip; // ensure relation
          full.tripId = trip.id;

          tripUpdateBox.put(full);
          updated = full;
          debugPrint(
            '🔁 TripUpdate updated → PB: ${updated.pocketbaseId} (OBX: ${updated.objectBoxId})',
          );
        } else {
          continue;
        }
      } else {
        // New record
        update.trip.target = trip;
        update.tripId = trip.id;
        final newId = tripUpdateBox.put(update);
        updated = tripUpdateBox.get(newId)!;
        debugPrint(
          '✅ New TripUpdate saved → PB: ${updated.pocketbaseId} (OBX: ${updated.objectBoxId})',
        );
      }

      updatedTripUpdates.add(updated);
    }

    // Assign fully updated TripUpdates to trip
    trip.tripUpdates.clear();
    trip.tripUpdates.addAll(updatedTripUpdates);
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, '
      'TripUpdates count: ${trip.tripUpdates.length}',
    );
  }

  Future<void> _syncPersonnelsForTrip(TripModel trip) async {
    final List<PersonelModel> updatedPersonnels = [];

    for (var p in trip.personels) {
      debugPrint(
        '👥 Syncing personnel → Trip: ${trip.name}, PB: ${p.pocketbaseId}, db: ${p.objectBoxId}, Name: ${p.name}',
      );

      final existing =
          personnelBox
              .query(PersonelModel_.pocketbaseId.equals(p.pocketbaseId))
              .build()
              .findFirst();

      PersonelModel updated;

      if (existing != null) {
        final full = personnelBox.get(existing.objectBoxId);
        if (full != null) {
          full.name = p.name;
          full.role = p.role;

          personnelBox.put(full);
          updated = full;

          debugPrint(
            '🔁 Personnel updated → ${updated.name} (OBX: ${updated.objectBoxId})',
          );
        } else {
          continue;
        }
      } else {
        final newId = personnelBox.put(p);
        updated = personnelBox.get(newId)!;

        debugPrint(
          '✅ New personnel saved → ${updated.name} (OBX: ${updated.objectBoxId})',
        );
      }

      updatedPersonnels.add(updated);
    }

    // Assign fully updated personnels to trip
    trip.personels.clear();
    trip.personels.addAll(updatedPersonnels);
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, '
      'Personnels count: ${trip.personels.length}',
    );
  }

  Future<void> _syncDeliveryDataForTrip(TripModel trip) async {
    // ✅ Snapshot first to avoid concurrent modification on ToMany
    final incomingDeliveries = trip.deliveryData.toList();

    // ✅ Ensure trip has OBX id before linking relations
    if (trip.objectBoxId == 0) {
      trip.objectBoxId = tripBox.put(trip);
    }

    final Map<String, DeliveryDataModel> uniqueDeliveries = {};

    for (final d in incomingDeliveries) {
      final deliveryPbId = (d.pocketbaseId).trim();
      if (deliveryPbId.isEmpty) {
        debugPrint('⚠️ Skipping delivery: missing pocketbaseId/id');
        continue;
      }

      debugPrint('📦 Syncing deliveryData → ${d.ownerName} PB: $deliveryPbId');

      // -------------------------------------------------------------
      // 1️⃣ Load existing or create new DeliveryData
      // -------------------------------------------------------------
      final existing =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryPbId))
              .build()
              .findFirst();

      final fresh =
          existing != null
              ? deliveryDataBox.get(existing.objectBoxId)!
              : DeliveryDataModel();

      // Copy base fields
      fresh
        ..id = d.id
        ..pocketbaseId = deliveryPbId
        ..ownerName = d.ownerName
        ..deliveryNumber = d.deliveryNumber
        ..province = d.province
        ..municipality = d.municipality
        ..barangay = d.barangay
        ..paymentMode = d.paymentMode
        ..storeName = d.storeName
        ..updated = d.updated
        ..isUnloaded = d.isUnloaded
        ..isUnloading = d.isUnloading
        ..created = d.created
        ..totalDeliveryTime = d.totalDeliveryTime
        ..tripId = trip.id;

      // ✅ Always link to the current trip instance (avoid extra Trip creation)
      fresh.trip.target = trip;

      // -------------------------------------------------------------
      // 2️⃣ Sync Customer (ToOne)
      // -------------------------------------------------------------
      final cust = d.customer.target;
      if (cust != null) {
        final custPbId = (cust.pocketbaseId).trim();

        if (custPbId.isNotEmpty) {
          final existingCust =
              customerBox
                  .query(CustomerDataModel_.pocketbaseId.equals(custPbId))
                  .build()
                  .findFirst();

          if (existingCust == null) {
            final newCust =
                CustomerDataModel()
                  ..id = cust.id
                  ..pocketbaseId = custPbId
                  ..name = cust.name
                  ..province = cust.province
                  ..municipality = cust.municipality
                  ..barangay = cust.barangay;

            final newId = customerBox.put(newCust);
            fresh.customer.target = customerBox.get(newId);
          } else {
            fresh.customer.target = customerBox.get(existingCust.objectBoxId);
          }
        } else {
          fresh.customer.target = null;
        }
      } else {
        fresh.customer.target = null;
      }

      // -------------------------------------------------------------
      // 3️⃣ Sync Invoices (ToMany) — snapshot first
      // -------------------------------------------------------------
      final invoiceList = <InvoiceDataModel>[];
      final incomingInvoices = d.invoices.toList();

      for (final inv in incomingInvoices) {
        final invPbId = (inv.pocketbaseId).trim();
        if (invPbId.isEmpty) continue;

        final existingInv =
            invoiceBox
                .query(InvoiceDataModel_.pocketbaseId.equals(invPbId))
                .build()
                .findFirst();

        if (existingInv == null) {
          final newInv =
              InvoiceDataModel()
                ..id = inv.id
                ..pocketbaseId = invPbId
                ..name = inv.name
                ..refId = inv.refId
                ..documentDate = inv.documentDate
                ..volume = inv.volume
                ..weight = inv.weight
                ..totalAmount = inv.totalAmount;

          final newId = invoiceBox.put(newInv);
          invoiceList.add(invoiceBox.get(newId)!);
        } else {
          invoiceList.add(invoiceBox.get(existingInv.objectBoxId)!);
        }
      }

      fresh.invoices
        ..clear()
        ..addAll(invoiceList);

      // -------------------------------------------------------------
      // 3️⃣ Sync InvoiceItems (ToMany) — snapshot first + link invoiceData ToOne
      // -------------------------------------------------------------
      final List<InvoiceItemsModel> syncedInvoiceItems = <InvoiceItemsModel>[];

      // If d.invoiceItems is dynamic, make it explicit:
      final List<InvoiceItemsModel> incomingInvoiceItems =
          d.invoiceItems.toList().cast<InvoiceItemsModel>();

      // -------------------------------------------------------------
      // ✅ Build invoice lookup from already-synced fresh.invoices
      // -------------------------------------------------------------
      final Map<String, InvoiceDataModel> invoiceByPbId = {};
      final Map<String, InvoiceDataModel> invoiceById = {};

      try {
        final invs = fresh.invoices.toList();
        for (final inv in invs) {
          final pb = (inv.pocketbaseId).trim();
          final id = (inv.id ?? '').toString().trim();
          if (pb.isNotEmpty) invoiceByPbId[pb] = inv;
          if (id.isNotEmpty) invoiceById[id] = inv;
        }
      } catch (_) {}

      debugPrint(
        '🧾 [INVOICE ITEMS] Incoming invoice items for delivery '
        'PB=$deliveryPbId → count=${incomingInvoiceItems.length}',
      );
      debugPrint(
        '🧾 [INVOICE ITEMS] Invoice lookup: '
        'byPbId=${invoiceByPbId.length}, byId=${invoiceById.length}',
      );

      for (final InvoiceItemsModel inv in incomingInvoiceItems) {
        final invPbId = (inv.pocketbaseId).trim();

        if (invPbId.isEmpty) {
          debugPrint('⚠️ [INVOICE ITEMS] Skipped item with EMPTY pocketbaseId');
          continue;
        }

        // -------------------------------------------------------------
        // ✅ Find the invoice ID from incoming item
        // Priority:
        // 1) inv.invoiceData.target?.pocketbaseId (if expanded)
        // 2) inv.invoiceDataId (raw string)
        // 3) inv.invoiceData.target?.id
        // -------------------------------------------------------------
        String incomingInvoicePbId = '';
        String incomingInvoiceId = '';

        try {
          incomingInvoicePbId = (inv.invoiceData.target?.id ?? '').trim();
        } catch (_) {}

        try {
          incomingInvoiceId = (inv.invoiceDataId ?? '').toString().trim();
        } catch (_) {}

        if (incomingInvoiceId.isEmpty) {
          try {
            incomingInvoiceId =
                (inv.invoiceData.target?.id ?? '').toString().trim();
          } catch (_) {}
        }

        debugPrint(
          '🔍 [INVOICE ITEMS] Processing item PB=$invPbId | name=${inv.name} '
          '| invPb=$incomingInvoicePbId | invId=$incomingInvoiceId',
        );

        // -------------------------------------------------------------
        // ✅ Resolve invoice locally using the maps
        // -------------------------------------------------------------
        InvoiceDataModel? resolvedInvoice;
        if (incomingInvoicePbId.isNotEmpty) {
          resolvedInvoice = invoiceByPbId[incomingInvoicePbId];
        }
        resolvedInvoice ??= invoiceById[incomingInvoiceId];

        if (resolvedInvoice == null &&
            (incomingInvoicePbId.isNotEmpty || incomingInvoiceId.isNotEmpty)) {
          debugPrint(
            '⚠️ [INVOICE ITEMS] No matching invoice found locally for item PB=$invPbId '
            '(invPb=$incomingInvoicePbId, invId=$incomingInvoiceId)',
          );
        }

        // -------------------------------------------------------------
        // ✅ Find existing local InvoiceItem by pocketbaseId
        // -------------------------------------------------------------
        final q =
            invoiceItemsBox
                .query(InvoiceItemsModel_.pocketbaseId.equals(invPbId))
                .build();
        final existingInv = q.findFirst();
        q.close();

        InvoiceItemsModel localItem;

        if (existingInv == null) {
          debugPrint('🆕 [INVOICE ITEMS] Creating new item → PB=$invPbId');

          final newInv =
              InvoiceItemsModel()
                ..id = inv.id
                ..pocketbaseId = invPbId
                ..name = inv.name
                ..brand = inv.brand
                ..refId = inv.refId
                ..uom = inv.uom
                ..quantity = inv.quantity
                ..uomPrice = inv.uomPrice
                ..totalAmount = inv.totalAmount
                ..totalBaseQuantity = inv.totalBaseQuantity
                ..created = inv.created
                ..updated = inv.updated;

          // ✅ LINK invoiceData ToOne + raw field
          if (resolvedInvoice != null) {
            newInv.invoiceData.target = resolvedInvoice;
            newInv.invoiceDataId = (resolvedInvoice.id ?? '').toString();
            debugPrint(
              '🔗 [INVOICE ITEMS] Linked NEW item → invoiceData '
              'pb=${resolvedInvoice.pocketbaseId} id=${resolvedInvoice.id}',
            );
          } else {
            // still store the raw invoiceDataId if present, for future re-link
            if (incomingInvoiceId.isNotEmpty) {
              newInv.invoiceDataId = incomingInvoiceId;
              debugPrint(
                '🧷 [INVOICE ITEMS] NEW item saved with raw invoiceDataId=$incomingInvoiceId (no ToOne link yet)',
              );
            }
          }

          final newObxId = invoiceItemsBox.put(newInv);
          localItem = invoiceItemsBox.get(newObxId)!;
          syncedInvoiceItems.add(localItem);

          debugPrint(
            '✅ [INVOICE ITEMS] Saved new item PB=$invPbId → OBX=$newObxId',
          );
        } else {
          debugPrint(
            '♻️ [INVOICE ITEMS] Existing item found PB=$invPbId → OBX=${existingInv.objectBoxId}',
          );

          // ✅ Load the persisted instance and update fields
          localItem = invoiceItemsBox.get(existingInv.objectBoxId)!;

          localItem
            ..id = inv.id
            ..name = inv.name
            ..brand = inv.brand
            ..refId = inv.refId
            ..uom = inv.uom
            ..quantity = inv.quantity
            ..uomPrice = inv.uomPrice
            ..totalAmount = inv.totalAmount
            ..totalBaseQuantity = inv.totalBaseQuantity
            ..created = inv.created
            ..updated = inv.updated;

          // ✅ Ensure invoice relation is linked
          if (resolvedInvoice != null) {
            localItem.invoiceData.target = resolvedInvoice;
            localItem.invoiceDataId = (resolvedInvoice.id ?? '').toString();

            debugPrint(
              '🔗 [INVOICE ITEMS] Linked EXISTING item → invoiceData '
              'pb=${resolvedInvoice.pocketbaseId} id=${resolvedInvoice.id}',
            );
          } else {
            // keep raw if we have it
            if ((localItem.invoiceDataId ?? '').trim().isEmpty &&
                incomingInvoiceId.isNotEmpty) {
              localItem.invoiceDataId = incomingInvoiceId;
              debugPrint(
                '🧷 [INVOICE ITEMS] EXISTING item stored raw invoiceDataId=$incomingInvoiceId (no ToOne link yet)',
              );
            }
          }

          // ✅ Persist changes
          invoiceItemsBox.put(localItem);
          syncedInvoiceItems.add(localItem);
        }
      }

      // BEFORE attach
      debugPrint(
        '📦 [INVOICE ITEMS] Attaching ${syncedInvoiceItems.length} items '
        'to DeliveryData PB=$deliveryPbId (previous=${fresh.invoiceItems.length})',
      );

      // Attach to delivery
      fresh.invoiceItems
        ..clear()
        ..addAll(syncedInvoiceItems);

      // IMPORTANT: persist parent (depending on your overall flow)
      deliveryDataBox.put(fresh);

      // AFTER attach
      debugPrint(
        '✅ [INVOICE ITEMS] DeliveryData PB=$deliveryPbId now has '
        '${fresh.invoiceItems.length} invoice items',
      );

      // -------------------------------------------------------------
      // ✅ Debug: verify invoice links on first few items
      // -------------------------------------------------------------
      for (int i = 0; i < fresh.invoiceItems.length && i < 5; i++) {
        final it = fresh.invoiceItems[i];
        debugPrint(
          '🧾 [VERIFY] Item ${i + 1}: ${it.name} '
          '| itemPB=${it.pocketbaseId} '
          '| invTarget=${it.invoiceData.target?.id} '
          '| invPB=${it.invoiceData.target?.id} '
          '| invRaw=${it.invoiceDataId}',
        );
      }

      // -------------------------------------------------------------
      // 4️⃣ Sync DeliveryUpdates (ToMany) — snapshot first
      // -------------------------------------------------------------
      final updatesList = <DeliveryUpdateModel>[];
      final incomingUpdates = d.deliveryUpdates.toList();

      // ✅ Cleanup by deliveryDataPbId (this is what forceReload uses)
      try {
        final cleanupQuery =
            deliveryUpdateBox
                .query(
                  DeliveryUpdateModel_.deliveryDataPbId.equals(deliveryPbId),
                )
                .build();

        final existingForDelivery = cleanupQuery.find();
        cleanupQuery.close();

        if (existingForDelivery.isNotEmpty) {
          deliveryUpdateBox.removeMany(
            existingForDelivery.map((e) => e.objectBoxId).toList(),
          );

          debugPrint(
            '🧹 Removed ${existingForDelivery.length} existing DeliveryUpdates for delivery PB:$deliveryPbId',
          );
        }
      } catch (e) {
        debugPrint(
          '⚠️ Failed to cleanup DeliveryUpdates for $deliveryPbId: $e',
        );
      }

      for (final up in incomingUpdates) {
        final upId = (up.id ?? '').trim();
        if (upId.isEmpty) {
          debugPrint('⚠️ Skipping DeliveryUpdate: missing update id');
          continue;
        }

        debugPrint(
          "🕒 PB update → id=$upId, title=${up.title}, time=${up.time}, created=${up.created}",
        );

        final existingUp =
            deliveryUpdateBox
                .query(DeliveryUpdateModel_.id.equals(upId))
                .build()
                .findFirst();

        final model =
            existingUp != null
                ? deliveryUpdateBox.get(existingUp.objectBoxId)!
                : (DeliveryUpdateModel()..id = upId);

        // ✅ CRITICAL for forceReloadDeliveryUpdatesByTripId queries
        model.deliveryDataPbId = deliveryPbId;

        model
          ..title = up.title
          ..subtitle = up.subtitle
          ..time = up.time
          ..created = up.created
          ..updated = up.updated
          ..lastLocalUpdatedAt = up.lastLocalUpdatedAt;

        final savedObxId = deliveryUpdateBox.put(model);
        updatesList.add(deliveryUpdateBox.get(savedObxId)!);

        debugPrint(
          "✅ Saved DeliveryUpdate → id=$upId, deliveryPB=$deliveryPbId, obx=$savedObxId",
        );
      }

      fresh.deliveryUpdates
        ..clear()
        ..addAll(updatesList);

      // -------------------------------------------------------------
      // 5️⃣ Save DeliveryData
      // -------------------------------------------------------------
      final obxId = deliveryDataBox.put(fresh);
      uniqueDeliveries[deliveryPbId] = deliveryDataBox.get(obxId)!;

      debugPrint(
        '🔁 DeliveryData synced → ${fresh.ownerName} OBX: $obxId '
        'Invoices: ${fresh.invoices.length}, Updates: ${fresh.deliveryUpdates.length}',
      );
    }

    // ✅ IMPORTANT: Update Trip relation ONLY AFTER LOOP (prevents concurrent modification)
    trip.deliveryData
      ..clear()
      ..addAll(uniqueDeliveries.values);

    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → ${trip.name} with ${trip.deliveryData.length} delivery items',
    );
  }

  Future<void> _syncIntransitChecklistForTrip(TripModel trip) async {
    // ✅ Snapshot incoming list (same as deliveryData)
    final incomingChecklist = trip.checklist.toList();

    // ✅ Ensure trip has OBX id before relations
    if (trip.objectBoxId == 0) {
      trip.objectBoxId = tripBox.put(trip);
    }

    final Map<String, ChecklistModel> uniqueChecklist = {};

    debugPrint(
      '🧩 Syncing ${incomingChecklist.length} checklist items '
      'for Trip ID: ${trip.id} | Trip OBX: ${trip.objectBoxId}',
    );

    for (final c in incomingChecklist) {
      // ✅ EXACTLY same fallback logic style as deliveryData
      final checklistPbId = ((c.pocketbaseId)).trim();

      if (checklistPbId.isEmpty) {
        debugPrint('⚠️ Skipping checklist: missing pocketbaseId/id');
        continue;
      }

      debugPrint('📋 Syncing checklist → ${c.objectName} PB: $checklistPbId');

      // Load existing or create
      final existing =
          checklistBox
              .query(ChecklistModel_.pocketbaseId.equals(checklistPbId))
              .build()
              .findFirst();

      final ChecklistModel fresh =
          existing != null
              ? checklistBox.get(existing.objectBoxId)!
              : ChecklistModel();

      // Copy fields
      fresh
        ..id = c.id
        ..pocketbaseId = checklistPbId
        ..objectName = c.objectName
        ..description = c.description
        ..status = c.status
        ..isChecked = c.isChecked
        ..timeCompleted = c.timeCompleted
        ..tripId = trip.id;

      // ✅ Link checklist -> trip
      fresh.trip.target = trip;

      // Save checklist
      final obxId = checklistBox.put(fresh);
      uniqueChecklist[checklistPbId] = checklistBox.get(obxId)!;

      debugPrint('✅ Checklist synced → ${fresh.objectName} OBX: $obxId');
    }

    // ✅ Attach to trip and save (like deliveryData)
    trip.checklist
      ..clear()
      ..addAll(uniqueChecklist.values);

    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → ${trip.name} with ${trip.checklist.length} checklist items',
    );
  }

  Future<void> _syncEndTripChecklistForTrip(TripModel trip) async {
    final Map<String, EndTripChecklistModel> uniqueChecklist = {};

    for (final e in trip.endTripChecklist) {
      debugPrint(
        '📋 Syncing End Trip Checklist → Trip: ${trip.name}, PB: ${e.pocketbaseId}, Item: ${e.objectName}',
      );

      // -------------------------------------------------------------
      // 1️⃣ Load existing or create new checklist
      // -------------------------------------------------------------
      EndTripChecklistModel fresh;

      final existing =
          endTripChecklistBox
              .query(EndTripChecklistModel_.pocketbaseId.equals(e.pocketbaseId))
              .build()
              .findFirst();

      if (existing != null) {
        fresh = endTripChecklistBox.get(existing.dbId)!;
        debugPrint('🔁 Existing checklist found → OBX: ${fresh.dbId}');
      } else {
        fresh =
            EndTripChecklistModel()
              ..id = e.id
              ..pocketbaseId = e.pocketbaseId;
        debugPrint('🆕 Creating new end trip checklist locally');
      }

      // -------------------------------------------------------------
      // 2️⃣ Copy fields
      // -------------------------------------------------------------
      fresh.objectName = e.objectName;
      fresh.description = e.description;
      fresh.status = e.status;
      fresh.isChecked = e.isChecked;
      fresh.timeCompleted = e.timeCompleted;

      // -------------------------------------------------------------
      // 3️⃣ Sync Trip relation
      // -------------------------------------------------------------
      if (e.tripModel != null) {
        final remoteTrip = e.tripModel!;

        final tripQuery =
            tripBox
                .query(
                  TripModel_.pocketbaseId.equals(remoteTrip.pocketbaseId ?? ''),
                )
                .build();
        final existingTrip = tripQuery.findFirst();
        tripQuery.close();

        if (existingTrip == null) {
          final newTrip =
              TripModel()
                ..id = remoteTrip.id
                ..pocketbaseId = remoteTrip.pocketbaseId
                ..name = remoteTrip.name;

          final newTripId = tripBox.put(newTrip);
          fresh.tripModel = tripBox.get(newTripId);

          debugPrint('✅ Trip created & linked → ${newTrip.name}');
        } else {
          fresh.tripModel = tripBox.get(existingTrip.objectBoxId);
          debugPrint('ℹ️ Trip linked → ${existingTrip.name}');
        }
      } else {
        fresh.tripModel = null;
        debugPrint('⚠️ Checklist has no linked trip');
      }

      // -------------------------------------------------------------
      // 4️⃣ Save checklist
      // -------------------------------------------------------------
      final obxId = endTripChecklistBox.put(fresh);
      uniqueChecklist[fresh.pocketbaseId] = endTripChecklistBox.get(obxId)!;

      debugPrint('✅ End checklist synced → ${fresh.objectName} (OBX: $obxId)');
    }

    // -------------------------------------------------------------
    // 5️⃣ Assign checklist to trip & save
    // -------------------------------------------------------------
    trip.endTripChecklist
      ..clear()
      ..addAll(uniqueChecklist.values);
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → ${trip.name} with ${trip.endTripChecklist.length} end checklist items',
    );
  }

  Future<void> _syncInTransitOtpForTrip(TripModel trip) async {
    final otp = trip.otp.target;
    if (otp == null) return;

    debugPrint(
      '🔍 Syncing InTransit OTP for trip "${trip.name}" '
      '→ OTP ID: ${otp.id}, Verified: ${otp.isVerified}',
    );

    // -------------------------------------------------
    // 1️⃣ Find existing OTP by PB ID
    // -------------------------------------------------
    final existingOtp =
        otpBox.query(OtpModel_.id.equals(otp.id)).build().findFirst();

    OtpModel syncedOtp;

    if (existingOtp != null) {
      // -------------------------------------------------
      // 2️⃣ Update existing OTP
      // -------------------------------------------------
      final fullOtp = otpBox.get(existingOtp.dbId);
      if (fullOtp == null) {
        debugPrint('⚠️ Failed to load existing OTP from ObjectBox');
        return;
      }

      fullOtp
        ..otpCode = otp.otpCode
        ..generatedCode = otp.generatedCode
        ..isVerified = otp.isVerified
        ..createdAt = otp.createdAt
        ..expiresAt = otp.expiresAt
        ..verifiedAt = otp.verifiedAt
        ..otpType = otp.otpType;

      // Link trip
      fullOtp.trip.target = trip;
      fullOtp.trip.targetId = trip.objectBoxId;

      otpBox.put(fullOtp);
      syncedOtp = fullOtp;

      debugPrint(
        '🔁 OTP updated → PB: ${syncedOtp.id}, OBX: ${syncedOtp.dbId}, '
        'Verified: ${syncedOtp.isVerified}',
      );
    } else {
      // -------------------------------------------------
      // 3️⃣ New OTP
      // -------------------------------------------------
      otp.trip.target = trip;
      otp.trip.targetId = trip.objectBoxId;

      final newOtpId = otpBox.put(otp);
      syncedOtp = otpBox.get(newOtpId)!;

      debugPrint(
        '✅ New OTP saved → PB: ${syncedOtp.id}, OBX: $newOtpId, '
        'Verified: ${syncedOtp.isVerified}',
      );
    }

    // -------------------------------------------------
    // 4️⃣ Attach OTP back to Trip
    // -------------------------------------------------
    trip.otp.target = syncedOtp;
    trip.otp.targetId = syncedOtp.dbId;
    tripBox.put(trip);

    debugPrint(
      '🟦 OTP linked to Trip → '
      'Trip ID: ${trip.id}, OBX: ${trip.objectBoxId}, '
      'OTP OBX: ${trip.otp.targetId}, '
      'OTP Code: ${syncedOtp.otpCode}, '
      'Verified: ${syncedOtp.isVerified}',
    );
  }


  Future<void> _syncEndTripOtpForTrip(TripModel trip) async {
    final endOtp = trip.endTripOtp.target;
    if (endOtp == null) return;

    debugPrint(
      '🔐 Syncing End Trip OTP → Trip: ${trip.name}, PB: ${endOtp.id}',
    );

    final existing =
        endTripOtpBox
            .query(EndTripOtpModel_.id.equals(endOtp.id))
            .build()
            .findFirst();

    EndTripOtpModel updated;

    if (existing != null) {
      final full = endTripOtpBox.get(existing.dbId);
      if (full != null) {
        full.otpCode = endOtp.otpCode;
        full.expiresAt = endOtp.expiresAt;
        full.tripId = trip.id;

        endTripOtpBox.put(full);
        updated = full;

        debugPrint('🔁 End OTP updated → OBX: ${updated.dbId}');
      } else {
        return;
      }
    } else {
      endOtp.tripId = trip.id;
      final newId = endTripOtpBox.put(endOtp);
      updated = endTripOtpBox.get(newId)!;

      debugPrint('✅ New End OTP saved → OBX: ${updated.dbId}');
    }

    // Assign fully updated End OTP to trip
    trip.endTripOtp.target = updated;
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, '
      'End OTP OBX ID: ${trip.endTripOtp.target?.dbId}',
    );
  }

  /// 🧹 Clean Personnel table:
  ///    1. Remove items with NULL/EMPTY pocketbaseId
  ///    2. Remove duplicates using pocketbaseId
  Future<void> _cleanPersonnel() async {
    try {
      final allPersonnel = personnelBox.getAll();

      final seen = <String, PersonelModel>{};

      for (var p in allPersonnel) {
        final pbId = p.pocketbaseId.trim();

        // 🔴 Step 1 — Remove personnel with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL Personnel → '
            'Name: ${p.name}, OBX: ${p.objectBoxId}',
          );
          personnelBox.remove(p.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate personnel
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate Personnel → Removing ${p.name} '
            '(PB: $pbId, OBX: ${p.objectBoxId})',
          );
          personnelBox.remove(p.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = p;
      }

      debugPrint(
        '🟢 Personnel cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanPersonnel error: $e');
    }
  }

  /// 🧹 Clean TripUpdate table:
  /// 1️⃣ Remove items with NULL/EMPTY pocketbaseId
  /// 2️⃣ Remove duplicates using pocketbaseId
  Future<void> _cleanTripUpdates() async {
    try {
      final allUpdates = tripUpdateBox.getAll();

      final seen = <String, TripUpdateModel>{};

      for (var u in allUpdates) {
        final pbId = u.pocketbaseId.trim();

        // 🔴 Step 1 — Remove TripUpdate with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL TripUpdate → '
            'Status: ${u.status}, OBX: ${u.objectBoxId}',
          );
          tripUpdateBox.remove(u.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate TripUpdates
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate TripUpdate → Removing PB: $pbId '
            '(OBX: ${u.objectBoxId})',
          );
          tripUpdateBox.remove(u.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = u;
      }

      debugPrint(
        '🟢 TripUpdate cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanTripUpdates error: $e');
    }
  }

  /// 🧹 Clean DeliveryTeam table:
  ///    1. Remove items with NULL/EMPTY pocketbaseId
  ///    2. Remove duplicates using pocketbaseId
  Future<void> _cleanDeliveryTeam() async {
    try {
      final allTeams = deliveryTeamBox.getAll();

      final seen = <String, DeliveryTeamModel>{};

      for (var team in allTeams) {
        final pbId = team.pocketbaseId.trim();

        // 🔴 Step 1 — Remove team with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL DeliveryTeam → '
            'Name: ${team.id}, OBX: ${team.objectBoxId}',
          );
          deliveryTeamBox.remove(team.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate teams
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate DeliveryTeam → Removing ${team.id} '
            '(PB: $pbId, OBX: ${team.objectBoxId})',
          );
          deliveryTeamBox.remove(team.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = team;
      }

      debugPrint(
        '🟢 DeliveryTeam cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanDeliveryTeam error: $e');
    }
  }

  Future<void> _cleanChecklistData() async {
    try {
      final allChecklist = checklistBox.getAll();

      final seen = <String, ChecklistModel>{};

      for (final c in allChecklist) {
        final pbId = c.pocketbaseId.trim();

        // 🔴 Step 1 — Remove checklist with NULL / empty PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL Checklist → '
            'OBX: ${c.objectBoxId}, Name: ${c.objectName}',
          );
          checklistBox.remove(c.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate checklist (same PB ID)
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate Checklist → Removing OBX: ${c.objectBoxId} '
            '(PB: $pbId, Name: ${c.objectName})',
          );
          checklistBox.remove(c.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = c;
      }

      debugPrint(
        '🟢 Checklist cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanChecklistData error: $e');
    }
  }

  Future<void> _cleanDeliveryData() async {
    try {
      final allData = deliveryDataBox.getAll();

      final seen = <String, DeliveryDataModel>{};

      for (var d in allData) {
        final pbId = d.pocketbaseId.trim();

        // 🔴 Step 1 — Remove Delivery Data with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL DeliveryData → '
            'OBX: ${d.objectBoxId}, Customer: ${d.ownerName}',
          );
          deliveryDataBox.remove(d.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate Delivery Data
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate DeliveryData → Removing OBX: ${d.objectBoxId} '
            '(PB: $pbId, Customer: ${d.ownerName})',
          );
          deliveryDataBox.remove(d.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = d;
      }

      debugPrint(
        '🟢 DeliveryData cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanDeliveryData error: $e');
    }
  }

  Future<void> _cleanInTransitOtp() async {
    try {
      final allOtps = otpBox.getAll();

      final seen = <String, OtpModel>{};

      for (final otp in allOtps) {
        final pbId = otp.id.trim();

        // 🔴 Step 1 — Remove OTP with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL InTransit OTP → '
            'OBX: ${otp.dbId}, Code: ${otp.otpCode}',
          );
          otpBox.remove(otp.dbId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate OTPs
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate InTransit OTP → Removing '
            '(PB: $pbId, OBX: ${otp.dbId})',
          );
          otpBox.remove(otp.dbId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = otp;
      }

      debugPrint(
        '🟢 InTransit OTP cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e, st) {
      debugPrint('❌ _cleanInTransitOtp ERROR: $e\n$st');
    }
  }

  // Add method to sync remote data after trip acceptance
  Future<void> syncRemoteTripData(TripModel remoteTripData) async {
    try {
      debugPrint('🔄 Syncing remote trip data to local storage');

      // Load the current local trip
      final localTrip = await loadTrip();

      // ---------------------------------------------------------
      // SYNC DELIVERY DATA
      // ---------------------------------------------------------
      if (remoteTripData.deliveryData.isNotEmpty) {
        for (final deliveryData in remoteTripData.deliveryData) {
          deliveryData.tripId = localTrip.id;

          // Sync CUSTOMER (toOne)
          if (deliveryData.customer.target != null) {
            customerBox.put(deliveryData.customer.target!);
            debugPrint('✅ Synced customer ${deliveryData.customer.target!.id}');
          }

          // Sync INVOICE (toOne)
          if (deliveryData.invoice.target != null) {
            invoiceBox.put(deliveryData.invoice.target!);
            debugPrint('✅ Synced invoice ${deliveryData.invoice.target!.id}');
          }

          deliveryDataBox.put(deliveryData);
        }

        debugPrint(
          '✅ Synced ${remoteTripData.deliveryData.length} delivery data records',
        );
      }

      // ---------------------------------------------------------
      // SYNC PERSONNEL
      // ---------------------------------------------------------
      if (remoteTripData.personels.isNotEmpty) {
        for (final personnel in remoteTripData.personels) {
          personnel.tripId = localTrip.id;
          personnelBox.put(personnel);
        }
        debugPrint('✅ Synced ${remoteTripData.personels.length} personnel');
      }

      // ---------------------------------------------------------
      // SYNC DELIVERY TEAM
      // ---------------------------------------------------------
      if (remoteTripData.deliveryTeam.target != null) {
        final remoteTeam = remoteTripData.deliveryTeam.target!;
        remoteTeam.tripId = localTrip.id;

        deliveryTeamBox.put(remoteTeam);
        debugPrint('✅ Synced delivery team ${remoteTeam.id}');
      }

      // ---------------------------------------------------------
      // UPDATE TRIP RELATIONSHIPS
      // ---------------------------------------------------------
      final updatedTrip = localTrip.copyWith(
        deliveryDataList: remoteTripData.deliveryData,
        personelsList: remoteTripData.personels,
      );

      // Update delivery team (toOne)
      if (remoteTripData.deliveryTeam.target != null) {
        updatedTrip.deliveryTeam.target = remoteTripData.deliveryTeam.target;
      }

      // Update to-many relations properly
      updatedTrip.deliveryData.clear();
      updatedTrip.deliveryData.addAll(remoteTripData.deliveryData);

      updatedTrip.personels.clear();
      updatedTrip.personels.addAll(remoteTripData.personels);

      // Save trip
      tripBox.put(updatedTrip);
      _cachedTrip = updatedTrip;

      debugPrint('✅ Remote trip data synced successfully');
    } catch (e) {
      debugPrint('❌ Failed to sync remote trip data: $e');
      throw CacheException(message: 'Failed to sync remote trip data: $e');
    }
  }

  Future<TripModel> getCompleteTripData() async {
    try {
      debugPrint('📦 Loading complete trip data with all relationships');

      final trip = await loadTrip();

      if (trip.objectBoxId == 0) {
        throw CacheException(message: 'Trip not found in local storage');
      }

      // -------------------------------------------------------------
      // 1️⃣ Fetch DeliveryData linked to the trip
      // -------------------------------------------------------------
      final deliverySet = <String, DeliveryDataModel>{};
      for (final d in trip.deliveryData) {
        final fullDD = deliveryDataBox.get(d.objectBoxId);
        if (fullDD != null) {
          deliverySet[fullDD.id ?? ''] = fullDD;
        }
      }

      // -------------------------------------------------------------
      // 2️⃣ Fetch Personnels linked to the trip
      // -------------------------------------------------------------
      final personnelSet = <String, PersonelModel>{};
      for (final p in trip.personels) {
        final fullP = personnelBox.get(p.objectBoxId);
        if (fullP != null) {
          personnelSet[fullP.id ?? ''] = fullP;
        }
      }

      // -------------------------------------------------------------
      // 3️⃣ Fetch DeliveryTeam linked to the trip
      // -------------------------------------------------------------
      DeliveryTeamModel? deliveryTeam;
      if (trip.deliveryTeam.target != null) {
        final fullTeam = deliveryTeamBox.get(
          trip.deliveryTeam.target!.objectBoxId,
        );
        if (fullTeam != null) deliveryTeam = fullTeam;
      }

      debugPrint('📊 Complete trip data loaded:');
      debugPrint('   🚛 Delivery Data: ${deliverySet.length}');
      debugPrint('   👥 Personnel: ${personnelSet.length}');
      debugPrint('   👨‍💼 Delivery Team: ${deliveryTeam?.id ?? 'None'}');

      // -------------------------------------------------------------
      // 4️⃣ Build complete trip model
      // -------------------------------------------------------------
      final completeTrip = trip.copyWith(
        deliveryDataList: deliverySet.values.toList(),
        personelsList: personnelSet.values.toList(),
      );

      // Attach relations
      if (deliveryTeam != null) {
        completeTrip.deliveryTeam.target = deliveryTeam;
      }

      completeTrip.deliveryData
        ..clear()
        ..addAll(deliverySet.values);
      completeTrip.personels
        ..clear()
        ..addAll(personnelSet.values);

      return completeTrip;
    } catch (e, st) {
      debugPrint('❌ Failed to load complete trip data: $e\n$st');
      throw CacheException(message: 'Failed to load complete trip data: $e');
    }
  }

  @override
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

  @override
  Future<void> saveTrip(TripModel trip) async {
    try {
      debugPrint('💾 LOCAL: Starting trip save');

      if (trip.deliveryTeam.target != null) {
        final deliveryTeamBoxs = deliveryTeamBox;
        final deliveryTeam = trip.deliveryTeam.target!;
        deliveryTeam.tripId = trip.id;

        final deliveryTeamId = deliveryTeamBoxs.put(deliveryTeam);
        debugPrint('✅ LOCAL: Stored delivery team with ID: ${deliveryTeam.id}');
        debugPrint('📦 LOCAL: ObjectBox ID: $deliveryTeamId');
      }

      final tripId = tripBox.put(trip);
      debugPrint('✅ LOCAL: Stored trip with ID: ${trip.id}');
      debugPrint('📦 LOCAL: ObjectBox ID: $tripId');

      // Verify storage
      final storedTrip = tripBox.get(tripId);
      debugPrint('📊 LOCAL: Storage verification:');
      debugPrint('   🚛 Delivery Team: ${storedTrip?.deliveryTeam.target?.id}');
      debugPrint('   👥 Personnel: ${storedTrip?.personels.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Save failed - $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> autoSaveTrip(TripModel trip) async {
    try {
      debugPrint('🔄 Auto-saving trip data: ${trip.tripNumberId}');

      // Clear existing trips
      tripBox.removeAll();

      final tripId = trip.id;

      // -------------------------------------------------------------
      // SAVE DELIVERY TEAM
      // -------------------------------------------------------------
      if (trip.deliveryTeam.target != null) {
        final deliveryTeam = trip.deliveryTeam.target!;
        deliveryTeam.tripId = tripId;
        deliveryTeamBox.put(deliveryTeam);
        debugPrint('✅ Saved delivery team: ${deliveryTeam.id}');
      }

      // -------------------------------------------------------------
      // SAVE DELIVERY DATA + CUSTOMER + INVOICE
      // -------------------------------------------------------------
      if (trip.deliveryData.isNotEmpty) {
        for (final delivery in trip.deliveryData) {
          delivery.tripId = tripId;

          if (delivery.customer.target != null) {
            customerBox.put(delivery.customer.target!);
          }

          if (delivery.invoice.target != null) {
            invoiceBox.put(delivery.invoice.target!);
          }

          deliveryDataBox.put(delivery);
        }

        debugPrint('✅ Saved ${trip.deliveryData.length} delivery data records');
      }

      // -------------------------------------------------------------
      // SAVE OTP
      // -------------------------------------------------------------
      if (trip.otp.target != null) {
        final otp = trip.otp.target!;
        otp.tripId = tripId;
        otpBox.put(otp);
        debugPrint('✅ Saved OTP: ${otp.id}');
      }

      // -------------------------------------------------------------
      // SAVE END TRIP OTP
      // -------------------------------------------------------------
      if (trip.endTripOtp.target != null) {
        final endTripOtp = trip.endTripOtp.target!;
        endTripOtp.tripId = tripId;
        endTripOtpBox.put(endTripOtp);
        debugPrint('✅ Saved End Trip OTP: ${endTripOtp.id}');
      }

      // -------------------------------------------------------------
      // SAVE PERSONNEL
      // -------------------------------------------------------------
      if (trip.personels.isNotEmpty) {
        for (final personnel in trip.personels) {
          personnel.tripId = tripId;
          personnelBox.put(personnel);
        }

        debugPrint('✅ Saved ${trip.personels.length} personnel');
      }

      // -------------------------------------------------------------
      // SAVE CHECKLIST ITEMS
      // -------------------------------------------------------------
      if (trip.checklist.isNotEmpty) {
        for (final item in trip.checklist) {
          //item.trip = tripId;
          checklistBox.put(item);
        }

        debugPrint('✅ Saved ${trip.checklist.length} checklist items');
      }

      // -------------------------------------------------------------
      // SAVE THE TRIP ITSELF
      // -------------------------------------------------------------
      final tripToSave = TripModel(
        id: trip.id,
        collectionId: trip.collectionId,
        collectionName: trip.collectionName,
        tripNumberId: trip.tripNumberId,
        totalTripDistance: trip.totalTripDistance,
        qrCode: trip.qrCode,
        created: trip.created,
        updated: trip.updated,
        isAccepted: true,
        timeAccepted: trip.timeAccepted ?? DateTime.now(),
        isEndTrip: trip.isEndTrip,
        timeEndTrip: trip.timeEndTrip,
        objectBoxId: 1,
      );

      final savedTripId = tripBox.put(tripToSave);

      debugPrint('✅ Trip saved with ID: $savedTripId');

      _cachedTrip = tripToSave;

      // -------------------------------------------------------------
      // VERIFY SAVE
      // -------------------------------------------------------------
      final savedTrip = tripBox.get(savedTripId);

      if (savedTrip != null) {
        debugPrint('✅ Trip verification successful');
        debugPrint('   🎫 Trip Number: ${savedTrip.tripNumberId}');
        debugPrint('   🔢 Trip ID: ${savedTrip.id}');
        debugPrint('   ✓ Is Accepted: ${savedTrip.isAccepted}');
      } else {
        debugPrint('❌ Trip verification failed — not found after save');
      }

      // -------------------------------------------------------------
      // UPDATE SHARED PREFERENCES
      // -------------------------------------------------------------
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData != null) {
        try {
          final userData = jsonDecode(storedUserData);

          userData['tripNumberId'] = trip.tripNumberId;
          userData['trip'] = {'id': trip.id, 'tripNumberId': trip.tripNumberId};

          await prefs.setString('user_data', jsonEncode(userData));
          debugPrint('✅ Updated user data in SharedPreferences with trip info');
        } catch (e) {
          debugPrint('❌ Failed to update SharedPreferences: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Auto-save failed: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<String?> getTrackingId() async {
    debugPrint('🔍 Retrieving tracking ID');
    return _trackingId;
  }

  @override
  Future<bool> checkEndTripOtpStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end trip OTP status for: $tripId');

      final trips = tripBox.getAll().where((trip) => trip.id == tripId);
      if (trips.isEmpty) {
        throw const CacheException(message: 'Trip not found in local storage');
      }

      final trip = trips.first;
      final hasEndTripOtp = trip.endTripOtp.target != null;
      final isEndTrip = trip.isEndTrip;

      debugPrint('📊 End Trip Status Check:');
      debugPrint('Has End Trip OTP: $hasEndTripOtp');
      debugPrint('Is End Trip: $isEndTrip');

      return hasEndTripOtp && isEndTrip!;
    } catch (e) {
      debugPrint('❌ End trip status check failed: $e');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> cacheDeliveryDataForTrip(String tripId) async {
    try {
      debugPrint('📦 Caching delivery data for trip: $tripId');

      // You'll need to fetch delivery data from remote and cache it
      // This should be called after trip acceptance

      // Example of how to cache delivery data:
      // final deliveryDataBox = _store.box<DeliveryDataModel>();
      // final customerBox = _store.box<CustomerModel>();
      // final invoiceBox = _store.box<InvoiceModel>();

      // Fetch delivery data from remote source (you'll need to implement this)
      // final remoteDeliveryData = await _fetchDeliveryDataFromRemote(tripId);

      // Cache customers first
      // for (final delivery in remoteDeliveryData) {
      //   if (delivery.customerData != null) {
      //     customerBox.put(delivery.customerData!);
      //   }
      //   if (delivery.invoiceData != null) {
      //     invoiceBox.put(delivery.invoiceData!);
      //   }
      // }

      // Then cache delivery data with relationships
      // deliveryDataBox.putMany(remoteDeliveryData);

      debugPrint('✅ Delivery data cached successfully');
    } catch (e) {
      debugPrint('❌ Failed to cache delivery data: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<String> calculateTotalTripDistance(String tripId) async {
    try {
      debugPrint('📊 LOCAL: Calculating total trip distance');
      final trip =
          tripBox
              .query(TripModel_.pocketbaseId.equals(tripId))
              .build()
              .findFirst();

      if (trip != null) {
        final startOdometer = trip.otp.target?.intransitOdometer ?? '0';
        final endOdometer = trip.endTripOtp.target?.endTripOdometer ?? '0';

        final totalDistance =
            (int.parse(endOdometer) - int.parse(startOdometer)).toString();
        trip.totalTripDistance = totalDistance;

        tripBox.put(trip);
        debugPrint(
          '✅ LOCAL: Total trip distance calculated: $totalDistance km',
        );
        return totalDistance;
      } else {
        throw const CacheException(message: 'Trip not found in local storage');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to calculate trip distance: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
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
      _cachedTrip = null;
      _trackingId = null;

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
