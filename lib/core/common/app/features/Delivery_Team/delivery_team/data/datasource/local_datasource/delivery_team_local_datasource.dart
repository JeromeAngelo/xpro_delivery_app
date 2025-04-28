import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:flutter/foundation.dart';

abstract class DeliveryTeamLocalDatasource {
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId);
  Future<void> updateDeliveryTeam(DeliveryTeamModel team);
  Future<void> cacheDeliveryTeam(DeliveryTeamModel team);
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId);
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  });
}

class DeliveryTeamLocalDatasourceImpl implements DeliveryTeamLocalDatasource {
  final Box<DeliveryTeamModel> _deliveryTeamBox;
  DeliveryTeamModel? _cachedDeliveryTeam;

  DeliveryTeamLocalDatasourceImpl(this._deliveryTeamBox);
  @override
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId) async {
    try {
      debugPrint('🔍 Querying local delivery team for trip: $tripId');

      // Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      // First try with tripId directly
      final query = _deliveryTeamBox.query(
        DeliveryTeamModel_.tripId.equals(tripId),
      );
      final teams = query.build().find();
      // query.;

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored delivery teams: ${_deliveryTeamBox.count()}');
      debugPrint('Found teams for trip: ${teams.length}');

      if (teams.isNotEmpty) {
        final team = teams.first;
        _cachedDeliveryTeam = team;
        debugPrint('✅ Found delivery team using provided trip ID');
        return team;
      }

      // If not found with tripId, try with tripNumberId from user data
      if (userData != null) {
        final userJson = jsonDecode(userData);
        final tripNumberId = userJson['tripNumberId'];

        if (tripNumberId != null) {
          debugPrint(
            '🔍 Trying with trip number ID from preferences: $tripNumberId',
          );

          final tripNumberQuery =
              _deliveryTeamBox
                  .query(DeliveryTeamModel_.tripId.equals(tripNumberId))
                  .build();

          final tripNumberTeams = tripNumberQuery.find();
          tripNumberQuery.close();

          if (tripNumberTeams.isNotEmpty) {
            final team = tripNumberTeams.first;
            _cachedDeliveryTeam = team;
            debugPrint('✅ Found team using trip number ID from preferences');
            return team;
          }
        }
      }

      // Try with pocketbaseId as last resort
      final pbQuery =
          _deliveryTeamBox
              .query(DeliveryTeamModel_.pocketbaseId.equals(tripId))
              .build();

      final pbTeams = pbQuery.find();
      pbQuery.close();

      if (pbTeams.isNotEmpty) {
        final team = pbTeams.first;
        _cachedDeliveryTeam = team;
        debugPrint('✅ Found team using pocketbase ID');
        return team;
      }

      // If we get here, no team was found
      debugPrint('❌ No delivery team found in local storage for trip: $tripId');
      throw const CacheException(
        message: 'No delivery team found in local storage',
        statusCode: 404,
      );
    } catch (e) {
      debugPrint('❌ Local storage error: ${e.toString()}');
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
              (team.updated?.isAfter(existingTeam.updated ?? DateTime(0)) ??
                  false)) {
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
    return team.tripId != null &&
        team.vehicle.isNotEmpty &&
        team.personels.isNotEmpty;
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
        created: team.created,
        updated: team.updated,
      );

      // Copy personnel and vehicles
      teamCopy.personels.addAll(team.personels);
      teamCopy.vehicle.addAll(team.vehicle);

      // Clean up data
      await _cleanupPersonnelData(teamCopy);
      await _cleanupDeliveryTeams();

      // Save the clean copy
      final savedId = _deliveryTeamBox.put(teamCopy);
      _cachedDeliveryTeam = teamCopy;

      // Verify storage immediately after saving
      final storedTeam = _deliveryTeamBox.get(savedId);
      if (storedTeam != null) {
        debugPrint('✅ Storage verification successful');
        debugPrint('📊 Final stored team details:');
        debugPrint('Team ID: ${storedTeam.id}');
        debugPrint('Trip ID: ${storedTeam.tripId}');
        debugPrint('Personnel count: ${storedTeam.personels.length}');
        debugPrint('Vehicle count: ${storedTeam.vehicle.length}');

        // Verify personnel details
        storedTeam.personels.forEach(
          (p) => debugPrint('   👤 ${p.name} (${p.id})'),
        );
      }
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
}
