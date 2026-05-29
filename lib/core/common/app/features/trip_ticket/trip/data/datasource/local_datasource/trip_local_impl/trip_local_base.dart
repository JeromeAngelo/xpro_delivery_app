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

import '../../../../../../../../../services/objectbox.dart';
import '../../../../../../checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import '../../../../../../delivery_data/invoice_items/data/model/invoice_items_model.dart';
import '../../../../../../delivery_team/delivery_team/data/models/delivery_team_model.dart';
import '../../../../../../delivery_team/personels/data/models/personel_models.dart';
import '../../../../../../otp/intransit_otp/data/models/otp_models.dart';
import '../../../../../../delivery_data/delivery_update/data/models/delivery_update_model.dart';
import '../../../../../../delivery_data/invoice_data/data/model/invoice_data_model.dart';
import '../../../../../trip_updates/data/model/trip_update_model.dart';

abstract class TripLocalBase {
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

  TripModel? cachedTrip;
  String? trackingId;

  SharedPreferences? sharedPreferences;

  TripLocalBase(this.objectBoxStore);

  // ================================================================
  // HELPER METHODS (formerly private, now public for mixin access)
  // ================================================================

  /// Save user data locally (ObjectBox + SharedPreferences)
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

      await sharedPreferences?.setString('user_data', jsonEncode(userData));
      await sharedPreferences?.setString('auth_token', updatedUser.token ?? '');

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

  /// Save user trip by user ID
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

      // // ---------------------------------------------------------
      // // STEP 3 — Clean related data before inserting new relation data
      // // ---------------------------------------------------------
      await cleanDeliveryData();
      await cleanDeliveryTeam();
      await cleanPersonnel(); //← if needed

      await cleanChecklistData();

      await cleanChecklistData();
      // ---------------------------------------------------------
      // STEP 4 — Sync related data
      // ---------------------------------------------------------
      await syncDeliveryDataForTrip(trip);
      await syncDeliveryTeamForTrip(trip);
      await syncVehicleForTrip(trip);
      await syncPersonnelsForTrip(trip); //← if needed
      await syncEndTripOtpForTrip(trip);
      await syncEndTripChecklistForTrip(trip);
      await syncIntransitChecklistForTrip(trip);
      await syncOtpForTrip(trip);
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

  /// Sync remote trip data after trip acceptance
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
      cachedTrip = updatedTrip;

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

  /// 🧹 Clear trips that are no longer in remote
  Future<void> removeDuplicateTrips() async {
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

  Future<void> syncVehicleForTrip(TripModel trip) async {
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

  Future<void> syncDeliveryTeamForTrip(TripModel trip) async {
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

  Future<void> syncTripUpdatesForTrip(TripModel trip) async {
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

  Future<void> syncPersonnelsForTrip(TripModel trip) async {
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

  Future<void> syncDeliveryDataForTrip(TripModel trip) async {
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

  Future<void> syncIntransitChecklistForTrip(TripModel trip) async {
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

  Future<void> syncEndTripChecklistForTrip(TripModel trip) async {
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

  Future<void> syncOtpForTrip(TripModel trip) async {
    final otp = trip.otp.target;
    if (otp == null) return;

    debugPrint('🔐 Syncing OTP → Trip: ${trip.name}, PB: ${otp.id}');

    final existing =
        otpBox.query(OtpModel_.id.equals(otp.id)).build().findFirst();

    OtpModel updated;

    if (existing != null) {
      final full = otpBox.get(existing.dbId);
      if (full != null) {
        full.otpCode = otp.otpCode;
        full.expiresAt = otp.expiresAt;
        full.tripId = trip.id;

        otpBox.put(full);
        updated = full;

        debugPrint('🔁 OTP updated → OBX: ${updated.dbId}');
      } else {
        return;
      }
    } else {
      otp.tripId = trip.id;
      final newId = otpBox.put(otp);
      updated = otpBox.get(newId)!;

      debugPrint('✅ New OTP saved → OBX: ${updated.dbId}');
    }

    // Assign fully updated OTP to trip
    trip.otp.target = updated;
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, '
      'OTP OBX ID: ${trip.otp.target?.dbId}',
    );
  }

  Future<void> syncEndTripOtpForTrip(TripModel trip) async {
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
  Future<void> cleanPersonnel() async {
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
      debugPrint('❌ cleanPersonnel error: $e');
    }
  }

  /// 🧹 Clean TripUpdate table:
  /// 1️⃣ Remove items with NULL/EMPTY pocketbaseId
  /// 2️⃣ Remove duplicates using pocketbaseId
  Future<void> cleanTripUpdates() async {
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
      debugPrint('❌ cleanTripUpdates error: $e');
    }
  }

  /// 🧹 Clean DeliveryTeam table:
  ///    1. Remove items with NULL/EMPTY pocketbaseId
  ///    2. Remove duplicates using pocketbaseId
  Future<void> cleanDeliveryTeam() async {
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
      debugPrint('❌ cleanDeliveryTeam error: $e');
    }
  }

  Future<void> cleanChecklistData() async {
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
      debugPrint('❌ cleanChecklistData error: $e');
    }
  }

  Future<void> cleanDeliveryData() async {
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
      debugPrint('❌ cleanDeliveryData error: $e');
    }
  }

  /// Calculate trip total time from timeAccepted to OTP verification time
  Future<void> calculateAndStoreTripTotalTime(TripModel trip) async {
    try {
      // Get verification time from EndTripOtp or Otp
      final verifiedAt =
          trip.endTripOtp.target?.verifiedAt ?? trip.otp.target?.verifiedAt;
      final timeAccepted = trip.timeAccepted;

      if (verifiedAt == null || timeAccepted == null) {
        debugPrint(
          '⚠️ Cannot calculate tripTotalTime: verifiedAt=$verifiedAt, timeAccepted=$timeAccepted',
        );
        return;
      }

      // Calculate duration
      final duration = verifiedAt.difference(timeAccepted);
      trip.tripTotalTime = duration.toString() as String?;

      debugPrint(
        '⏱️ Trip Total Time Calculated: ${trip.tripTotalTime} '
        '(Start: $timeAccepted, End: $verifiedAt)',
      );

      // Update trip in ObjectBox
      tripBox.put(trip);
    } catch (e) {
      debugPrint('❌ Error calculating trip total time: $e');
    }
  }

  // loadTrip is implemented by LoadTripImpl mixin
  Future<TripModel> loadTrip();
}
