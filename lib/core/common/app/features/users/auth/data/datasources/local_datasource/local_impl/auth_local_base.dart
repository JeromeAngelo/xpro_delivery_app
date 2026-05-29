import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../../../../services/objectbox.dart';
import '../../../../../../checklists/intransit_checklist/data/model/checklist_model.dart';
import '../../../../../../delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import '../../../../../../delivery_data/invoice_items/data/model/invoice_items_model.dart';
import '../../../../../../otp/end_trip_otp/data/model/end_trip_model.dart';
import '../../../../../../trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import '../../../../../../trip_ticket/delivery_collection/data/model/collection_model.dart';
import '../../../../../../trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import '../../../../../../checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import '../../../../../../delivery_data/delivery_update/data/models/delivery_update_model.dart';
import '../../../../../../delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../../../delivery_team/personels/data/models/personel_models.dart';
import '../../../../../../otp/intransit_otp/data/models/otp_models.dart';
import '../../../../../../trip_ticket/trip_updates/data/model/trip_update_model.dart';

/// Base class that holds the shared ObjectBox store, boxes, SharedPreferences,
/// and all private helper methods used across auth local data source implementations.
class AuthLocalBase {
  final ObjectBoxStore objectBoxStore;
  final Box<LocalUsersModel> box;
  final SharedPreferences prefs;

  Box<ChecklistModel> get checklistBox => objectBoxStore.checklistBox;

  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<DeliveryTeamModel> get deliveryTeamBox => objectBoxStore.deliveryTeamBox;

  Box<DeliveryVehicleModel> get vehicleBox => objectBoxStore.deliveryVehicleBox;
  Box<PersonelModel> get personnelBox => objectBoxStore.personelBox;
  Box<OtpModel> get otpBox => objectBoxStore.store.box<OtpModel>();
  Box<EndTripOtpModel> get endTripOtpBox => objectBoxStore.endTripOtpBox;

  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;

  Box<InvoiceItemsModel> get invoiceItemsBox => objectBoxStore.invoiceItemsBox;

  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;
  Box<EndTripChecklistModel> get endTripChecklistBox =>
      objectBoxStore.endTripChecklistBox;
  Box<TripUpdateModel> get tripUpdateBox => objectBoxStore.tripUpdatesBox;
  Box<CancelledInvoiceModel> get cancelledInvoiceBox =>
      objectBoxStore.cancelledInvoiceBox;
  Box<CollectionModel> get deliveryCollectonBox =>
      objectBoxStore.deliveryCollectonBox;

  Box<DeliveryReceiptModel> get deliveryReceiptBox =>
      objectBoxStore.deliveryReceiptBox;

  AuthLocalBase({required this.objectBoxStore, required this.prefs})
    : box = objectBoxStore.userBox;

  // ---------------------------------------------------------------------------
  // Helper: removes duplicate trips AND null-ID trips
  // ---------------------------------------------------------------------------
  Future<void> removeDuplicateTrips() async {
    final allTrips = tripBox.getAll();

    final seenIds = <String>{};
    int removedDuplicates = 0;
    int removedNullTrips = 0;

    for (final trip in allTrips) {
      // --- Case 1: Trip has NO valid ID → remove it.
      if (trip.id == null || trip.id!.trim().isEmpty) {
        tripBox.remove(trip.objectBoxId);
        removedNullTrips++;
        continue;
      }

      // --- Case 2: Duplicate ID → remove it.
      if (seenIds.contains(trip.id)) {
        tripBox.remove(trip.objectBoxId);
        removedDuplicates++;
      } else {
        seenIds.add(trip.id!);
      }
    }

    debugPrint(
      '🧹 removeDuplicateTrips(): '
      'Removed $removedNullTrips null-ID trips, '
      'Removed $removedDuplicates duplicate trips. '
      'Remaining trips: ${tripBox.count()}',
    );
  }

  // ---------------------------------------------------------------------------
  // Sync helpers
  // ---------------------------------------------------------------------------

  Future<void> syncIntransitChecklistForTrip(TripModel trip) async {
    final List<ChecklistModel> updatedChecklist = [];

    for (final c in trip.checklist) {
      debugPrint(
        '📋 Syncing Checklist → ${c.objectName}, '
        'PB: ${c.pocketbaseId}, OBX: ${c.objectBoxId}',
      );

      // -------------------------------------------------------------
      // 1️⃣ Find existing checklist by PocketBase ID
      // -------------------------------------------------------------
      final existing =
          checklistBox
              .query(ChecklistModel_.pocketbaseId.equals(c.pocketbaseId))
              .build()
              .findFirst();

      ChecklistModel updated;

      if (existing != null) {
        final full = checklistBox.get(existing.objectBoxId);

        if (full == null) {
          debugPrint('⚠️ Skipped: existing checklist OBX object was null');
          continue;
        }

        // -------------------------------------------------------------
        // 2️⃣ UPDATE fields
        // -------------------------------------------------------------
        full.id = c.id;
        full.objectName = c.objectName;
        full.description = c.description;
        full.status = c.status;
        full.isChecked = c.isChecked;
        full.timeCompleted = c.timeCompleted;

        // -------------------------------------------------------------
        // 3️⃣ SYNC: Trip relation (ToOne)
        // -------------------------------------------------------------
        if (c.trip.target != null) {
          final remoteTrip = c.trip.target!;

          final existingTrip =
              tripBox
                  .query(
                    TripModel_.pocketbaseId.equals(
                      remoteTrip.pocketbaseId ?? '',
                    ),
                  )
                  .build()
                  .findFirst();

          if (existingTrip != null) {
            full.trip.target = tripBox.get(existingTrip.objectBoxId);
          } else {
            final newTripId = tripBox.put(
              TripModel()
                ..id = remoteTrip.id
                ..pocketbaseId = remoteTrip.pocketbaseId
                ..name = remoteTrip.name,
            );
            full.trip.target = tripBox.get(newTripId);
          }
        } else {
          full.trip.target = null;
        }

        checklistBox.put(full);
        updated = full;

        debugPrint('🔁 Checklist updated → ${updated.objectName}');
      } else {
        // -------------------------------------------------------------
        // 4️⃣ NEW checklist
        // -------------------------------------------------------------
        final newId = checklistBox.put(c);
        final fresh = checklistBox.get(newId)!;

        // --- Trip relation ---
        if (c.trip.target != null) {
          final remoteTrip = c.trip.target!;

          final existingTrip =
              tripBox
                  .query(
                    TripModel_.pocketbaseId.equals(
                      remoteTrip.pocketbaseId ?? '',
                    ),
                  )
                  .build()
                  .findFirst();

          if (existingTrip != null) {
            fresh.trip.target = tripBox.get(existingTrip.objectBoxId);
          } else {
            final newTripId = tripBox.put(
              TripModel()
                ..id = remoteTrip.id
                ..pocketbaseId = remoteTrip.pocketbaseId
                ..name = remoteTrip.name,
            );
            fresh.trip.target = tripBox.get(newTripId);
          }
        }

        checklistBox.put(fresh);
        updated = fresh;

        debugPrint('✅ New Checklist saved → ${updated.objectName}');
      }

      updatedChecklist.add(updated);
    }

    // -------------------------------------------------------------
    // 5️⃣ Re-attach checklist to trip & save
    // -------------------------------------------------------------
    trip.checklist.clear();
    trip.checklist.addAll(updatedChecklist);
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → ${trip.name} '
      'Checklist count: ${trip.checklist.length}',
    );
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
        fullVehicle.type = vehicle.type;
        fullVehicle.make = vehicle.make;
        fullVehicle.volumeCapacity = vehicle.volumeCapacity;
        fullVehicle.weightCapacity = vehicle.weightCapacity;

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
      '🔍 Syncing DeliveryTeam for trip "${trip.name}" '
      '→ PB: ${deliveryTeam.pocketbaseId}, ActiveDeliveries: ${deliveryTeam.activeDeliveries}',
    );

    // -----------------------------
    // 1️⃣ Sync DeliveryVehicle first
    // -----------------------------
    final pbVehicle = deliveryTeam.deliveryVehicle.target;
    DeliveryVehicleModel? syncedVehicle;

    if (pbVehicle != null) {
      // Save or update the vehicle in ObjectBox
      final existingVehicle =
          vehicleBox
              .query(
                DeliveryVehicleModel_.pocketbaseId.equals(
                  pbVehicle.pocketbaseId,
                ),
              )
              .build()
              .findFirst();

      if (existingVehicle != null) {
        // Update existing vehicle
        existingVehicle.plateNo = pbVehicle.plateNo;
        existingVehicle.make = pbVehicle.make;
        existingVehicle.name = pbVehicle.name;
        // ... add other fields if needed

        vehicleBox.put(existingVehicle);
        syncedVehicle = existingVehicle;

        debugPrint(
          '🚗 DeliveryVehicle updated → PB: ${syncedVehicle.pocketbaseId}, OBX: ${syncedVehicle.objectBoxId}, Plate: ${syncedVehicle.name}',
        );
      } else {
        // New vehicle
        final newVehicleId = vehicleBox.put(pbVehicle);
        syncedVehicle = vehicleBox.get(newVehicleId)!;

        debugPrint(
          '🚗 DeliveryVehicle saved → PB: ${syncedVehicle.pocketbaseId}, OBX: $newVehicleId, Plate: ${syncedVehicle.plateNo}',
        );
      }
    }

    // -----------------------------
    // 2️⃣ Sync DeliveryTeam
    // -----------------------------
    final existingTeam =
        deliveryTeamBox
            .query(
              DeliveryTeamModel_.pocketbaseId.equals(deliveryTeam.pocketbaseId),
            )
            .build()
            .findFirst();

    DeliveryTeamModel updatedTeam;

    if (existingTeam != null) {
      final fullTeam = deliveryTeamBox.get(existingTeam.objectBoxId);
      if (fullTeam != null) {
        // Update team fields
        fullTeam.id = deliveryTeam.id;
        fullTeam.activeDeliveries = deliveryTeam.activeDeliveries;
        fullTeam.totalDelivered = deliveryTeam.totalDelivered;
        fullTeam.undeliveredCustomers = deliveryTeam.undeliveredCustomers;
        fullTeam.totalDistanceTravelled = deliveryTeam.totalDistanceTravelled;

        // Update personnel and checklist
        fullTeam.personels
          ..clear()
          ..addAll(deliveryTeam.personels);
        fullTeam.checklist
          ..clear()
          ..addAll(deliveryTeam.checklist);

        // Link vehicle
        fullTeam.deliveryVehicle.target = syncedVehicle;
        fullTeam.deliveryVehicle.targetId = syncedVehicle?.objectBoxId ?? 0;

        // Link team <-> trip
        fullTeam.trip.target = trip;

        deliveryTeamBox.put(fullTeam);
        updatedTeam = fullTeam;

        debugPrint(
          '🔁 DeliveryTeam updated → PB: ${updatedTeam.pocketbaseId}, OBX: ${updatedTeam.objectBoxId}, Vehicle OBX: ${syncedVehicle?.objectBoxId} Vehicle id: ${syncedVehicle?.pocketbaseId}, Vehicle id: ${syncedVehicle?.name}',
        );
      } else {
        debugPrint('⚠️ Could not load full existing DeliveryTeam from OBX');
        return;
      }
    } else {
      // New team
      if (syncedVehicle != null) {
        deliveryTeam.deliveryVehicle.target = syncedVehicle;
        deliveryTeam.deliveryVehicle.targetId = syncedVehicle.objectBoxId;
      }

      final newTeamId = deliveryTeamBox.put(deliveryTeam);
      updatedTeam = deliveryTeamBox.get(newTeamId)!;

      // Link to trip
      updatedTeam.trip.target = trip;

      debugPrint(
        '✅ New DeliveryTeam saved → PB: ${updatedTeam.pocketbaseId}, OBX: $newTeamId, Vehicle OBX: ${syncedVehicle?.objectBoxId}',
      );
    }

    // -----------------------------
    // 3️⃣ Assign updated team to trip
    // -----------------------------
    trip.deliveryTeam.target = updatedTeam;
    tripBox.put(trip);

    debugPrint(
      '🟦 Delivery Team saved to Trip → '
      'Trip ID: ${trip.id}, OBX: ${trip.objectBoxId}, '
      'DeliveryTeam OBX: ${trip.deliveryTeam.targetId}, '
      'Team Vehicle ID: ${trip.deliveryTeam.target?.deliveryVehicle.target?.name}, '
      'ActiveDeliveries: ${trip.deliveryTeam.target?.activeDeliveries}, '
      'Personnel: ${trip.deliveryTeam.target?.personels.length}',
    );
  }

  Future<void> syncInTransitOtpForTrip(TripModel trip) async {
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

  Future<void> syncEndTripOtpForTrip(TripModel trip) async {
    final endTripOtp = trip.endTripOtp.target;
    if (endTripOtp == null) return;

    debugPrint(
      '🔍 Syncing EndTrip OTP for trip "${trip.name}" '
      '→ OTP ID: ${endTripOtp.id}, Verified: ${endTripOtp.isVerified}',
    );

    // -------------------------------------------------
    // 1️⃣ Find existing EndTrip OTP by PB ID
    // -------------------------------------------------
    final existingOtp =
        endTripOtpBox
            .query(EndTripOtpModel_.id.equals(endTripOtp.id))
            .build()
            .findFirst();

    EndTripOtpModel syncedOtp;

    if (existingOtp != null) {
      // -------------------------------------------------
      // 2️⃣ Update existing EndTrip OTP
      // -------------------------------------------------
      final fullOtp = endTripOtpBox.get(existingOtp.dbId);
      if (fullOtp == null) {
        debugPrint('⚠️ Failed to load existing EndTrip OTP from ObjectBox');
        return;
      }

      fullOtp
        ..otpCode = endTripOtp.otpCode
        ..generatedCode = endTripOtp.generatedCode
        ..isVerified = endTripOtp.isVerified
        ..createdAt = endTripOtp.createdAt
        ..expiresAt = endTripOtp.expiresAt
        ..verifiedAt = endTripOtp.verifiedAt
        ..otpType = endTripOtp.otpType;

      // Link trip
      fullOtp.trip.target = trip;
      fullOtp.trip.targetId = trip.objectBoxId;

      endTripOtpBox.put(fullOtp);
      syncedOtp = fullOtp;

      debugPrint(
        '🔁 EndTrip OTP updated → PB: ${syncedOtp.id}, '
        'OBX: ${syncedOtp.dbId}, Verified: ${syncedOtp.isVerified}',
      );
    } else {
      // -------------------------------------------------
      // 3️⃣ New EndTrip OTP
      // -------------------------------------------------
      endTripOtp.trip.target = trip;
      endTripOtp.trip.targetId = trip.objectBoxId;

      final newOtpId = endTripOtpBox.put(endTripOtp);
      syncedOtp = endTripOtpBox.get(newOtpId)!;

      debugPrint(
        '✅ New EndTrip OTP saved → PB: ${syncedOtp.id}, '
        'OBX: $newOtpId, Verified: ${syncedOtp.isVerified}',
      );
    }

    // -------------------------------------------------
    // 4️⃣ Attach EndTrip OTP back to Trip
    // -------------------------------------------------
    trip.endTripOtp.target = syncedOtp;
    trip.endTripOtp.targetId = syncedOtp.dbId;
    tripBox.put(trip);

    debugPrint(
      '🟦 EndTrip OTP linked to Trip → '
      'Trip ID: ${trip.id}, OBX: ${trip.objectBoxId}, '
      'EndTrip OTP OBX: ${trip.endTripOtp.targetId}, '
      'OTP Code: ${syncedOtp.otpCode}, '
      'Verified: ${syncedOtp.isVerified}',
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
    int skippedDuplicates = 0;

    for (final d in incomingDeliveries) {
      final deliveryPbId = (d.pocketbaseId).trim();
      if (deliveryPbId.isEmpty) {
        debugPrint('⚠️ Skipping delivery: missing pocketbaseId/id');
        continue;
      }

      debugPrint('📦 Syncing deliveryData → ${d.ownerName} PB: $deliveryPbId');

      // ---------------------------------------------------
      // 🆕 DEDUPLICATION CHECK: Skip if already synced
      // ---------------------------------------------------
      if (uniqueDeliveries.containsKey(deliveryPbId)) {
        debugPrint(
          '⚠️ DUPLICATE DETECTED: Delivery $deliveryPbId already in sync list',
        );
        skippedDuplicates++;
        continue; // Skip redundant sync
      }

      // ---------------------------------------------------
      // 1️⃣ Load existing or create new DeliveryData
      // ---------------------------------------------------
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
      // 3️⃣ Sync Invoices (ToMany) — snapshot first + DEDUP
      // -------------------------------------------------------------
      final invoiceList = <InvoiceDataModel>[];
      final incomingInvoices = d.invoices.toList();
      final seenInvoiceIds = <String>{}; // Track to avoid duplicates in batch

      for (final inv in incomingInvoices) {
        final invPbId = (inv.pocketbaseId).trim();
        if (invPbId.isEmpty) continue;

        // ---------------------------------------------------
        // 🆕 DEDUPLICATION: Skip if already in batch
        // ---------------------------------------------------
        if (seenInvoiceIds.contains(invPbId)) {
          debugPrint(
            '⚠️ [DEDUP] Duplicate Invoice in batch: PB=$invPbId (${inv.name})',
          );
          skippedDuplicates++;
          continue;
        }
        seenInvoiceIds.add(invPbId);

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
      // 3️⃣ Sync InvoiceItems (ToMany) — snapshot first + DEDUP
      // -------------------------------------------------------------
      final List<InvoiceItemsModel> syncedInvoiceItems = <InvoiceItemsModel>[];
      final seenInvoiceItemIds = <String>{}; // Track to avoid duplicates

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

        // ---------------------------------------------------
        // 🆕 DEDUPLICATION: Skip if already in batch
        // ---------------------------------------------------
        if (seenInvoiceItemIds.contains(invPbId)) {
          debugPrint(
            '⚠️ [DEDUP] Duplicate InvoiceItem in batch: PB=$invPbId (${inv.name})',
          );
          skippedDuplicates++;
          continue;
        }
        seenInvoiceItemIds.add(invPbId);

        // ---------------------------------------------------
        // ✅ Find the invoice ID from incoming item
        // ---------------------------------------------------
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

        // ---------------------------------------------------
        // ✅ Resolve invoice locally using the maps
        // ---------------------------------------------------
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

        // ---------------------------------------------------
        // ✅ Find existing local InvoiceItem by pocketbaseId
        // ---------------------------------------------------
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
      // 4️⃣ Sync DeliveryUpdates (ToMany) — snapshot first + DEDUP
      // -------------------------------------------------------------
      final updatesList = <DeliveryUpdateModel>[];
      final incomingUpdates = d.deliveryUpdates.toList();
      final seenUpdateIds = <String>{}; // Track to avoid duplicates in batch

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
          debugPrint(
            '🧹 Found ${existingForDelivery.length} existing DeliveryUpdates for PB:$deliveryPbId',
          );

          // ---------------------------------------------------
          // 🆕 SMART CLEANUP: Keep synced ones, remove failed/pending
          // ---------------------------------------------------
          final toRemove = <int>[];
          for (final existing in existingForDelivery) {
            // Only remove non-synced updates (failed, pending, etc.)
            if (existing.syncStatus != 'synced') {
              toRemove.add(existing.objectBoxId);
            } else {
              debugPrint(
                '   ✅ Keeping synced update: ${existing.title} (${existing.id})',
              );
            }
          }

          if (toRemove.isNotEmpty) {
            deliveryUpdateBox.removeMany(toRemove);
            debugPrint('   🗑️ Removed ${toRemove.length} non-synced updates');
          }
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

        // ---------------------------------------------------
        // 🆕 DEDUPLICATION: Skip if already in batch
        // ---------------------------------------------------
        if (seenUpdateIds.contains(upId)) {
          debugPrint(
            '⚠️ [DEDUP] Duplicate DeliveryUpdate in batch: $upId (${up.title})',
          );
          skippedDuplicates++;
          continue;
        }
        seenUpdateIds.add(upId);

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

    // ---------------------------------------------------
    // 📊 SUMMARY OF SYNC OPERATION
    // ---------------------------------------------------
    if (skippedDuplicates > 0) {
      debugPrint(
        '✅ SYNC COMPLETE: Processed ${uniqueDeliveries.length} deliveries, skipped $skippedDuplicates duplicate entries',
      );
    } else {
      debugPrint(
        '✅ SYNC COMPLETE: Processed ${uniqueDeliveries.length} deliveries, no duplicates found',
      );
    }
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

  Future<void> syncCollectionsForTrip(TripModel trip) async {
    final Map<String, CollectionModel> uniqueCollections = {};

    debugPrint('🔁 Syncing collections for trip → ${trip.name}');

    for (final c in trip.deliveryCollection) {
      debugPrint(
        '📦 Syncing Collection → ${c.collectionName} PB: ${c.pocketbaseId}',
      );

      // ------------------------------------------------------------
      // LOAD OR CREATE COLLECTION
      // ------------------------------------------------------------
      CollectionModel fresh;

      final existing =
          deliveryCollectonBox
              .query(CollectionModel_.pocketbaseId.equals(c.pocketbaseId))
              .build()
              .findFirst();

      if (existing != null) {
        fresh = deliveryCollectonBox.get(existing.objectBoxId)!;
      } else {
        fresh =
            CollectionModel()
              ..id = c.id
              ..pocketbaseId = c.pocketbaseId
              ..collectionId = c.collectionId
              ..collectionName = c.collectionName
              ..totalAmount = c.totalAmount
              ..created = c.created
              ..updated = c.updated
              ..tripId = trip.id
              ..syncStatus = SyncStatus.synced.name;
      }

      // ------------------------------------------------------------
      // SYNC CUSTOMER
      // ------------------------------------------------------------
      if (c.customer.target != null) {
        final cust = c.customer.target!;

        final existingCust =
            customerBox
                .query(
                  CustomerDataModel_.pocketbaseId.equals(cust.pocketbaseId),
                )
                .build()
                .findFirst();

        if (existingCust == null) {
          final newCust =
              CustomerDataModel()
                ..id = cust.id
                ..pocketbaseId = cust.pocketbaseId
                ..name = cust.name
                ..province = cust.province
                ..municipality = cust.municipality
                ..barangay = cust.barangay;

          final newId = customerBox.put(newCust);
          fresh.customer.target = customerBox.get(newId);
        } else {
          fresh.customer.target = customerBox.get(existingCust.objectBoxId);
        }

        fresh.customerId = cust.id;
      } else {
        fresh.customer.target = null;
        fresh.customerId = null;
      }

      // ------------------------------------------------------------
      // SYNC DELIVERY DATA
      // ------------------------------------------------------------
      if (c.deliveryData.target != null) {
        final d = c.deliveryData.target!;

        final existingDelivery =
            deliveryDataBox
                .query(DeliveryDataModel_.pocketbaseId.equals(d.pocketbaseId))
                .build()
                .findFirst();

        if (existingDelivery != null) {
          fresh.deliveryData.target = deliveryDataBox.get(
            existingDelivery.objectBoxId,
          );
          fresh.deliveryDataId = d.id;
        } else {
          debugPrint(
            '⚠️ DeliveryData not found locally for PB: ${d.pocketbaseId}',
          );
          fresh.deliveryData.target = null;
          fresh.deliveryDataId = null;
        }
      }

      // ------------------------------------------------------------
      // SYNC TRIP
      // ------------------------------------------------------------
      fresh.trip.target = trip;
      fresh.tripId = trip.id;

      // ------------------------------------------------------------
      // SYNC INVOICES (CLEAR + REATTACH)
      // ------------------------------------------------------------
      final invoiceList = <InvoiceDataModel>[];

      for (final inv in c.invoices) {
        final existingInv =
            invoiceBox
                .query(InvoiceDataModel_.pocketbaseId.equals(inv.pocketbaseId))
                .build()
                .findFirst();

        if (existingInv == null) {
          final newInv =
              InvoiceDataModel()
                ..id = inv.id
                ..pocketbaseId = inv.pocketbaseId
                ..name = inv.name
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

      // ------------------------------------------------------------
      // SYNC DELIVERY RECEIPT (OPTIONAL)
      // ------------------------------------------------------------
      if (c.deliveryReceipt.target != null) {
        final receipt = c.deliveryReceipt.target!;

        final existingReceipt =
            deliveryReceiptBox
                .query(
                  DeliveryReceiptModel_.pocketbaseId.equals(
                    receipt.pocketbaseId,
                  ),
                )
                .build()
                .findFirst();

        if (existingReceipt == null) {
          final newReceipt =
              DeliveryReceiptModel()
                ..id = receipt.id
                ..pocketbaseId = receipt.pocketbaseId
                ..customerImagesString = receipt.customerImagesString
                ..created = receipt.created;

          final newId = deliveryReceiptBox.put(newReceipt);
          fresh.deliveryReceipt.target = deliveryReceiptBox.get(newId);
        } else {
          fresh.deliveryReceipt.target = deliveryReceiptBox.get(
            existingReceipt.objectBoxId,
          );
        }
      } else {
        fresh.deliveryReceipt.target = null;
      }

      // ------------------------------------------------------------
      // SAVE COLLECTION
      // ------------------------------------------------------------
      final obxId = deliveryCollectonBox.put(fresh);
      uniqueCollections[fresh.pocketbaseId] = deliveryCollectonBox.get(obxId)!;

      debugPrint(
        '✅ Collection synced → ${fresh.collectionName} OBX:$obxId '
        'Invoices:${fresh.invoices.length}',
      );
    }

    // ------------------------------------------------------------
    // ATTACH COLLECTIONS TO TRIP
    // ------------------------------------------------------------
    trip.deliveryCollection
      ..clear()
      ..addAll(uniqueCollections.values);

    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → ${trip.name} with ${trip.deliveryCollection.length} collections',
    );
  }

  Future<void> syncCancelledInvoicesForTrip(TripModel trip) async {
    debugPrint('🔁 Syncing CancelledInvoices for trip → ${trip.name}');

    final Map<String, CancelledInvoiceModel> uniqueCancelled = {};

    for (final ci in trip.cancelledInvoices) {
      debugPrint(
        '🚫 Syncing CancelledInvoice → PB:${ci.id} reason=${ci.reason}',
      );

      // ---------------------------------------------------------
      // 1️⃣ Load existing or create new CancelledInvoice
      // ---------------------------------------------------------
      CancelledInvoiceModel fresh;

      final existingQuery =
          cancelledInvoiceBox
              .query(
                CancelledInvoiceModel_.pocketbaseId.equals(ci.pocketbaseId),
              )
              .build();
      final existing = existingQuery.findFirst();
      existingQuery.close();

      if (existing != null) {
        fresh = cancelledInvoiceBox.get(existing.objectBoxId)!;
      } else {
        fresh =
            CancelledInvoiceModel()
              ..id = ci.id
              ..pocketbaseId = ci.pocketbaseId
              ..collectionId = ci.collectionId
              ..collectionName = ci.collectionName
              ..reason = ci.reason
              ..image = ci.image
              ..created = ci.created
              ..updated = ci.updated
              ..tripId = trip.id;
      }

      // ---------------------------------------------------------
      // 2️⃣ Sync DeliveryData (ToOne)
      // ---------------------------------------------------------
      if (ci.deliveryData.target != null) {
        final dd = ci.deliveryData.target!;
        final ddQuery =
            deliveryDataBox
                .query(DeliveryDataModel_.pocketbaseId.equals(dd.pocketbaseId))
                .build();
        final existingDD = ddQuery.findFirst();
        ddQuery.close();

        if (existingDD != null) {
          fresh.deliveryData.target = deliveryDataBox.get(
            existingDD.objectBoxId,
          );
        } else {
          final newDD =
              DeliveryDataModel()
                ..id = dd.id
                ..pocketbaseId = dd.pocketbaseId
                ..ownerName = dd.ownerName
                ..deliveryNumber = dd.deliveryNumber
                ..storeName = dd.storeName
                ..province = dd.province
                ..municipality = dd.municipality
                ..barangay = dd.barangay
                ..paymentMode = dd.paymentMode
                ..tripId = trip.id;

          final newId = deliveryDataBox.put(newDD);
          fresh.deliveryData.target = deliveryDataBox.get(newId);
        }
      } else {
        fresh.deliveryData.target = null;
      }

      // ---------------------------------------------------------
      // 3️⃣ Sync Trip (ToOne)
      // ---------------------------------------------------------
      final tripQuery =
          tripBox
              .query(TripModel_.pocketbaseId.equals(trip.pocketbaseId ?? ''))
              .build();
      final existingTrip = tripQuery.findFirst();
      tripQuery.close();

      if (existingTrip != null) {
        fresh.trip.target = tripBox.get(existingTrip.objectBoxId);
      } else {
        final newTrip =
            TripModel()
              ..id = trip.id
              ..pocketbaseId = trip.pocketbaseId
              ..name = trip.name;
        final newId = tripBox.put(newTrip);
        fresh.trip.target = tripBox.get(newId);
      }

      // ---------------------------------------------------------
      // 4️⃣ Sync Customer (ToOne)
      // ---------------------------------------------------------
      if (ci.customer.target != null) {
        final cust = ci.customer.target!;
        final custQuery =
            customerBox
                .query(
                  CustomerDataModel_.pocketbaseId.equals(cust.pocketbaseId),
                )
                .build();
        final existingCust = custQuery.findFirst();
        custQuery.close();

        if (existingCust != null) {
          fresh.customer.target = customerBox.get(existingCust.objectBoxId);
        } else {
          final newCust =
              CustomerDataModel()
                ..id = cust.id
                ..pocketbaseId = cust.pocketbaseId
                ..name = cust.name
                ..province = cust.province
                ..municipality = cust.municipality
                ..barangay = cust.barangay;

          final newId = customerBox.put(newCust);
          fresh.customer.target = customerBox.get(newId);
        }
      } else {
        fresh.customer.target = null;
      }

      // ---------------------------------------------------------
      // 5️⃣ Sync Primary Invoice (ToOne)
      // ---------------------------------------------------------
      if (ci.invoice.target != null) {
        final inv = ci.invoice.target!;
        final invQuery =
            invoiceBox
                .query(InvoiceDataModel_.pocketbaseId.equals(inv.pocketbaseId))
                .build();
        final existingInv = invQuery.findFirst();
        invQuery.close();

        if (existingInv != null) {
          fresh.invoice.target = invoiceBox.get(existingInv.objectBoxId);
        } else {
          final newInv =
              InvoiceDataModel()
                ..id = inv.id
                ..pocketbaseId = inv.pocketbaseId
                ..name = inv.name
                ..totalAmount = inv.totalAmount;

          final newId = invoiceBox.put(newInv);
          fresh.invoice.target = invoiceBox.get(newId);
        }
      } else {
        fresh.invoice.target = null;
      }

      // ---------------------------------------------------------
      // 6️⃣ Sync Invoices (ToMany)
      // ---------------------------------------------------------
      final invoiceList = <InvoiceDataModel>[];

      for (final inv in ci.invoices) {
        final invQuery =
            invoiceBox
                .query(InvoiceDataModel_.pocketbaseId.equals(inv.pocketbaseId))
                .build();
        final existingInv = invQuery.findFirst();
        invQuery.close();

        if (existingInv != null) {
          invoiceList.add(invoiceBox.get(existingInv.objectBoxId)!);
        } else {
          final newInv =
              InvoiceDataModel()
                ..id = inv.id
                ..pocketbaseId = inv.pocketbaseId
                ..name = inv.name
                ..totalAmount = inv.totalAmount;

          final newId = invoiceBox.put(newInv);
          invoiceList.add(invoiceBox.get(newId)!);
        }
      }

      fresh.invoices
        ..clear()
        ..addAll(invoiceList);

      // ---------------------------------------------------------
      // 7️⃣ Save CancelledInvoice
      // ---------------------------------------------------------
      final obxId = cancelledInvoiceBox.put(fresh);
      uniqueCancelled[fresh.id ?? ''] = cancelledInvoiceBox.get(obxId)!;

      debugPrint(
        '✅ CancelledInvoice synced → OBX:$obxId reason=${fresh.reason}, id =${fresh.pocketbaseId}',
      );
    }

    // ---------------------------------------------------------
    // 8️⃣ Attach to Trip & Save
    // ---------------------------------------------------------
    trip.cancelledInvoices
      ..clear()
      ..addAll(uniqueCancelled.values);

    tripBox.put(trip);

    debugPrint(
      '🟦 Trip updated → ${trip.name} with ${trip.cancelledInvoices.length} cancelled invoices',
    );
  }

  // ---------------------------------------------------------------------------
  // Clean helpers
  // ---------------------------------------------------------------------------

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

  /// 🧹 Clean CancelledInvoice table:
  /// 1️⃣ Remove items with NULL / EMPTY PocketBase ID (id)
  /// 2️⃣ Remove duplicates using PocketBase ID
  Future<void> cleanCancelledInvoices() async {
    try {
      debugPrint('🧹 Starting CancelledInvoice cleanup');

      final allCancelled = cancelledInvoiceBox.getAll();

      final seen = <String, CancelledInvoiceModel>{};

      for (final ci in allCancelled) {
        final pbId = (ci.id ?? '').trim();

        // -------------------------------------------------
        // 🔴 Step 1 — Remove invalid (no PB ID)
        // -------------------------------------------------
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing INVALID CancelledInvoice → '
            'Reason: ${ci.reason}, OBX: ${ci.objectBoxId}',
          );
          cancelledInvoiceBox.remove(ci.objectBoxId);
          continue;
        }

        // -------------------------------------------------
        // 🔁 Step 2 — Remove duplicates
        // -------------------------------------------------
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate CancelledInvoice → Removing '
            'PB: $pbId (OBX: ${ci.objectBoxId})',
          );
          cancelledInvoiceBox.remove(ci.objectBoxId);
          continue;
        }

        // -------------------------------------------------
        // ✅ First valid occurrence
        // -------------------------------------------------
        seen[pbId] = ci;
      }

      debugPrint(
        '🟢 CancelledInvoice cleanup complete — '
        '${allCancelled.length - seen.length} invalid/duplicate records removed.',
      );
    } catch (e, st) {
      debugPrint('❌ cleanCancelledInvoices error: $e\n$st');
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

  /// 🧹 Clean InTransit OTP table:
  ///    1. Remove items with NULL/EMPTY PB ID
  ///    2. Remove duplicates using PB ID
  Future<void> cleanInTransitOtp() async {
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
      debugPrint('❌ cleanInTransitOtp ERROR: $e\n$st');
    }
  }

  /// 🧹 Clean EndTrip OTP table:
  ///    1. Remove items with NULL/EMPTY PB ID
  ///    2. Remove duplicates using PB ID
  Future<void> cleanEndTripOtp() async {
    try {
      final allOtps = endTripOtpBox.getAll();

      final seen = <String, EndTripOtpModel>{};

      for (final otp in allOtps) {
        final pbId = otp.id.trim();

        // 🔴 Step 1 — Remove OTP with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL EndTrip OTP → '
            'OBX: ${otp.dbId}, Code: ${otp.otpCode}',
          );
          endTripOtpBox.remove(otp.dbId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate OTPs
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate EndTrip OTP → Removing '
            '(PB: $pbId, OBX: ${otp.dbId})',
          );
          endTripOtpBox.remove(otp.dbId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = otp;
      }

      debugPrint(
        '🟢 EndTrip OTP cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e, st) {
      debugPrint('❌ cleanEndTripOtp ERROR: $e\n$st');
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
            'OBX: ${d.objectBoxId}, Customer: ${d.ownerName}, ID: ${d.id} PB: ${d.pocketbaseId}',
          );
          deliveryDataBox.removeAll();
          continue;
        }

        // 🔁 Step 2 — Remove duplicate Delivery Data
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate DeliveryData → Removing OBX: ${d.objectBoxId} '
            '(PB: $pbId, Customer: ${d.ownerName})',
          );
          deliveryDataBox.removeAll();
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

  Future<void> cleanEndTripChecklist() async {
    try {
      final allChecklist = endTripChecklistBox.getAll();

      final seen = <String, EndTripChecklistModel>{};

      for (var e in allChecklist) {
        final pbId = e.pocketbaseId.trim();

        // 🔴 Step 1 — Remove checklist with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL EndTripChecklist → '
            'OBX: ${e.dbId}, Item: ${e.objectName}, ID: ${e.id}, PB: ${e.pocketbaseId}',
          );
          endTripChecklistBox.remove(e.dbId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate checklist by PB ID
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate EndTripChecklist → Removing OBX: ${e.dbId} '
            '(PB: $pbId, Item: ${e.objectName})',
          );
          endTripChecklistBox.remove(e.dbId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = e;
      }

      debugPrint(
        '🟢 EndTripChecklist cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e, st) {
      debugPrint('❌ cleanEndTripChecklist error: $e\n$st');
    }
  }

  Future<void> cleanDeliveryCollections() async {
    try {
      final allCollections = deliveryCollectonBox.getAll();

      debugPrint(
        '🧹 COLLECTION CLEANUP: Starting with ${allCollections.length} records',
      );

      final Map<String, CollectionModel> seen = {};
      final List<int> idsToRemove = [];

      for (final c in allCollections) {
        final pbId = c.pocketbaseId.trim();

        // ------------------------------------------------------------
        // STEP 1 — REMOVE COLLECTIONS WITH NO PB ID
        // ------------------------------------------------------------
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing Collection with EMPTY PB ID → '
            'OBX:${c.objectBoxId}, '
            'CollectionId:${c.collectionId}, '
            'Name:${c.collectionName}',
          );

          detachCollectionRelations(c);
          idsToRemove.add(c.objectBoxId);
          continue;
        }

        // ------------------------------------------------------------
        // STEP 2 — REMOVE DUPLICATES (PB ID BASED)
        // ------------------------------------------------------------
        if (seen.containsKey(pbId)) {
          final kept = seen[pbId]!;

          debugPrint(
            '⚠️ Duplicate Collection detected → '
            'REMOVING OBX:${c.objectBoxId}, '
            'KEEPING OBX:${kept.objectBoxId}, '
            'PB:$pbId',
          );

          detachCollectionRelations(c);
          idsToRemove.add(c.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = c;
      }

      // ------------------------------------------------------------
      // EXECUTE REMOVALS
      // ------------------------------------------------------------
      if (idsToRemove.isNotEmpty) {
        deliveryCollectonBox.removeMany(idsToRemove);
        debugPrint(
          '🗑️ COLLECTION CLEANUP: Removed ${idsToRemove.length} records',
        );
      } else {
        debugPrint('🟢 COLLECTION CLEANUP: No duplicates found');
      }

      debugPrint(
        '✅ COLLECTION CLEANUP COMPLETE — '
        'Remaining unique collections: ${seen.length}',
      );
    } catch (e, st) {
      debugPrint('❌ cleanDeliveryCollections error: $e');
      debugPrint(st.toString());
    }
  }

  void detachCollectionRelations(CollectionModel c) {
    try {
      c.customer.target = null;
      c.deliveryData.target = null;
      c.trip.target = null;
      c.deliveryReceipt.target = null;
      c.invoices.clear();
    } catch (e) {
      debugPrint(
        '⚠️ Failed to detach relations for Collection OBX:${c.objectBoxId} → $e',
      );
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

  // ---------------------------------------------------------------------------
  // Clear user data (used by SaveUserImpl and CacheUserDataImpl)
  // ---------------------------------------------------------------------------
  Future<void> clearUser() async {
    debugPrint('🧹 Clearing user data from local storage');
    box.removeAll();
    await prefs.remove('user_data');
    await prefs.remove('user_trip_data');
  }
}
