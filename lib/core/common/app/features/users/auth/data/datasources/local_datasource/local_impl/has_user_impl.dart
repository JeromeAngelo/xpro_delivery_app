import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin HasUserImpl on AuthLocalBase {
  Future<bool> hasUser() async {
    final query =
        box.query(LocalUsersModel_.pocketbaseId.notEquals('')).build();
    final count = query.count();
    final hasStoredUser = prefs.containsKey('user_data');
    debugPrint('📊 Current users in storage: $count');
    debugPrint('📦 Has stored user data: $hasStoredUser');
    return count > 0 && hasStoredUser;
  }
}
