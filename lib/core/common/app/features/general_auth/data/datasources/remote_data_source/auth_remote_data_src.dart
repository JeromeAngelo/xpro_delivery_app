import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/data/models/auth_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_trip_collection/data/models/users_trip_collection_model.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_status_enum.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../users_roles/data/model/user_role_model.dart';

abstract class GeneralUserRemoteDataSource {
  const GeneralUserRemoteDataSource();

  Future<GeneralUserModel> signIn({
    required String email,
    required String password,
  });

  /// Get all users
  Future<List<GeneralUserModel>> getAllUsers();

  // Helper method to get a user by ID with expanded relations
  Future<GeneralUserModel> getUserById(String userId);

  /// Create a new user
  Future<GeneralUserModel> createUser(GeneralUserModel user);

  /// Update an existing user
  Future<GeneralUserModel> updateUser(GeneralUserModel user);

  /// Delete a specific user
  Future<bool> deleteUser(String userId);

  /// Delete all users
  Future<bool> deleteAllUsers();

  Future<void> signOut();
}

class GeneralUserRemoteDataSourceImpl implements GeneralUserRemoteDataSource {
  const GeneralUserRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

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
  Future<GeneralUserModel> signIn({
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
      final userRecord = await _pocketBaseClient
          .collection('users')
          .getOne(
            authData.record!.id,
            expand:
                'userRole', // Make sure this matches the field name in PocketBase
          );

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

      // Check if user has Team Leader role
      final userRoleData = userRecord.expand['userRole'];
      // bool isTeamLeader = false;
      bool isSuperAdministrator = false;
      bool isCollectionAdministator = false;
      bool isReturnAdministrator = false;
      bool isOtpCodeViewer = false;
      Map<String, dynamic>? roleJson;

      if (userRoleData != null) {
        debugPrint('🔍 User role data type: ${userRoleData.runtimeType}');

        // Handle the case where userRoleData is a List<RecordModel>
        if (userRoleData.isNotEmpty) {
          final roleRecord = userRoleData.first;
          final roleName = roleRecord.data['name']?.toString() ?? '';
          //  isTeamLeader = roleName == 'Team Leader';
          isSuperAdministrator = roleName == 'Super Administrator';
          isCollectionAdministator = roleName == 'Collection Administator';
          isReturnAdministrator = roleName == 'Return Administrator';
          isOtpCodeViewer = roleName == 'OTP Code Viewer';
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

      if (!isSuperAdministrator &&
          !isCollectionAdministator &&
          !isOtpCodeViewer &&
          !isReturnAdministrator) {
        throw const ServerException(
          message:
              'You don\'t have permission to sign in to this app. Please contact your admin support and try again.',
          statusCode: 'Permission Error',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> userData;

      try {
        // Prepare user data with role information
        userData = {
          'id': authData.record!.id,
          'collectionId': authData.record!.collectionId,
          'collectionName': authData.record!.collectionName,
          'email': authData.record!.data['email'],
          'name': authData.record!.data['name'],
          'tripNumberId': authData.record!.data['tripNumberId'],
          'tokenKey': authData.token,
          'status': authData.record!.data['status'],
        };

        // Add role data if available
        if (roleJson != null) {
          userData['expand'] = {'userRole': roleJson};
        }

        // Store properly formatted auth data
        await prefs.setString(_authTokenKey, authData.token);
        await prefs.setString(_authUserKey, jsonEncode(userData));

        debugPrint('✅ Authentication successful');
        debugPrint('💾 Stored user data: ${userData['name']}');
        debugPrint('   🆔 User ID: ${userData['id']}');
        debugPrint('   👑 Role: ${roleJson?['name'] ?? 'Unknown'}');
        debugPrint('   🔑 Token: ${authData.token.substring(0, 10)}...');

        return GeneralUserModel.fromJson(userData);
      } catch (e) {
        debugPrint('⚠️ Error formatting user data: ${e.toString()}');

        // Fallback data formatting
        final cleanedData = jsonEncode(authData.record!.data)
            .replaceAll(RegExp(r':\s+'), '": "')
            .replaceAll(RegExp(r',\s+'), '", "')
            .replaceAll('{', '{"')
            .replaceAll('}', '"}');

        userData = jsonDecode(cleanedData);
        userData['tokenKey'] = authData.token;

        // Add role data if available
        if (roleJson != null) {
          userData['expand'] = {'userRole': roleJson};
        }

        return GeneralUserModel.fromJson(userData);
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
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out user');
      _pocketBaseClient.authStore.clear();

      // Clear saved auth data from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      await prefs.remove(_authUserKey);

      debugPrint('✅ User signed out successfully');
      return;
    } catch (e) {
      debugPrint('❌ Sign out error: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  @override
  Future<List<GeneralUserModel>> getAllUsers() async {
    try {
      debugPrint('🔄 Fetching all users');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      // First, let's examine the structure of a single user record to understand the field names
      try {
        final sampleRecords =
            await _pocketBaseClient.collection('users').getFullList();
        if (sampleRecords.isNotEmpty) {
          final record = sampleRecords.first;
          debugPrint('📋 Sample user record structure:');
          debugPrint('Record ID: ${record.id}');
          debugPrint('Record data keys: ${record.data.keys.join(', ')}');

          // Print all fields in the record to see what's available
          record.data.forEach((key, value) {
            debugPrint('Field: $key = $value');
          });
        }
      } catch (e) {
        debugPrint('⚠️ Error examining sample record: $e');
      }

      // Now fetch all users with explicit fields
      final records = await _pocketBaseClient
          .collection('users')
          .getFullList(expand: 'trip,deliveryTeam,userRole', sort: '-created');

      debugPrint('✅ Retrieved ${records.length} users from API');

      List<GeneralUserModel> users = [];

      for (var record in records) {
        try {
          // Debug the raw record data
          debugPrint('🔍 Processing user record: ${record.id}');
          debugPrint('Raw data keys: ${record.data.keys.join(', ')}');

          // Check for email field with different possible names
          String? email;
          if (record.data.containsKey('email')) {
            email = record.data['email'];
            debugPrint('📧 Found email field: $email');
          } else if (record.data.containsKey('username')) {
            email = record.data['email'];
            debugPrint('📧 Using username as email: $email');
          } else {
            // Try to find any field that might contain email
            for (var key in record.data.keys) {
              final value = record.data[key]?.toString() ?? '';
              if (value.contains('@') && value.contains('.')) {
                email = value;
                debugPrint('📧 Found potential email in field $key: $email');
                break;
              }
            }
          }

          // Helper function to safely extract string or first element from list
          String? extractStringValue(dynamic value) {
            if (value == null) return null;
            if (value is String) return value;
            if (value is List && value.isNotEmpty) {
              return value.first?.toString();
            }
            return value.toString();
          }

          // Create a detailed map with all fields explicitly
          final mappedData = {
            'id': record.id,
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            'email': email,
            'name': record.data['name'],
            'profilePic': record.data['profilePic'],
            'tripNumberId': record.data['tripNumberId'],
            'userRole': extractStringValue(record.data['userRole']),
            'trip': extractStringValue(record.data['trip']),
            'deliveryTeam': extractStringValue(record.data['deliveryTeam']),
            'status': record.data['status'],
          };

          // Debug the extracted email
          debugPrint(
            '📧 User ${record.id} mapped email: ${mappedData['email']}',
          );

          // Process expanded relations
          TripModel? tripModel;
          DeliveryTeamModel? deliveryTeamModel;
          UserRoleModel? roleModel;

          // Process trip expand if available
          if (record.expand.containsKey('trip') &&
              record.expand['trip'] != null) {
            tripModel = _processTripExpand(record.expand['trip']);
          }

          // Process delivery team expand if available
          if (record.expand.containsKey('deliveryTeam') &&
              record.expand['deliveryTeam'] != null) {
            deliveryTeamModel = _processDeliveryTeamExpand(
              record.expand['deliveryTeam'],
            );
          }

          // Process user role expand if available
          if (record.expand.containsKey('userRole') &&
              record.expand['userRole'] != null) {
            roleModel = _processRoleExpand(record.expand['userRole']);
          }

          // Convert status string to enum
          UserStatusEnum status = UserStatusEnum.suspended; // Default value
          if (mappedData['status'] != null) {
            final statusStr = mappedData['status'].toString().toLowerCase();
            try {
              status = UserStatusEnum.values.firstWhere(
                (e) => e.name.toLowerCase() == statusStr,
                orElse: () => UserStatusEnum.suspended,
              );
              debugPrint(
                '🔄 Converted status string "$statusStr" to enum: ${status.name}',
              );
            } catch (e) {
              debugPrint(
                '⚠️ Error converting status: $e, using default: suspended',
              );
            }
          } else {
            debugPrint('⚠️ Status field is null, using default: suspended');
          }

          // Determine if user has a trip
          bool hasTrip =
              tripModel != null ||
              (mappedData['trip'] != null &&
                  mappedData['trip'].toString().isNotEmpty);

          debugPrint('👤 User ${mappedData['name']} has trip: $hasTrip');

          // Create the user model with explicit field mapping
          final userModel = GeneralUserModel(
            id: mappedData['id'] as String?,
            collectionId: mappedData['collectionId'] as String?,
            collectionName: mappedData['collectionName'] as String?,
            email: mappedData['email'] as String?,
            name: mappedData['name'] as String?,
            profilePic: mappedData['profilePic'] as String?,
            tripNumberId: mappedData['tripNumberId'] as String?,
            roleId: mappedData['userRole'] as String?,
            tripId: mappedData['trip'] as String?,
            deliveryTeamId: mappedData['deliveryTeam'] as String?,
            tripModel: tripModel,
            deliveryTeamModel: deliveryTeamModel,
            roleModel: roleModel,
            status: status, // Use the converted enum value
            hasTrip: hasTrip, // Set the hasTrip field
          );

          // Debug the created model
          debugPrint(
            '✅ Created user model for ${userModel.name} with email: ${userModel.email}, status: ${userModel.status?.name}, hasTrip: ${userModel.hasTrip}',
          );
          debugPrint(
            '📅 Created: ${userModel.created?.toIso8601String() ?? 'null'}, Updated: ${userModel.updated?.toIso8601String() ?? 'null'}',
          );

          users.add(userModel);
        } catch (itemError) {
          debugPrint(
            '⚠️ Error processing user record: ${itemError.toString()}',
          );
        }
      }

      debugPrint('✅ Successfully processed ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('❌ Failed to fetch all users: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch all users: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // Helper method to process trip expand data
  TripModel? _processTripExpand(dynamic tripData) {
    if (tripData == null) return null;

    try {
      debugPrint(
        '🔄 Processing trip expand data type: ${tripData.runtimeType}',
      );

      if (tripData is RecordModel) {
        return TripModel.fromJson({
          'id': tripData.id,
          'collectionId': tripData.collectionId,
          'collectionName': tripData.collectionName,
          ...tripData.data,
        });
      } else if (tripData is List && tripData.isNotEmpty) {
        final firstTrip = tripData.first;
        if (firstTrip is RecordModel) {
          return TripModel.fromJson({
            'id': firstTrip.id,
            'collectionId': firstTrip.collectionId,
            'collectionName': firstTrip.collectionName,
            ...firstTrip.data,
          });
        }
      } else if (tripData is String) {
        // If it's just a string ID, return a minimal model
        return TripModel(id: tripData);
      }

      debugPrint('⚠️ Unhandled trip data format: ${tripData.runtimeType}');
    } catch (e) {
      debugPrint('❌ Error processing trip expand data: $e');
    }

    return null;
  }

  // Helper method to process delivery team expand data
  DeliveryTeamModel? _processDeliveryTeamExpand(dynamic teamData) {
    if (teamData == null) return null;

    try {
      debugPrint(
        '🔄 Processing delivery team expand data type: ${teamData.runtimeType}',
      );

      if (teamData is RecordModel) {
        return DeliveryTeamModel.fromJson({
          'id': teamData.id,
          'collectionId': teamData.collectionId,
          'collectionName': teamData.collectionName,
          ...teamData.data,
        });
      } else if (teamData is List && teamData.isNotEmpty) {
        final firstTeam = teamData.first;
        if (firstTeam is RecordModel) {
          return DeliveryTeamModel.fromJson({
            'id': firstTeam.id,
            'collectionId': firstTeam.collectionId,
            'collectionName': firstTeam.collectionName,
            ...firstTeam.data,
          });
        }
      } else if (teamData is String) {
        // If it's just a string ID, return a minimal model
        return DeliveryTeamModel(id: teamData);
      }

      debugPrint(
        '⚠️ Unhandled delivery team data format: ${teamData.runtimeType}',
      );
    } catch (e) {
      debugPrint('❌ Error processing delivery team expand data: $e');
    }

    return null;
  }

  // Helper method to process user role expand data
  UserRoleModel? _processRoleExpand(dynamic roleData) {
    if (roleData == null) return null;

    try {
      debugPrint(
        '🔄 Processing user role expand data type: ${roleData.runtimeType}',
      );

      if (roleData is RecordModel) {
        return UserRoleModel.fromJson({
          'id': roleData.id,
          'name': roleData.data['name'],
          'permissions': roleData.data['permissions'],
        });
      } else if (roleData is List && roleData.isNotEmpty) {
        final firstRole = roleData.first;
        if (firstRole is RecordModel) {
          return UserRoleModel.fromJson({
            'id': firstRole.id,
            'name': firstRole.data['name'],
            'permissions': firstRole.data['permissions'],
          });
        }
      } else if (roleData is String) {
        // If it's just a string ID, return a minimal model
        return UserRoleModel(id: roleData);
      }

      debugPrint('⚠️ Unhandled user role data format: ${roleData.runtimeType}');
    } catch (e) {
      debugPrint('❌ Error processing user role expand data: $e');
    }

    return null;
  }

  @override
  Future<GeneralUserModel> createUser(GeneralUserModel user) async {
    try {
      debugPrint('🔄 Creating new user: ${user.email}');

      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      // Prepare data for creation
      final userData = user.toJson();

      // Remove ID fields that should be generated by the server
      userData.remove('id');
      userData.remove('collectionId');
      userData.remove('collectionName');

      // Ensure password is included for new users
      if (!userData.containsKey('password') ||
          userData['password'] == null ||
          userData['password'].isEmpty) {
        throw const ServerException(
          message: 'Password is required for new users',
          statusCode: '400',
        );
      }

      // Ensure password confirmation is included and matches password
      if (!userData.containsKey('passwordConfirm') ||
          userData['passwordConfirm'] == null ||
          userData['passwordConfirm'].isEmpty) {
        // If passwordConfirm is missing, set it to match the password
        userData['passwordConfirm'] = userData['password'];
      } else if (userData['password'] != userData['passwordConfirm']) {
        // If passwords don't match, throw an exception
        throw const ServerException(
          message: 'Password and confirmation do not match',
          statusCode: '400',
        );
      }

      // Set email visibility to true by default
      userData['emailVisibility'] = true;

      final record = await _pocketBaseClient
          .collection('users')
          .create(body: userData);

      debugPrint('✅ User created successfully: ${record.id}');

      // Create user performance record only for Helper and Driver roles
      try {
        if (userData['userRole'] != null) {
          debugPrint('🔄 Checking user role for performance record creation');

          // Get the user role to check if it's "Helper" or "Driver"
          final userRoleRecord = await _pocketBaseClient
              .collection('userRoles')
              .getOne(userData['userRole']);

          final roleName = userRoleRecord.data['name']?.toString();
          debugPrint('👤 User role for performance: $roleName');

          if (roleName == 'Helper' || roleName == 'Driver') {
            debugPrint(
              '🔄 Creating user performance record for $roleName user: ${record.id}',
            );

            final performanceData = {'user': record.id};

            await _pocketBaseClient
                .collection('userPerformance')
                .create(body: performanceData);

            debugPrint(
              '✅ User performance record created successfully for $roleName user',
            );
          } else {
            debugPrint(
              'ℹ️ User role "$roleName" does not require performance tracking',
            );
          }
        } else {
          debugPrint(
            '⚠️ No user role assigned, skipping performance record creation',
          );
        }
      } catch (performanceError) {
        debugPrint(
          '⚠️ Failed to create user performance record: ${performanceError.toString()}',
        );
        // Note: We don't throw here to avoid failing the entire user creation
        // The user was created successfully, but performance record creation failed
      }

      // Check if user has "Helper" or "Driver" role and create personnel record
      try {
        if (userData['userRole'] != null) {
          debugPrint('🔄 Checking user role for personnel record creation');

          // Get the user role to check if it's "Helper" or "Driver"
          final userRoleRecord = await _pocketBaseClient
              .collection('userRoles')
              .getOne(userData['userRole']);

          final roleName = userRoleRecord.data['name']?.toString();
          debugPrint('👤 User role: $roleName');

          if (roleName == 'Helper' || roleName == 'Driver') {
            debugPrint('🔄 Creating personnel record for $roleName user');

            // Map user roles to personnel roles
            String personnelRole;
            if (roleName == 'Driver') {
              personnelRole = 'team_leader';
            } else if (roleName == 'Helper') {
              personnelRole = 'helper';
            } else {
              personnelRole = 'helper'; // fallback
            }

            final personnelData = {
              'name': userData['name'] ?? record.data['name'],
              'role': personnelRole,
              'user': record.id,
            };

            debugPrint('👥 Mapping $roleName -> $personnelRole for personnel record');

            await _pocketBaseClient
                .collection('personels')
                .create(body: personnelData);

            debugPrint(
              '✅ Personnel record created successfully for $roleName user',
            );
          }
        }
      } catch (personnelError) {
        debugPrint(
          '⚠️ Failed to create personnel record: ${personnelError.toString()}',
        );
        // Note: We don't throw here to avoid failing the entire user creation
        // The user was created successfully, but personnel record creation failed
      }

      // Fetch the created record with expanded relations
      return getUserById(record.id);
    } catch (e) {
      debugPrint('❌ Failed to create user: ${e.toString()}');
      throw ServerException(
        message: 'Failed to create user: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<GeneralUserModel> updateUser(GeneralUserModel user) async {
    try {
      debugPrint('🔄 Updating user: ${user.id}');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      if (user.id == null || user.id!.isEmpty) {
        throw const ServerException(
          message: 'Cannot update user: Missing ID',
          statusCode: '400',
        );
      }

      // Prepare data for update
      final userData = user.toJson();

      // Remove fields that shouldn't be updated
      userData.remove('id');
      userData.remove('collectionId');
      userData.remove('collectionName');

      // Check if password is being updated
      bool isUpdatingPassword =
          userData.containsKey('password') &&
          userData['password'] != null &&
          userData['password'].isNotEmpty;

      // If updating password, ensure oldPassword is provided
      if (isUpdatingPassword) {
        if (!userData.containsKey('oldPassword') ||
            userData['oldPassword'] == null ||
            userData['oldPassword'].isEmpty) {
          throw const ServerException(
            message: 'Old password is required to change password',
            statusCode: '400',
          );
        }

        // Log that we're updating password with oldPassword
        debugPrint('🔑 Updating password with oldPassword provided');
      } else {
        // If not updating password, remove password-related fields
        userData.remove('password');
        userData.remove('passwordConfirm');
        userData.remove('oldPassword');
      }

      // Log the update data (excluding sensitive information)
      final logData = Map<String, dynamic>.from(userData);
      if (logData.containsKey('password')) logData['password'] = '********';
      if (logData.containsKey('passwordConfirm')) {
        logData['passwordConfirm'] = '********';
      }
      if (logData.containsKey('oldPassword')) {
        logData['oldPassword'] = '********';
      }
      debugPrint('📝 Update data: $logData');

      // Perform the update
      await _pocketBaseClient
          .collection('users')
          .update(user.id!, body: userData);

      debugPrint('✅ User updated successfully');

      // Check if user has "Helper" or "Driver" role and update personnel record
      try {
        if (userData['userRole'] != null) {
          debugPrint('🔄 Checking user role for personnel record update');

          // Get the user role to check if it's "Helper" or "Driver"
          final userRoleRecord = await _pocketBaseClient
              .collection('userRoles')
              .getOne(userData['userRole']);

          final roleName = userRoleRecord.data['name']?.toString();
          debugPrint('👤 User role for update: $roleName');

          if (roleName == 'Helper' || roleName == 'Driver') {
            debugPrint('🔄 Updating personnel record for $roleName user');

            // Map user roles to personnel roles
            String personnelRole;
            if (roleName == 'Driver') {
              personnelRole = 'team_leader';
            } else if (roleName == 'Helper') {
              personnelRole = 'helper';
            } else {
              personnelRole = 'helper'; // fallback
            }

            debugPrint('👥 Mapping $roleName -> $personnelRole for personnel update');

            // Try to find existing personnel record for this user
            final existingPersonnelRecords = await _pocketBaseClient
                .collection('personels')
                .getList(
                  page: 1,
                  perPage: 1,
                  filter: 'user = "${user.id}"',
                );

            final personnelUpdateData = {
              'name': userData['name'] ?? user.name,
              'role': personnelRole,
              'user': user.id,
            };

            if (existingPersonnelRecords.items.isNotEmpty) {
              // Update existing personnel record
              final existingPersonnelId = existingPersonnelRecords.items.first.id;
              await _pocketBaseClient
                  .collection('personels')
                  .update(existingPersonnelId, body: personnelUpdateData);
              
              debugPrint('✅ Updated existing personnel record for $roleName user');
            } else {
              // Create new personnel record if it doesn't exist
              await _pocketBaseClient
                  .collection('personels')
                  .create(body: personnelUpdateData);
              
              debugPrint('✅ Created new personnel record for $roleName user');
            }
          } else {
            debugPrint('ℹ️ User role "$roleName" does not require personnel record');
            
            // If the user role is no longer Driver/Helper, remove any existing personnel record
            try {
              final existingPersonnelRecords = await _pocketBaseClient
                  .collection('personels')
                  .getList(
                    page: 1,
                    perPage: 1,
                    filter: 'user = "${user.id}"',
                  );

              if (existingPersonnelRecords.items.isNotEmpty) {
                final existingPersonnelId = existingPersonnelRecords.items.first.id;
                await _pocketBaseClient
                    .collection('personels')
                    .delete(existingPersonnelId);
                
                debugPrint('🗑️ Removed personnel record - user no longer Driver/Helper');
              }
            } catch (deleteError) {
              debugPrint('⚠️ Failed to remove personnel record: ${deleteError.toString()}');
            }
          }
        } else {
          debugPrint('⚠️ No user role assigned, skipping personnel record update');
        }
      } catch (personnelError) {
        debugPrint('⚠️ Failed to update personnel record: ${personnelError.toString()}');
        // Note: We don't throw here to avoid failing the entire user update
        // The user was updated successfully, but personnel record update failed
      }

      // Fetch the updated record with expanded relations
      return getUserById(user.id!);
    } catch (e) {
      debugPrint('❌ Failed to update user: ${e.toString()}');
      throw ServerException(
        message: 'Failed to update user: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteUser(String userId) async {
    try {
      debugPrint('🔄 Deleting user: $userId');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      // First, check if the user exists
      await _pocketBaseClient.collection('users').getOne(userId);

      // Delete the user
      await _pocketBaseClient.collection('users').delete(userId);

      debugPrint('✅ User deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete user: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete user: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteAllUsers() async {
    try {
      debugPrint('⚠️ Attempting to delete all users');

      // Get all users
      final records = await _pocketBaseClient.collection('users').getFullList();

      // Delete each user
      for (final record in records) {
        await _pocketBaseClient.collection('users').delete(record.id);
      }

      debugPrint('✅ All users deleted successfully: ${records.length} records');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete all users: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete all users: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<GeneralUserModel> getUserById(String userId) async {
    try {
      debugPrint('🔄 Fetching user by ID: $userId');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      // Fetch the user with expanded relations
      final record = await _pocketBaseClient
          .collection('users')
          .getOne(userId, expand: 'trip,deliveryTeam,userRole,trip_collection');

      debugPrint('✅ Retrieved user record: ${record.id}');

      // Debug the raw record data
      debugPrint('🔍 Processing user record: ${record.id}');
      debugPrint('Raw data keys: ${record.data.keys.join(', ')}');

      // Check for email field with different possible names
      String? email;
      if (record.data.containsKey('email')) {
        email = record.data['email'];
        debugPrint('📧 Found email field: $email');
      } else if (record.data.containsKey('username')) {
        email = record.data['email'];
        debugPrint('📧 Using username as email: $email');
      } else {
        // Try to find any field that might contain email
        for (var key in record.data.keys) {
          final value = record.data[key]?.toString() ?? '';
          if (value.contains('@') && value.contains('.')) {
            email = value;
            debugPrint('📧 Found potential email in field $key: $email');
            break;
          }
        }
      }

      // Parse created and updated dates
      DateTime? createdDate;
      DateTime? updatedDate;

      try {
        createdDate = record.created as DateTime?;
      } catch (e) {
        debugPrint('⚠️ Error parsing created date: $e');
      }

      try {
        updatedDate = record.updated as DateTime?;
      } catch (e) {
        debugPrint('⚠️ Error parsing updated date: $e');
      }

      // Helper function to safely extract string or first element from list
      String? extractStringValue(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;
        if (value is List && value.isNotEmpty) {
          return value.first?.toString();
        }
        return value.toString();
      }

      // Create a detailed map with all fields explicitly
      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'email': email,
        'name': record.data['name'],
        'profilePic': record.data['profilePic'],
        'tripNumberId': record.data['tripNumberId'],
        'userRole': extractStringValue(record.data['userRole']),
        'trip': extractStringValue(record.data['trip']),
        'deliveryTeam': extractStringValue(record.data['deliveryTeam']),
        'trip_collection':
            record.data['trip_collection'], // Keep as is for collections
        'status': record.data['status'],
        'created': createdDate,
        'updated': updatedDate,
      };

      // Debug the extracted email
      debugPrint('📧 User ${record.id} mapped email: ${mappedData['email']}');
      debugPrint(
        '📅 Created: ${createdDate?.toIso8601String() ?? 'null'}, Updated: ${updatedDate?.toIso8601String() ?? 'null'}',
      );

      // Process expanded relations
      TripModel? tripModel;
      DeliveryTeamModel? deliveryTeamModel;
      UserRoleModel? roleModel;
      List<UserTripCollectionModel> tripCollectionModels = [];

      // Process trip expand if available
      if (record.expand.containsKey('trip') && record.expand['trip'] != null) {
        tripModel = _processTripExpand(record.expand['trip']);
        debugPrint('🚗 Processed trip relation: ${tripModel?.id}');
      }

      // Process delivery team expand if available
      if (record.expand.containsKey('deliveryTeam') &&
          record.expand['deliveryTeam'] != null) {
        deliveryTeamModel = _processDeliveryTeamExpand(
          record.expand['deliveryTeam'],
        );
        debugPrint(
          '👥 Processed delivery team relation: ${deliveryTeamModel?.id}',
        );
      }

      // Process user role expand if available
      if (record.expand.containsKey('userRole') &&
          record.expand['userRole'] != null) {
        roleModel = _processRoleExpand(record.expand['userRole']);
        debugPrint('👑 Processed user role relation: ${roleModel?.name}');
      }

      // Process trip collection expand if available
      if (record.expand.containsKey('trip_collection') &&
          record.expand['trip_collection'] != null) {
        final tripCollectionData = record.expand['trip_collection'];
        if (tripCollectionData is List) {
          for (var item in tripCollectionData!) {
            try {
              final tripCollectionModel = UserTripCollectionModel.fromJson({
                'id': item.id,
                'collectionId': item.collectionId,
                'collectionName': item.collectionName,
                ...item.data,
              });
              tripCollectionModels.add(tripCollectionModel);
            } catch (e) {
              debugPrint('⚠️ Error processing trip collection item: $e');
            }
          }
          debugPrint(
            '📚 Processed ${tripCollectionModels.length} trip collection records',
          );
        }
      }

      // Convert status string to enum
      UserStatusEnum status = UserStatusEnum.suspended; // Default value
      if (mappedData['status'] != null) {
        final statusStr = mappedData['status'].toString().toLowerCase();
        try {
          status = UserStatusEnum.values.firstWhere(
            (e) => e.name.toLowerCase() == statusStr,
            orElse: () => UserStatusEnum.suspended,
          );
          debugPrint(
            '🔄 Converted status string "$statusStr" to enum: ${status.name}',
          );
        } catch (e) {
          debugPrint(
            '⚠️ Error converting status: $e, using default: suspended',
          );
        }
      } else {
        debugPrint('⚠️ Status field is null, using default: suspended');
      }

      // Determine if user has a trip
      bool hasTrip =
          tripModel != null ||
          (mappedData['trip'] != null &&
              mappedData['trip'].toString().isNotEmpty) ||
          (mappedData['tripNumberId'] != null &&
              mappedData['tripNumberId'].toString().isNotEmpty);

      debugPrint('👤 User ${mappedData['name']} has trip: $hasTrip');

      // Create the user model with explicit field mapping and expanded relations
      final userModel = GeneralUserModel(
        id: mappedData['id'] as String?,
        collectionId: mappedData['collectionId'] as String?,
        collectionName: mappedData['collectionName'] as String?,
        email: mappedData['email'] as String?,
        name: mappedData['name'] as String?,
        profilePic: mappedData['profilePic'] as String?,
        tripNumberId: mappedData['tripNumberId'] as String?,
        roleId: mappedData['userRole'] as String?,
        tripId: mappedData['trip'] as String?,
        deliveryTeamId: mappedData['deliveryTeam'] as String?,
        tripCollectionIds:
            mappedData['trip_collection'] is List
                ? (mappedData['trip_collection'] as List)
                    .map((e) => e.toString())
                    .toList()
                : mappedData['trip_collection'] != null
                ? [mappedData['trip_collection'].toString()]
                : null,
        tripModel: tripModel,
        deliveryTeamModel: deliveryTeamModel,
        roleModel: roleModel,
        tripCollectionModels: tripCollectionModels,
        status: status, // Use the converted enum value
        hasTrip: hasTrip, // Set the hasTrip field
        created: mappedData['created'] as DateTime?,
        updated: mappedData['updated'] as DateTime?,
      );

      debugPrint(
        '✅ Created user model for ${userModel.name} with email: ${userModel.email}, status: ${userModel.status?.name}, hasTrip: ${userModel.hasTrip}',
      );
      debugPrint(
        '📅 Created: ${userModel.created?.toIso8601String() ?? 'null'}, Updated: ${userModel.updated?.toIso8601String() ?? 'null'}',
      );
      return userModel;
    } catch (e) {
      debugPrint('❌ Failed to fetch user by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch user by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // // Helper method to map a record to a GeneralUserModel
  // GeneralUserModel _mapRecordToUserModel(RecordModel record) {
  //   try {
  //     // Extract basic user data
  //     final userData = {
  //       'id': record.id,
  //       'collectionId': record.collectionId,
  //       'collectionName': record.collectionName,
  //       'email': record.data['email'],
  //       'name': record.data['name'],
  //       'profilePic': record.data['profilePic'],
  //       'tripNumberId': record.data['tripNumberId'],
  //       'token': record.data['token'],
  //       'status': record.data['status'],
  //     };

  //     // Extract IDs for relationships
  //     String? roleId = record.data['userRole'];
  //     String? tripId = record.data['trip'];
  //     String? deliveryTeamId = record.data['deliveryTeam'];

  //     // Extract trip collection IDs
  //     List<String>? tripCollectionIds;
  //     if (record.data['trip_collection'] != null) {
  //       if (record.data['trip_collection'] is List) {
  //         tripCollectionIds =
  //             (record.data['trip_collection'] as List)
  //                 .map((id) => id.toString())
  //                 .toList();
  //       } else if (record.data['trip_collection'] is String) {
  //         // Handle case where it might be a single string ID
  //         tripCollectionIds = [record.data['trip_collection'].toString()];
  //       }
  //     }

  //     // Convert status string to enum
  //     UserStatusEnum status;
  //     if (userData['status'] is String) {
  //       // Convert string to enum
  //       status = UserStatusEnum.values.firstWhere(
  //         (e) => e.name == (userData['status'] as String).toLowerCase(),
  //         orElse: () => UserStatusEnum.suspended,
  //       );
  //     } else if (userData['status'] is UserStatusEnum) {
  //       // Already an enum
  //       status = userData['status'] as UserStatusEnum;
  //     } else {
  //       // Default value
  //       status = UserStatusEnum.suspended;
  //     }

  //     // Create the user model with just the basic data and IDs
  //     return GeneralUserModel(
  //       id: userData['id'] as String?,
  //       collectionId: userData['collectionId'] as String?,
  //       collectionName: userData['collectionName'] as String?,
  //       email: userData['email'] as String?,
  //       name: userData['name'] as String?,
  //       profilePic: userData['profilePic'] as String?,
  //       tripNumberId: userData['tripNumberId'] as String?,
  //       status: status, // Use the converted enum value
  //       token: userData['token'] as String?,
  //       roleId: roleId,
  //       tripId: tripId,
  //       deliveryTeamId: deliveryTeamId,
  //       tripCollectionIds: tripCollectionIds,
  //     );
  //   } catch (e) {
  //     debugPrint('❌ Error mapping record to UserModel: $e');
  //     throw ServerException(
  //       message: 'Failed to map record to UserModel: $e',
  //       statusCode: '500',
  //     );
  //   }
  // }

  // Helper method to map an expanded record to a map
  // Map<String, dynamic> _mapExpandedRecord(RecordModel record) {
  //   return {
  //     'id': record.id,
  //     'collectionId': record.collectionId,
  //     'collectionName': record.collectionName,
  //     ...Map<String, dynamic>.from(record.data),
  //     'created': record.created,
  //     'updated': record.updated,
  //   };
  // }
}
