import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/auth_remote_base.dart';

/// Mixin that provides the [loadUser] implementation for [AuthRemoteDataSrc].
mixin LoadUserImpl on AuthRemoteBase {
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
}
