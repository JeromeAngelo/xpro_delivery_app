import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin GetLocalUserImpl on AuthLocalBase {
  Future<LocalUsersModel> getLocalUser() async {
    try {
      debugPrint('🔍 Fetching user from local storage');
      final storedData = prefs.getString('user_data');

      if (storedData != null) {
        debugPrint('📦 Raw stored user data: $storedData');
        final userData = jsonDecode(storedData);

        // Create model with proper token mapping
        final user = LocalUsersModel(
          id: userData['id'],
          collectionId: userData['collectionId'],
          collectionName: userData['collectionName'],
          email: userData['email'],
          name: userData['name'],
          tripNumberId: userData['tripNumberId'],
          token: userData['tokenKey'], // Map tokenKey to token
        );

        debugPrint('✅ Successfully loaded user from local storage');
        debugPrint('   👤 User: ${user.name}');
        debugPrint('   🎫 Trip ID: ${user.tripId}');
        debugPrint('   🔑 Token: ${user.token?.substring(0, 10)}...');

        return user;
      }
      throw const CacheException(message: 'No stored user data found');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
