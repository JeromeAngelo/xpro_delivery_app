import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/data/model/personnel_trip_model.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';

abstract class PersonnelTripRemoteDataSource {
  // Get all personnel trips
  Future<List<PersonnelTripModel>> getAllPersonnelTrips();
  
  // Get personnel trip by ID
  Future<PersonnelTripModel> getPersonnelTripById(String id);
  
  // Get personnel trips by personnel ID
  Future<List<PersonnelTripModel>> getPersonnelTripsByPersonnelId(String personnelId);
  
  // Get personnel trips by trip ID
  Future<List<PersonnelTripModel>> getPersonnelTripsByTripId(String tripId);
}

class PersonnelTripRemoteDataSourceImpl implements PersonnelTripRemoteDataSource {
  const PersonnelTripRemoteDataSourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  static const String _authTokenKey = 'auth_token';
  static const String _authUserKey = 'auth_user';

  // Helper method to ensure PocketBase client is authenticated
  Future<void> _ensureAuthenticated() async {
    try {
      // Check if already authenticated
      if (_pocketBaseClient.authStore.isValid) {
        debugPrint('✅ PocketBase client already authenticated');
        return;
      }

      debugPrint('⚠️ PocketBase client not authenticated, attempting to restore from storage');

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
  Future<List<PersonnelTripModel>> getAllPersonnelTrips() async {
    try {
      debugPrint('🔄 Fetching all personnel trips');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      final records = await _pocketBaseClient
          .collection('personnelTripsCollection')
          .getFullList(
            expand: 'personnels,assignedTrips',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} personnel trips from API');

      return records.map((record) {
        return PersonnelTripModel.fromJson({
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          ...record.data,
          'expand': record.expand,
        });
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch all personnel trips: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch all personnel trips: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<PersonnelTripModel> getPersonnelTripById(String id) async {
    try {
      debugPrint('🔄 Fetching personnel trip by ID: $id');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      final record = await _pocketBaseClient
          .collection('personnelTripsCollection')
          .getOne(
            id,
            expand: 'personnels,assignedTrips',
          );

      debugPrint('✅ Retrieved personnel trip: ${record.id}');

      return PersonnelTripModel.fromJson({
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        ...record.data,
        'expand': record.expand,
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch personnel trip by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch personnel trip by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<PersonnelTripModel>> getPersonnelTripsByPersonnelId(String personnelId) async {
    try {
      debugPrint('🔄 Fetching personnel trips by personnel ID: $personnelId');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      final records = await _pocketBaseClient
          .collection('personnelTripsCollection')
          .getFullList(
            expand: 'personnels,assignedTrips',
            filter: 'personnels ~ "$personnelId"',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} personnel trips for personnel: $personnelId');

      return records.map((record) {
        return PersonnelTripModel.fromJson({
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          ...record.data,
          'expand': record.expand,
        });
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch personnel trips by personnel ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch personnel trips by personnel ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<PersonnelTripModel>> getPersonnelTripsByTripId(String tripId) async {
    try {
      debugPrint('🔄 Fetching personnel trips by trip ID: $tripId');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      final records = await _pocketBaseClient
          .collection('personnelTripsCollection')
          .getFullList(
            expand: 'personnels,assignedTrips',
            filter: 'assignedTrips ~ "$tripId"',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} personnel trips for trip: $tripId');

      return records.map((record) {
        return PersonnelTripModel.fromJson({
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          ...record.data,
          'expand': record.expand,
        });
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch personnel trips by trip ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch personnel trips by trip ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
