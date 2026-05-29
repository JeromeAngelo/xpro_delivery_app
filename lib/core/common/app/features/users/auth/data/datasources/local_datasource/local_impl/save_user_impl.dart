import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin SaveUserImpl on AuthLocalBase {
  Future<void> saveUser(LocalUsersModel user) async {
    try {
      debugPrint(
        '💾 [OFFLINE-FIRST] Saving user data locally for offline use...',
      );

      // Step 1️⃣: Clear existing local user data (optional, prevents duplicates)
      await clearUser();

      // Step 2️⃣: Save/update user in ObjectBox
      final existingUser =
          box
              .query(LocalUsersModel_.pocketbaseId.equals(user.pocketbaseId!))
              .build()
              .findFirst();

      LocalUsersModel updatedUser;

      if (existingUser != null) {
        debugPrint('🔄 Updating existing user in ObjectBox: ${user.name}');
        updatedUser = existingUser;

        // Update fields
        updatedUser.name = user.name;
        updatedUser.email = user.email;
        updatedUser.tripNumberId = user.tripNumberId;
        updatedUser.token = user.token;

        // Update related fields
        updatedUser.trip.target = user.trip.target;

        box.put(updatedUser);
      } else {
        debugPrint('➕ Adding new user to ObjectBox: ${user.name}');
        box.put(user);
        updatedUser = user;
      }

      debugPrint(
        '✅ User saved in ObjectBox successfully → OBX ID: ${updatedUser.objectBoxId} for ${updatedUser.name} ${updatedUser.pocketbaseId} with trip number id: ${updatedUser.tripNumberId}',
      );

      // Step 3️⃣: Save lightweight data in SharedPreferences
      final userData = {
        'id': updatedUser.id,
        'collectionId': updatedUser.collectionId,
        'collectionName': updatedUser.collectionName,
        'email': updatedUser.email,
        'name': updatedUser.name,
        'tripNumberId': updatedUser.tripNumberId,
        'tokenKey': updatedUser.token,
        'savedOffline': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString('user_data', jsonEncode(userData));
      await prefs.setString('auth_token', updatedUser.token ?? '');

      debugPrint('✅ User data cached in SharedPreferences for offline access');
      debugPrint('   👤 User: ${updatedUser.name}');
      debugPrint('   📧 Email: ${updatedUser.email}');
      debugPrint('   🆔 ID: ${updatedUser.id}');
      debugPrint('   🔑 Token: ${updatedUser.token?.substring(0, 10)}...');
    } catch (e) {
      debugPrint('❌ Failed to save user locally: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
