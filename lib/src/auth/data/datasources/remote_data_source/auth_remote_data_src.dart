import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/src/auth/data/models/auth_models.dart';

abstract class AuthRemoteDataSrc {
  const AuthRemoteDataSrc();

  Future<LocalUsersModel> signIn(
      {required String email, required String password});
  Future<LocalUsersModel> refreshUserData();
  Future<LocalUsersModel> loadUser();
  Future<LocalUsersModel> getUserById(String userId);
  Future<TripModel> getUserTrip(String userId);

  // New sync methods
  Future<LocalUsersModel> syncUserData(String userId);
  Future<TripModel> syncUserTripData(String userId);
}

class AuthRemoteDataSrcImpl implements AuthRemoteDataSrc {
  const AuthRemoteDataSrcImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
Future<LocalUsersModel> signIn({
  required String email,
  required String password,
}) async {
  try {
    debugPrint('🔐 Attempting sign in for: $email');

    final authData = await _pocketBaseClient
        .collection('users')
        .authWithPassword(email, password);

    if (authData.token.isEmpty) {
      throw const ServerException(
        message: 'Authentication failed',
        statusCode: 'Auth Error',
      );
    }

    // Get the user record with expanded role data
    final userRecord = await _pocketBaseClient.collection('users').getOne(
      authData.record.id,
      expand: 'user_role',  // Make sure this matches the field name in PocketBase
    );

    // Check if user has Team Leader role
    final userRoleData = userRecord.expand['user_role'];
    bool isTeamLeader = false;
    Map<String, dynamic>? roleJson;
    
    if (userRoleData != null) {
      debugPrint('🔍 User role data type: ${userRoleData.runtimeType}');
      
      // Handle the case where userRoleData is a List<RecordModel>
      if (userRoleData.isNotEmpty) {
        final roleRecord = userRoleData.first;
        final roleName = roleRecord.data['name']?.toString() ?? '';
        isTeamLeader = roleName == 'Team Leader';
        debugPrint('👑 User role (from list): $roleName');
        
        roleJson = {
          'id': roleRecord.id,
          'name': roleName,
          'permissions': roleRecord.data['permissions'] ?? [],
        };
      }
        } else {
      debugPrint('⚠️ No role data found for user');
    }

     // Check user status
      final userStatus =
          userRecord.data['status']?.toString().toLowerCase() ?? '';
      if (userStatus == 'suspended') {
        throw const ServerException(
          message:
              'Your account has been suspended. Please contact the administrator.',
          statusCode: 'Account Suspended',
        );
      }

    if (!isTeamLeader) {
      throw const ServerException(
        message: 'You don\'t have permission to sign in to this app. Please contact your admin support and try again.',
        statusCode: 'Permission Error',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userData;

    try {
      // Prepare user data with role information
      userData = {
        'id': authData.record.id,
        'collectionId': authData.record.collectionId,
        'collectionName': authData.record.collectionName,
        'email': authData.record.data['email'],
        'name': authData.record.data['name'],
        'tripNumberId': authData.record.data['tripNumberId'],
        'tokenKey': authData.token,
      };
      
      // Add role data if available
      if (roleJson != null) {
        userData['expand'] = {
          'user_role': roleJson,
        };
      }

      // Store properly formatted auth data
      await prefs.setString('auth_token', authData.token);
      await prefs.setString('user_data', jsonEncode(userData));

      debugPrint('✅ Authentication successful');
      debugPrint('💾 Stored user data: ${userData['name']}');
      debugPrint('   🆔 User ID: ${userData['id']}');
      debugPrint('   👑 Role: ${roleJson?['name'] ?? 'Unknown'}');
      debugPrint('   🔑 Token: ${authData.token.substring(0, 10)}...');

      return LocalUsersModel.fromJson(userData);
    } catch (e) {
      debugPrint('⚠️ Error formatting user data: ${e.toString()}');
      
      // Fallback data formatting
      final cleanedData = jsonEncode(authData.record.data)
          .replaceAll(RegExp(r':\s+'), '": "')
          .replaceAll(RegExp(r',\s+'), '", "')
          .replaceAll('{', '{"')
          .replaceAll('}', '"}');
      
      userData = jsonDecode(cleanedData);
      userData['tokenKey'] = authData.token;
      
      // Add role data if available
      if (roleJson != null) {
        userData['expand'] = {
          'user_role': roleJson,
        };
      }
      
      return LocalUsersModel.fromJson(userData);
    }
  } catch (e) {
    debugPrint('❌ Authentication error: ${e.toString()}');
    throw ServerException(
      message: e is ServerException ? e.message : e.toString(),
      statusCode: e is ServerException ? e.statusCode : '500',
    );
  }
}

@override
Future<LocalUsersModel> refreshUserData() async {
  try {
    debugPrint('🔄 Refreshing user data');
    final prefs = await SharedPreferences.getInstance();
    final storedUserData = prefs.getString('user_data');

    if (storedUserData != null) {
      // Parse stored data
      final userData = jsonDecode(storedUserData);
      final userId = userData['id'];
      
      debugPrint('🔍 Refreshing data for user: $userId');

      final userRecord = await _pocketBaseClient.collection('users').getOne(
        userId,
        expand: 'trip,deliveryTeam,trip.customers,trip.personels,trip.vehicle',
      );

      final mappedData = {
        'id': userRecord.id,
        'collectionId': userRecord.collectionId,
        'collectionName': userRecord.collectionName,
        'email': userRecord.data['email'],
        'name': userRecord.data['name'],
        'tripNumberId': userRecord.data['tripNumberId'],
        'deliveryTeam': _mapExpandedRecord(userRecord.expand['deliveryTeam']),
        'trip': _mapExpandedRecord(userRecord.expand['trip']),
        'tokenKey': userData['tokenKey'],
      };

      await prefs.setString('user_data', jsonEncode(mappedData));
      debugPrint('✅ User data refreshed successfully');
      return LocalUsersModel.fromJson(mappedData);
    }

    throw const ServerException(
      message: 'No stored user data found',
      statusCode: '404',
    );
  } catch (e) {
    debugPrint('❌ Refresh failed: ${e.toString()}');
    throw ServerException(message: e.toString(), statusCode: '500');
  }
}


  @override
  Future<LocalUsersModel> loadUser() async {
    try {
      debugPrint('🔄 Loading user data from remote');

      // First try to restore auth from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final storedUserData = prefs.getString('user_data');

      if (storedToken != null && storedUserData != null) {
        final userData = jsonDecode(storedUserData);
        debugPrint('📦 Stored user data: $userData');

        // Create user model directly from stored data
        return LocalUsersModel(
          id: userData['id'],
          email: userData['email'] ?? '',
          name: userData['name'] ?? '',
          tripNumberId: userData['tripNumberId'] ?? '',
          collectionId: '_pb_users_auth_',
          collectionName: 'users',
        );
      }

      throw const ServerException(
        message: 'No stored user data found',
        statusCode: '404',
      );
    } catch (e) {
      debugPrint('❌ Remote load failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
  
@override
Future<LocalUsersModel> getUserById(String userId) async {
  try {
    // Extract actual user ID if we received a JSON object
    String actualUserId;
    if (userId.startsWith('{')) {
      final userData = jsonDecode(userId);
      actualUserId = userData['id'];
    } else {
      actualUserId = userId;
    }
    
    debugPrint('🔍 Fetching user by ID: $actualUserId');
    debugPrint('📊 Remote Fetch Stats:');

    final user = await _pocketBaseClient.collection('users').getOne(
          actualUserId,
          expand: 'checklist,updateTimeline,deliveryTeam,completedCustomer,returnList,end_trip_checklists,trips',
    );

    debugPrint('   👤 User Found: ${user.id}');
    debugPrint('   📧 Email: ${user.data['email']}');
    debugPrint('   🚚 Trip Number: ${user.data['tripNumberId']}');

    debugPrint('📦 Expanded Relations:');
    debugPrint('   ✓ Checklists: ${user.expand['checklist']?.length ?? 0}');
    debugPrint('   ✓ Timeline Updates: ${user.expand['updateTimeline']?.length ?? 0}');
    debugPrint('   ✓ Delivery Teams: ${user.expand['deliveryTeam']?.length ?? 0}');
    debugPrint('   ✓ Completed Customers: ${user.expand['completedCustomer']?.length ?? 0}');
    debugPrint('   ✓ Returns: ${user.expand['returnList']?.length ?? 0}');
    debugPrint('   ✓ End Trip Checklists: ${user.expand['end_trip_checklists']?.length ?? 0}');
    debugPrint('   ✓ Trip: ${user.expand['trip'] != null ? 'Found' : 'Not Found'}');

    final Map<String, dynamic> userData = {
      ...user.data,
      'id': user.id,
      'name': user.data['name'] ?? '',
      'tripNumberId': user.data['tripNumberId'] ?? '',
      'checklist': user.expand['checklist']?.map((item) => item.id).toList() ?? [],
      'updateTimeline': user.expand['updateTimeline']?.map((item) => item.id).toList() ?? [],
      'deliveryTeam': user.expand['deliveryTeam']?.map((item) => item.id).toList() ?? [],
      'completedCustomer': user.expand['completedCustomer']?.map((item) => item.id).toList() ?? [],
      'returnList': user.expand['returnList']?.map((item) => item.id).toList() ?? [],
      'end_trip_checklists': user.expand['end_trip_checklists']?.map((item) => item.id).toList() ?? [],
      'trip': user.expand['trip'],
    };

    debugPrint('✅ User found and mapped successfully');
    debugPrint('   👤 Name: ${userData['name']}');
    debugPrint('   🎫 Trip Number: ${userData['tripNumberId']}');
    return LocalUsersModel.fromJson(userData);
  } catch (e) {
    debugPrint('❌ User fetch failed: ${e.toString()}');
    throw ServerException(message: e.toString(), statusCode: '500');
  }
}

  
  @override
Future<TripModel> getUserTrip(String userId) async {
  try {
    debugPrint('🔍 Loading trip for user: $userId');

    final prefs = await SharedPreferences.getInstance();
    final storedUserData = prefs.getString('user_data');

    if (storedUserData != null) {
      Map<String, dynamic> userData;
      try {
        userData = jsonDecode(storedUserData);
      } catch (e) {
        final cleanedData = storedUserData
            .replaceAll('""', '"')  // Remove double quotes
            .replaceAll(RegExp(r':\s+'), '": "')
            .replaceAll(RegExp(r',\s+'), '", "')
            .replaceAll('{', '{"')
            .replaceAll('}', '"}');
        userData = jsonDecode(cleanedData);
      }

      final userTripId = userData['tripNumberId'];
      debugPrint('🎫 User trip number ID: $userTripId');

      final tripRecords = await _pocketBaseClient.collection('tripticket').getFullList(
        filter: 'tripNumberId = "$userTripId"',
        expand: 'customers,deliveryTeam,personels,vehicle,checklist',
      );

      if (tripRecords.isEmpty) {
        throw const ServerException(
          message: 'No trip found for user',
          statusCode: '404',
        );
      }

      final tripRecord = tripRecords.first;
      final mappedData = {
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        'tripNumberId': tripRecord.data['tripNumberId'],
        'isAccepted': tripRecord.data['isAccepted'] ?? false,
        'customers': _mapExpandedRecord(tripRecord.expand['customers']),
        'deliveryTeam': _mapExpandedRecord(tripRecord.expand['deliveryTeam']),
        'personels': _mapExpandedRecord(tripRecord.expand['personels']),
        'vehicle': _mapExpandedRecord(tripRecord.expand['vehicle']),
        'checklist': _mapExpandedRecord(tripRecord.expand['checklist']),
      };

      await prefs.setString('user_trip_data', jsonEncode(mappedData));
      debugPrint('💾 Trip data cached successfully');

      return TripModel.fromJson(mappedData);
    }

    throw const ServerException(
      message: 'No stored user data found',
      statusCode: '404',
    );
  } catch (e) {
    debugPrint('❌ Failed to fetch user trip: $e');
    throw ServerException(message: e.toString(), statusCode: '500');
  }
}

Map<String, dynamic>? _mapExpandedRecord(dynamic record) {
  if (record == null) return null;
  
  if (record is List<RecordModel>) {
    if (record.isEmpty) return null;
    return {
      'id': record.first.id,
      'collectionId': record.first.collectionId,
      'collectionName': record.first.collectionName,
      ...record.first.data,
    };
  }
  
  if (record is RecordModel) {
    return {
      'id': record.id,
      'collectionId': record.collectionId,
      'collectionName': record.collectionName,
      ...record.data,
    };
  }
  
  return null;
}


  @override
  Future<LocalUsersModel> syncUserData(String userId) async {
    try {
      debugPrint('🔄 Syncing user data from remote for ID: $userId');
      
      final userRecord = await _pocketBaseClient.collection('users').getOne(
        userId,
        expand: 'checklist,updateTimeline,deliveryTeam,completedCustomer,returnList,end_trip_checklists,trips',
      );

      debugPrint('📊 Remote Sync Stats:');
      debugPrint('   👤 User Found: ${userRecord.id}');
      debugPrint('   📧 Email: ${userRecord.data['email']}');
      debugPrint('   🚚 Trip Number: ${userRecord.data['tripNumberId']}');

      final Map<String, dynamic> userData = {
        ...userRecord.data,
        'id': userRecord.id,
        'name': userRecord.data['name'] ?? '',
        'tripNumberId': userRecord.data['tripNumberId'] ?? '',
        'checklist': userRecord.expand['checklist']?.map((item) => item.id).toList() ?? [],
        'updateTimeline': userRecord.expand['updateTimeline']?.map((item) => item.id).toList() ?? [],
        'deliveryTeam': userRecord.expand['deliveryTeam']?.map((item) => item.id).toList() ?? [],
        'completedCustomer': userRecord.expand['completedCustomer']?.map((item) => item.id).toList() ?? [],
        'returnList': userRecord.expand['returnList']?.map((item) => item.id).toList() ?? [],
        'end_trip_checklists': userRecord.expand['end_trip_checklists']?.map((item) => item.id).toList() ?? [],
        'trip': userRecord.expand['trip'],
      };

      debugPrint('✅ User data synced successfully');
      return LocalUsersModel.fromJson(userData);
    } catch (e) {
      debugPrint('❌ User sync failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
@override
Future<TripModel> syncUserTripData(String userId) async {
  try {
    debugPrint('🔄 Syncing trip data for user: $userId');

    final userRecord = await _pocketBaseClient.collection('users').getOne(
      userId,
      expand: 'trip',
    );

    final tripNumberId = userRecord.data['tripNumberId'];
    debugPrint('🎫 Found trip number ID: $tripNumberId');

    final tripRecords = await _pocketBaseClient.collection('tripticket').getFullList(
      filter: 'tripNumberId = "$tripNumberId"',
      expand: 'customers,customers.invoices,customers.deliveryStatus,deliveryTeam,personels,vehicle,checklist,returnList,completedCustomer,undeliverableCustomer,tripUpdates,endTripChecklist',
    );

    if (tripRecords.isEmpty) {
      throw const ServerException(
        message: 'No trip found for user',
        statusCode: '404',
      );
    }

    final tripRecord = tripRecords.first;
    final mappedData = {
      'id': tripRecord.id,
      'collectionId': tripRecord.collectionId,
      'collectionName': tripRecord.collectionName,
      'tripNumberId': tripRecord.data['tripNumberId'],
      'isAccepted': tripRecord.data['isAccepted'] ?? false,
      'customers': _mapExpandedRecord(tripRecord.expand['customers']),
      'deliveryTeam': _mapExpandedRecord(tripRecord.expand['deliveryTeam']),
      'personels': _mapExpandedRecord(tripRecord.expand['personels']),
      'vehicle': _mapExpandedRecord(tripRecord.expand['vehicle']),
      'checklist': _mapExpandedRecord(tripRecord.expand['checklist']),
      'returnList': _mapExpandedRecord(tripRecord.expand['returnList']),
      'completedCustomer': _mapExpandedRecord(tripRecord.expand['completedCustomer']),
      'undeliverableCustomer': _mapExpandedRecord(tripRecord.expand['undeliverableCustomer']),
      'tripUpdates': _mapExpandedRecord(tripRecord.expand['tripUpdates']),
      'endTripChecklist': _mapExpandedRecord(tripRecord.expand['endTripChecklist']),
    };

    debugPrint('✅ Trip data synced successfully');
    debugPrint('   📊 Sync Stats:');
    debugPrint('   👥 Customers: ${tripRecord.expand['customers']?.length ?? 0}');
    debugPrint('   📝 Invoices: ${tripRecord.expand['customers.invoices']?.length ?? 0}');
    debugPrint('   🚛 Vehicle: ${tripRecord.expand['vehicle'] != null ? 'Found' : 'Not Found'}');

    return TripModel.fromJson(mappedData);
  } catch (e) {
    debugPrint('❌ Trip sync failed: ${e.toString()}');
    throw ServerException(message: e.toString(), statusCode: '500');
  }
}

}
