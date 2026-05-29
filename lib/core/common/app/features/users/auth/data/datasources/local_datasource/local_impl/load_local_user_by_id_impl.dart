import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin LoadLocalUserByIdImpl on AuthLocalBase {
  Future<LocalUsersModel> loadLocalUserById(String userId) async {
    try {
      debugPrint('🔍 Fetching user by ID from local storage: $userId');

      // Step 1️⃣: Try SharedPreferences first
      final storedData = prefs.getString('user_data');

      if (storedData != null) {
        final userData = jsonDecode(storedData);
        if (userData['id'] == userId) {
          debugPrint('📦 Found user in SharedPreferences');
          debugPrint('   👤 Name: ${userData['name']}');
          debugPrint('   📧 Email: ${userData['email']}');
          debugPrint('   🎫 Trip Number ID: ${userData['tripNumberId']}');
          debugPrint(
            '   🔑 Token: ${userData['tokenKey']?.substring(0, 10)}...',
          );
          debugPrint('   Timestamp: ${userData['timestamp']}');

          return LocalUsersModel(
            id: userData['id'],
            collectionId: userData['collectionId'],
            collectionName: userData['collectionName'],
            email: userData['email'],
            name: userData['name'],
            tripNumberId: userData['tripNumberId'],
            token: userData['tokenKey'],
          );
        } else {
          debugPrint(
            '⚠️ User in SharedPreferences does not match requested ID',
          );
        }
      } else {
        debugPrint('📦 No user data found in SharedPreferences');
      }

      // Step 2️⃣: Fallback to ObjectBox
      debugPrint('🏛️ Searching ObjectBox for user ID: $userId');

      final user =
          box
              .query(LocalUsersModel_.pocketbaseId.equals(userId))
              .build()
              .findFirst();

      if (user == null) {
        debugPrint('⚠️ User not found in ObjectBox for ID: $userId');
        throw const CacheException(message: 'User not found in local storage');
      }

      // Step 3️⃣: Massive debug logs for loaded user
      debugPrint('✅ Successfully loaded user from ObjectBox');
      debugPrint('   👤 Name: ${user.name}');
      debugPrint('   📧 Email: ${user.email}');
      debugPrint('   🎫 Trip Number ID: ${user.tripNumberId}');
      debugPrint('   🔑 Token: ${user.token?.substring(0, 10)}...');
      debugPrint('   🆔 Pocketbase ID: ${user.pocketbaseId}');
      debugPrint('   ObjectBox ID: ${user.objectBoxId}');

      // Trip info
      debugPrint('   🏷️ Trip Info:');
      debugPrint('      Trip ID: ${user.trip.target?.id ?? 'N/A'}');
      debugPrint('      Trip Name: ${user.trip.target?.name ?? 'N/A'}');

      return user;
    } catch (e) {
      debugPrint('❌ Local storage error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
