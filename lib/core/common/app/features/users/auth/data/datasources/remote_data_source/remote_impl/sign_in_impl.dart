import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/auth_remote_base.dart';

/// Mixin that provides the [signIn] implementation for [AuthRemoteDataSrc].
mixin SignInImpl on AuthRemoteBase {
  Future<LocalUsersModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting sign in for: $email');

      final authData = await pocketBaseClient
          .collection('users')
          .authWithPassword(email, password);

      if (authData.token.isEmpty) {
        throw const ServerException(
          message: 'Authentication failed',
          statusCode: 'Auth Error',
        );
      }

      // Get the user record with expanded role data
      final userRecord = await pocketBaseClient
          .collection('users')
          .getOne(
            authData.record.id,
            expand:
                'userRole', // Make sure this matches the field name in PocketBase
          );

      // Check if user has Team Leader role
      final userRoleData = userRecord.expand['userRole'];
      bool isTeamLeader = false;
      Map<String, dynamic>? roleJson;

      if (userRoleData != null) {
        debugPrint('🔍 User role data type: ${userRoleData.runtimeType}');

        // Handle the case where userRoleData is a List<RecordModel>
        if (userRoleData.isNotEmpty) {
          final roleRecord = userRoleData.first;
          final roleName = roleRecord.data['name']?.toString() ?? '';
          isTeamLeader = roleName == 'Team Leader' || roleName == 'Driver';
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
          userData['expand'] = {'userRole': roleJson};
        }

        // Store properly formatted auth data
        await prefs.setString('auth_token', authData.token);
        await prefs.setString('user_data', jsonEncode(userData));

        debugPrint('✅ Authentication successful');
        debugPrint('💾 Stored user data: ${userData['name']}');
        debugPrint('   🆔 User ID: ${userData['id']}');
        debugPrint('   👑 Role: ${roleJson?['name'] ?? 'Unknown'}');
        debugPrint('   🔑 Token: ${authData.token.substring(0, 10)}...');

        // 🕓 Record login event in "authLogs" with device info
        await recordAuthLog(
          userId: authData.record.id,
          loginTime: DateTime.now().toUtc().toIso8601String(),
        );

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
          userData['expand'] = {'userRole': roleJson};
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
}
