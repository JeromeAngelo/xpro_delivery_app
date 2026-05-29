import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin ForceReloadLocalUserByIdImpl on AuthLocalBase {
  Future<LocalUsersModel> forceReloadLocalUserById(String userId) async {
    try {
      final safeUserId = userId.trim();
      debugPrint('🔁 LOCAL: Force reloading user by ID="$safeUserId"');

      if (safeUserId.isEmpty) {
        debugPrint('⚠️ LOCAL: userId is empty. Cannot query ObjectBox safely.');
        throw const CacheException(message: 'Invalid userId (empty)');
      }

      // -----------------------------------------------------
      // 1️⃣ Reload User from ObjectBox (fresh query)
      // -----------------------------------------------------
      final userQuery =
          box.query(LocalUsersModel_.pocketbaseId.equals(safeUserId)).build();
      final user = userQuery.findFirst();
      userQuery.close();

      if (user == null) {
        // ❌ User itself must exist (this is the only hard fail)
        throw const CacheException(message: 'User not found in local DB');
      }

      debugPrint('👤 User reloaded → ${user.name} (OBX: ${user.objectBoxId})');

      // -----------------------------------------------------
      // 2️⃣ Reload Trip relation (NULL-SAFE + BROKEN-RELATION SAFE)
      // -----------------------------------------------------
      try {
        // Prefer targetId because it's the real ObjectBox relation id
        final tripObxId = user.trip.targetId;

        // ✅ If no trip is set or invalid → clear it safely and continue
        if (tripObxId == 0) {
          debugPrint(
            'ℹ️ User has no active trip (targetId=0). Clearing & bypassing.',
          );
          user.trip
            ..target = null
            ..targetId = 0;
        } else {
          final fullTrip = tripBox.get(tripObxId);

          if (fullTrip != null) {
            user.trip
              ..target = fullTrip
              ..targetId = fullTrip.objectBoxId;

            debugPrint(
              '📦 Trip relation reloaded → ${fullTrip.name} (OBX: ${fullTrip.objectBoxId})',
            );
          } else {
            // ✅ Relation points to missing Trip record → clear safely
            debugPrint(
              '⚠️ Trip targetId=$tripObxId but trip record missing. Clearing relation.',
            );
            user.trip
              ..target = null
              ..targetId = 0;
          }
        }
      } catch (e) {
        // ✅ Trip MUST NEVER break the flow
        debugPrint('⚠️ Trip reload failed (ignored): $e');
        user.trip
          ..target = null
          ..targetId = 0;
      }

      // -----------------------------------------------------
      // 3️⃣ Persist User so listeners/UI refresh
      // -----------------------------------------------------
      box.put(user);

      // -----------------------------------------------------
      // 4️⃣ Debug logs
      // -----------------------------------------------------
      debugPrint('✅ LOCAL: User force reload COMPLETE');
      debugPrint('   👤 Name: ${user.name}');
      debugPrint('   📧 Email: ${user.email}');
      debugPrint('   🎫 Trip Number ID: ${user.tripNumberId}');
      debugPrint('   🆔 Pocketbase ID: ${user.pocketbaseId}');
      debugPrint('   ObjectBox ID: ${user.objectBoxId}');
      debugPrint(
        '   🏷️ Trip OBX ID: ${user.trip.targetId == 0 ? 'NO ACTIVE TRIP' : user.trip.targetId}',
      );
      debugPrint(
        '   🏷️ Trip PB ID: ${user.trip.target?.id ?? 'NO ACTIVE TRIP'}',
      );

      return user;
    } catch (e, st) {
      debugPrint('❌ forceReloadLocalUserById ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
