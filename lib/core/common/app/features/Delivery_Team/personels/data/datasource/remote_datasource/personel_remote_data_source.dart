import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_role.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';

abstract class PersonelRemoteDataSource {
  Future<List<PersonelModel>> getPersonels();
  Future<PersonelModel> getPersonelById(String personelId);
  Future<void> setRole(String id, UserRole newRole);
  Future<List<PersonelModel>> loadPersonelsByTripId(String tripId);
  Future<List<PersonelModel>> loadPersonelsByDeliveryTeam(
    String deliveryTeamId,
  );

  // New functions
  Future<PersonelModel> createPersonel({
    required String name,
    required UserRole role,
    String? deliveryTeamId,
    String? tripId,
  });

  Future<bool> deletePersonel(String personelId);

  Future<bool> deleteAllPersonels(List<String> personelIds);

  Future<PersonelModel> updatePersonel({
    required String personelId,
    String? name,
    UserRole? role,
    String? deliveryTeamId,
    String? tripId,
  });
}

class PersonelRemoteDataSourceImpl implements PersonelRemoteDataSource {
  final PocketBase _pocketBaseClient;
  static const String _authTokenKey = 'auth_token';
  static const String _authUserKey = 'auth_user';

  PersonelRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  // Helper method to ensure PocketBase client is authenticated
  Future<void> _ensureAuthenticated() async {
    try {
      // Check if already authenticated
      if (_pocketBaseClient.authStore.isValid) {
        debugPrint('✅ PocketBase client already authenticated');
        return;
      }

      debugPrint(
        '⚠️ PocketBase client not authenticated, attempting to restore from storage',
      );

      // Try to restore authentication from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(_authTokenKey);
      final userDataString = prefs.getString(_authUserKey);

      if (authToken != null && userDataString != null) {
        debugPrint('🔄 Restoring authentication from storage');

        // Restore the auth store with token only
        // The PocketBase client will handle the record validation
        _pocketBaseClient.authStore.save(authToken, null);

        debugPrint('✅ Authentication restored from storage');
      } else {
        debugPrint('❌ No stored authentication found');
        throw const ServerException(
          message: 'User not authenticated. Please log in again.',
          statusCode: '401',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to ensure authentication: ${e.toString()}');
      throw ServerException(
        message: 'Authentication error: ${e.toString()}',
        statusCode: '401',
      );
    }
  }

  @override
  Future<List<PersonelModel>> getPersonels() async {
    // Ensure PocketBase client is authenticated
    await _ensureAuthenticated();

    final records = await _pocketBaseClient
        .collection('personels')
        .getFullList(sort: '-created', expand: 'trip,deliveryTeam');
    return records.map((record) {
      final data = record.toJson();
      return PersonelModel.fromJson(data);
    }).toList();
  }

  @override
  Future<PersonelModel> getPersonelById(String personelId) async {
    try {
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      debugPrint('🔄 Getting personnel by ID: $personelId');

      final record = await _pocketBaseClient
          .collection('personels')
          .getOne(personelId, expand: 'trip,deliveryTeam');

      debugPrint('✅ Successfully retrieved personnel');
      return PersonelModel.fromJson(record.toJson());
    } catch (e) {
      debugPrint('❌ Error getting personnel by ID: $e');
      throw ServerException(
        message: 'Failed to get personnel: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> setRole(String id, UserRole newRole) async {
    final roleValue = newRole == UserRole.teamLeader ? 'team_leader' : 'helper';
    await _pocketBaseClient
        .collection('personels')
        .update(id, body: {'role': roleValue});
  }

  @override
  Future<List<PersonelModel>> loadPersonelsByTripId(String tripId) async {
    // Ensure PocketBase client is authenticated
    await _ensureAuthenticated();

    final records = await _pocketBaseClient
        .collection('personels')
        .getFullList(filter: 'trip = "$tripId"', expand: 'trip,deliveryTeam');

    return records
        .map((record) => PersonelModel.fromJson(record.toJson()))
        .toList();
  }

  @override
  Future<List<PersonelModel>> loadPersonelsByDeliveryTeam(
    String deliveryTeamId,
  ) async {
    // Ensure PocketBase client is authenticated
    await _ensureAuthenticated();

    final records = await _pocketBaseClient
        .collection('personels')
        .getFullList(
          filter: 'deliveryTeam = "$deliveryTeamId"',
          expand: 'trip,deliveryTeam',
        );

    return records
        .map((record) => PersonelModel.fromJson(record.toJson()))
        .toList();
  }

  @override
  Future<PersonelModel> createPersonel({
    required String name,
    required UserRole role,
    String? deliveryTeamId,
    String? tripId,
  }) async {
    try {
      debugPrint('🔄 Creating new personnel: $name');

      // Convert role to string format expected by the API
      final roleValue = role == UserRole.teamLeader ? 'team_leader' : 'helper';

      // Prepare the request body
      final body = {'name': name, 'role': roleValue};

      // Add optional fields if provided
      if (deliveryTeamId != null) {
        body['deliveryTeam'] = deliveryTeamId;
      }

      if (tripId != null) {
        body['trip'] = tripId;
      }

      // Create the record
      final record = await _pocketBaseClient
          .collection('personels')
          .create(body: body);

      // Get the created record with expanded relations
      final createdRecord = await _pocketBaseClient
          .collection('personels')
          .getOne(record.id, expand: 'trip,deliveryTeam');

      debugPrint('✅ Successfully created personnel with ID: ${record.id}');
      return PersonelModel.fromJson(createdRecord.toJson());
    } catch (e) {
      debugPrint('❌ Error creating personnel: $e');
      throw ServerException(
        message: 'Failed to create personnel: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteAllPersonels(List<String> personelIds) async {
    try {
      debugPrint('🔄 Deleting multiple personnel: ${personelIds.length} items');

      // Use Future.wait to delete all personnel in parallel
      await Future.wait(
        personelIds.map(
          (id) => _pocketBaseClient.collection('personels').delete(id),
        ),
      );

      debugPrint('✅ Successfully deleted all personnel');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting multiple personnel: $e');
      throw ServerException(
        message: 'Failed to delete multiple personnel: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deletePersonel(String personelId) async {
    try {
      debugPrint('🔄 Deleting personnel: $personelId');

      await _pocketBaseClient.collection('personels').delete(personelId);

      debugPrint('✅ Successfully deleted personnel');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting personnel: $e');
      throw ServerException(
        message: 'Failed to delete personnel: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<PersonelModel> updatePersonel({
    required String personelId,
    String? name,
    UserRole? role,
    String? deliveryTeamId,
    String? tripId,
  }) async {
    try {
      debugPrint('🔄 Updating personnel: $personelId');

      // Prepare the request body with only the fields that need to be updated
      final body = <String, dynamic>{};

      if (name != null) {
        body['name'] = name;
      }

      if (role != null) {
        body['role'] = role == UserRole.teamLeader ? 'team_leader' : 'helper';
      }

      // For deliveryTeam and trip, we need to handle both setting and removing
      // If the value is an empty string, it will remove the relation
      if (deliveryTeamId != null) {
        body['deliveryTeam'] = deliveryTeamId.isEmpty ? null : deliveryTeamId;
      }

      if (tripId != null) {
        body['trip'] = tripId.isEmpty ? null : tripId;
      }

      // Update the record
      await _pocketBaseClient
          .collection('personels')
          .update(personelId, body: body);

      // Get the updated record with expanded relations
      final updatedRecord = await _pocketBaseClient
          .collection('personels')
          .getOne(personelId, expand: 'trip,deliveryTeam');

      debugPrint('✅ Successfully updated personnel');
      return PersonelModel.fromJson(updatedRecord.toJson());
    } catch (e) {
      debugPrint('❌ Error updating personnel: $e');
      throw ServerException(
        message: 'Failed to update personnel: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
