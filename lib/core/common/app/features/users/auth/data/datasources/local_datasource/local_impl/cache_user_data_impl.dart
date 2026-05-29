import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin CacheUserDataImpl on AuthLocalBase {
  Future<void> cacheUserData(LocalUsersModel user) async {
    try {
      debugPrint('💾 Caching user data locally');

      // Clear existing user data
      await clearUser();

      // Save to ObjectBox
      box.put(user);

      // Save to SharedPreferences for quick access
      final userData = {
        'id': user.id,
        'collectionId': user.collectionId,
        'collectionName': user.collectionName,
        'email': user.email,
        'name': user.name,
        'tripNumberId': user.tripNumberId,
        'deliveryTeam':
            user.deliveryTeam.target?.id, // Store ID for ToOne relation
      };

      await prefs.setString('user_data', jsonEncode(userData));

      debugPrint('✅ User cached successfully');
      debugPrint('   👤 User: ${user.name}');
      debugPrint('   📧 Email: ${user.email}');
      debugPrint('   🎫 Trip Number: ${user.tripNumberId}');
    } catch (e) {
      debugPrint('❌ Cache operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
