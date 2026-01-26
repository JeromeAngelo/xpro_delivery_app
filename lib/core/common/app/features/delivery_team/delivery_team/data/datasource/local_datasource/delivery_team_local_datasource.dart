
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../../../services/objectbox.dart';
import '../../../../../checklists/intransit_checklist/data/model/checklist_model.dart';
import '../../../../../trip_ticket/trip/data/models/trip_models.dart';
import '../../../../delivery_vehicle_data/data/model/delivery_vehicle_model.dart';

abstract class DeliveryTeamLocalDatasource {
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId);
  Future<void> updateDeliveryTeam(DeliveryTeamModel team);
  Future<void> cacheDeliveryTeam(DeliveryTeamModel team);
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId);
  Future<void> saveDeliveryTeamByTripId(String tripId, DeliveryTeamModel team);
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  });
}

class DeliveryTeamLocalDatasourceImpl implements DeliveryTeamLocalDatasource {
   Box<DeliveryTeamModel> get _deliveryTeamBox => objectBoxStore.deliveryTeamBox;
    Box<DeliveryVehicleModel> get vehicleBox => objectBoxStore.deliveryVehicleBox;
  Box<PersonelModel> get personnelBox => objectBoxStore.personelBox;
   Box<ChecklistModel> get checklistBox => objectBoxStore.checklistBox;
      Box<TripModel> get tripBox => objectBoxStore.tripBox;

  DeliveryTeamModel? _cachedDeliveryTeam;

  final ObjectBoxStore objectBoxStore;

  DeliveryTeamLocalDatasourceImpl(this.objectBoxStore);

  @override
Future<DeliveryTeamModel> loadDeliveryTeam(String tripId) async {
  try {
    debugPrint("📥 LOCAL loadDeliveryTeam() tripId = $tripId");

    // -------------------------------------------------------------
    // 1️⃣ Find the trip first
    // -------------------------------------------------------------
    final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
    final trip = tripQuery.findFirst();
    tripQuery.close();

    if (trip == null) {
      debugPrint("⚠️ Trip not found in local DB for tripId: $tripId");
      throw CacheException(
        message: "Trip not found in local DB",
        statusCode: 404,
      );
    }

    // -------------------------------------------------------------
    // 2️⃣ Get DeliveryTeam linked to this trip
    // -------------------------------------------------------------
    DeliveryTeamModel? team;
    for (final t in _deliveryTeamBox.getAll()) {
      if (t.trip.targetId == trip.objectBoxId) {
        team = t;
        break;
      }
    }

    if (team == null) {
      debugPrint("❌ No DeliveryTeam found for trip: $tripId");
      throw CacheException(
        message: "No DeliveryTeam found in local DB",
        statusCode: 404,
      );
    }

    debugPrint(
      "✅ DeliveryTeam FOUND → pbId=${team.id}, obx=${team.objectBoxId}, active delivery ${team.activeDeliveries}",
    );
    debugPrint(
      "    Personnels=${team.personels.length}, Checklist=${team.checklist.length}, Vehicle=${team.deliveryVehicle.target?.name}",
    );

    // -------------------------------------------------------------
    // 3️⃣ Load Vehicle (ToOne)
    // -------------------------------------------------------------
    final vRef = team.deliveryVehicle.target;
    if (vRef != null) {
      final fullVehicle = vehicleBox.get(vRef.objectBoxId);
      if (fullVehicle != null) {
        team.deliveryVehicle.target = fullVehicle;
        team.deliveryVehicle.targetId = fullVehicle.objectBoxId;
      }
    }

    // -------------------------------------------------------------
    // 4️⃣ Load Personnels (ToMany)
    // -------------------------------------------------------------
    final personnels = <PersonelModel>[];
    for (var p in team.personels) {
      if (p.objectBoxId != 0) {
        final full = personnelBox.get(p.objectBoxId);
        if (full != null) personnels.add(full);
      }
    }
    team.personels
      ..clear()
      ..addAll(personnels);

    // -------------------------------------------------------------
    // 5️⃣ Load Checklist (ToMany)
    // -------------------------------------------------------------
    final checklist = <ChecklistModel>[];
    for (var c in team.checklist) {
      if (c.objectBoxId != 0) {
        final full = checklistBox.get(c.objectBoxId);
        if (full != null) checklist.add(full);
      }
    }
    team.checklist
      ..clear()
      ..addAll(checklist);

    debugPrint("🎉 DeliveryTeam fully loaded for trip: ${trip.id}");
    return team;

  } catch (e, st) {
    debugPrint("❌ loadDeliveryTeam ERROR: $e\n$st");
    throw CacheException(message: e.toString());
  }
}

  @override
  Future<void> updateDeliveryTeam(DeliveryTeamModel team) async {
    try {
      debugPrint('💾 LOCAL: Updating delivery team: ${team.id}');
      _deliveryTeamBox.put(team);
      _cachedDeliveryTeam = team;
      debugPrint('✅ LOCAL: Team updated successfully');
    } catch (e) {
      debugPrint('❌ Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupDeliveryTeams() async {
    try {
      debugPrint('🧹 Starting delivery team cleanup process');
      final allTeams = _deliveryTeamBox.getAll();

      final Map<String?, DeliveryTeamModel> uniqueTeams = {};

      for (var team in allTeams) {
        if (_isValidDeliveryTeam(team)) {
          final existingTeam = uniqueTeams[team.pocketbaseId];
          if (existingTeam == null ||
              (team.updated!.isAfter(existingTeam.updated ?? DateTime(0)))) {
            uniqueTeams[team.pocketbaseId] = team;
          }
        }
      }

      _deliveryTeamBox.removeAll();
      _deliveryTeamBox.putMany(uniqueTeams.values.toList());

      debugPrint('✨ Delivery team cleanup complete:');
      debugPrint('📊 Original count: ${allTeams.length}');
      debugPrint('📊 After cleanup: ${uniqueTeams.length}');
    } catch (e) {
      debugPrint('❌ Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupPersonnelData(DeliveryTeamModel team) async {
    try {
      debugPrint('🧹 Starting personnel cleanup');
      final currentPersonnel = team.personels.toList();

      // Track unique personnel by their IDs
      final Map<String, PersonelModel> uniquePersonnel = {};

      // First pass - collect unique personnel
      for (var person in currentPersonnel) {
        if (person.id != null) {
          debugPrint('👤 Processing personnel: ${person.name} (${person.id})');
          // Only keep the first instance of each personnel
          if (!uniquePersonnel.containsKey(person.id)) {
            uniquePersonnel[person.id!] = person;
          }
        }
      }

      // Clear existing personnel
      team.personels.clear();

      // Add back only unique personnel
      team.personels.addAll(uniquePersonnel.values);

      debugPrint('✨ Personnel cleanup complete:');
      debugPrint('📊 Original count: ${currentPersonnel.length}');
      debugPrint('📊 After cleanup: ${team.personels.length}');

      // Verify unique personnel
      final uniqueIds = team.personels.map((p) => p.id).toSet();
      debugPrint('🔍 Unique personnel IDs: ${uniqueIds.length}');
      for (var p in team.personels) {
        debugPrint('   - ${p.name} (${p.id})');
      }
    } catch (e) {
      debugPrint('❌ Personnel cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidDeliveryTeam(DeliveryTeamModel team) {
    final hasTrip = team.tripId != null && team.tripId!.isNotEmpty;
    final hasVehicle =
        team.deliveryVehicle.target != null &&
        team.deliveryVehicle.target!.id != 0;
    final hasPersonnel = team.personels.isNotEmpty;

    return hasTrip && hasVehicle && hasPersonnel;
  }

  @override
  Future<void> cacheDeliveryTeam(DeliveryTeamModel team) async {
    try {
      debugPrint('💾 LOCAL: Caching delivery team');

      // Create a deep copy of the team data
      final teamCopy = DeliveryTeamModel(
        id: team.id,
        collectionId: team.collectionId,
        collectionName: team.collectionName,
      
      );

      // Copy personnel and vehicles
      teamCopy.personels.addAll(team.personels);
      if (team.deliveryVehicle.target != null) {
        teamCopy.deliveryVehicle.target = team.deliveryVehicle.target;
      }
      // teamCopy.deliveryVehicle.target?.id = team.deliveryVehicle.target?.id;

      // Clean up data
      await _cleanupPersonnelData(teamCopy);
      await _cleanupDeliveryTeams();

      // Save the clean copy
      final savedId = _deliveryTeamBox.put(teamCopy);
      _cachedDeliveryTeam = teamCopy;

      // Verify storage immediately after saving
      _deliveryTeamBox.get(savedId);
      // if (storedTeam != null) {
      //   debugPrint('✅ Storage verification successful');
      //   debugPrint('📊 Final stored team details:');
      //   debugPrint('Team ID: ${storedTeam.id}');
      //   debugPrint('Trip ID: ${storedTeam.tripId}');
      //   debugPrint('Personnel count: ${storedTeam.personels.length}');
      //   debugPrint('Vehicle count: ${storedTeam.deliveryVehicle.target!.id}');

      //   // Verify personnel details
      //   for (var p in storedTeam.personels) {
      //     debugPrint('   👤 ${p.name} (${p.id})');
      //   }
      // }
    } catch (e) {
      debugPrint('❌ Cache failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId) async {
    try {
      debugPrint('🔍 LOCAL: Loading delivery team by ID: $deliveryTeamId');

      final team =
          _deliveryTeamBox
              .query(DeliveryTeamModel_.pocketbaseId.equals(deliveryTeamId))
              .build()
              .findFirst();

      if (team == null) {
        throw const CacheException(message: 'Delivery team not found');
      }

      debugPrint('✅ LOCAL: Team found with ID: ${team.id}');
      return team;
    } catch (e) {
      debugPrint('❌ Load failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  }) async {
    try {
      debugPrint('📱 LOCAL: Assigning delivery team to trip');

      final query =
          _deliveryTeamBox
              .query(DeliveryTeamModel_.pocketbaseId.equals(deliveryTeamId))
              .build();
      final deliveryTeam = query.findFirst();
      query.close();

      if (deliveryTeam == null) {
        throw const CacheException(
          message: 'Delivery team not found in local storage',
        );
      }

      deliveryTeam.tripId = tripId;
      _deliveryTeamBox.put(deliveryTeam);

      debugPrint('✅ LOCAL: Delivery team assigned successfully');
      return deliveryTeam;
    } catch (e) {
      debugPrint('❌ LOCAL: Assignment failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  /// /// Saves delivery team data locally for a given trip ID
@override
Future<void> saveDeliveryTeamByTripId(
  String tripId,
  DeliveryTeamModel team,
) async {
  try {
    debugPrint('💾 LOCAL: Saving delivery team via Trip relation → tripId=$tripId');

    // -------------------------------------------------------------
    // 1️⃣ Find the trip first
    // -------------------------------------------------------------
    final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
    final trip = tripQuery.findFirst();
    tripQuery.close();

    if (trip == null) {
      debugPrint('❌ Trip not found in local DB for tripId=$tripId');
      throw CacheException(
        message: 'Trip not found in local DB',
        statusCode: 404,
      );
    }

    // -------------------------------------------------------------
    // 2️⃣ Cleanup dependent data before save
    // -------------------------------------------------------------
    await _cleanupPersonnelData(team);

    // -------------------------------------------------------------
    // 3️⃣ Check existing DeliveryTeam via Trip relation
    // -------------------------------------------------------------
    DeliveryTeamModel? existingTeam;
    if (trip.deliveryTeam.target != null) {
      final obxId = trip.deliveryTeam.target!.objectBoxId;
      existingTeam = _deliveryTeamBox.get(obxId);
    }

    if (existingTeam != null) {
      debugPrint('♻️ Updating existing DeliveryTeam for trip ${trip.name}');
      team.objectBoxId = existingTeam.objectBoxId;
    }

    // -------------------------------------------------------------
    // 4️⃣ Link team to trip (CRITICAL)
    // -------------------------------------------------------------
    team.trip.target = trip;
    team.trip.targetId = trip.objectBoxId;

    // -------------------------------------------------------------
    // 5️⃣ Save DeliveryTeam
    // -------------------------------------------------------------
    _deliveryTeamBox.put(team);

    // -------------------------------------------------------------
    // 6️⃣ Ensure Trip → DeliveryTeam link is set
    // -------------------------------------------------------------
    trip.deliveryTeam.target = team;
    tripBox.put(trip);

    _cachedDeliveryTeam = team;

    debugPrint('✅ LOCAL: Delivery team saved successfully for trip ${trip.name}');

    // -------------------------------------------------------------
    // 7️⃣ Verification
    // -------------------------------------------------------------
    final verifyTeam =
        tripBox.get(trip.objectBoxId)?.deliveryTeam.target;

    if (verifyTeam != null) {
      debugPrint(
        '📊 Verification OK → ${verifyTeam.personels.length} personnels stored',
      );
    } else {
      debugPrint('⚠️ Verification failed: Trip has no linked DeliveryTeam');
    }
  } catch (e, st) {
    debugPrint(
      '❌ LOCAL: Failed to save delivery team for trip $tripId\n$e\n$st',
    );
    throw CacheException(message: e.toString());
  }
}

}
