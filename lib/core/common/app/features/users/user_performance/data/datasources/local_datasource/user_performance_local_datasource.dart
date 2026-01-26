import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/data/model/user_performance_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

import '../../../../../../../../services/objectbox.dart';

abstract class UserPerformanceLocalDataSource {
  // Get user performance by user ID
  Future<UserPerformanceModel> getUserPerformanceByUserId(String userId);

  // Cache user performance data
  Future<void> cacheUserPerformance(UserPerformanceModel userPerformance);

  // Update user performance data
  Future<void> updateUserPerformance(UserPerformanceModel userPerformance);

  // Calculate delivery accuracy by user ID
  Future<double> calculateDeliveryAccuracyByUserId(String userId);

  // Sync user performance data
  Future<void> syncUserPerformance(UserPerformanceModel userPerformance);

  // Delete user performance data
  Future<bool> deleteUserPerformance(String userId);

  // Get all user performance data
  Future<List<UserPerformanceModel>> getAllUserPerformance();
}

class UserPerformanceLocalDataSourceImpl implements UserPerformanceLocalDataSource {
  
  final ObjectBoxStore objectBoxStore;

  UserPerformanceLocalDataSourceImpl(this.objectBoxStore);

  // ---------------------------------------------------
  // 📦 Boxes
  // ---------------------------------------------------
  Box<UserPerformanceModel> get userPerformanceBox =>
      objectBoxStore.userPerformanceBox;

  Box<LocalUsersModel> get userBox =>
      objectBoxStore.userBox;

  UserPerformanceModel? _cachedUserPerformance;
  
  // ===================================================
  // 📌 GET USER PERFORMANCE (RELATION-BASED)
  // ===================================================
  @override
  Future<UserPerformanceModel> getUserPerformanceByUserId(
      String userId) async {
    try {
      debugPrint('📱 LOCAL: Fetching user performance for userId: $userId');

      // 1️⃣ Resolve user first
      final userQuery =
          userBox.query(LocalUsersModel_.id.equals(userId)).build();
      final user = userQuery.findFirst();
      userQuery.close();

      if (user == null) {
        throw const CacheException(message: 'User not found');
      }

      // 2️⃣ Query performance via relation
      final perfQuery = userPerformanceBox
          .query(UserPerformanceModel_.user.equals(user.objectBoxId))
          .build();

      final perf = perfQuery.findFirst();
      perfQuery.close();

      if (perf == null) {
        throw const CacheException(
            message: 'User performance not found');
      }

      final complete = await _loadCompleteUserPerformance(perf);
      _cachedUserPerformance = complete;

      return complete;
    } catch (e) {
      debugPrint('❌ LOCAL: getUserPerformance error → $e');
      throw CacheException(message: e.toString());
    }
  }

  // ===================================================
  // 💾 CACHE USER PERFORMANCE
  // ===================================================
  @override
  Future<void> cacheUserPerformance(
      UserPerformanceModel performance) async {
    try {
      if (performance.user.target == null) {
        throw const CacheException(
            message: 'User relation must be set');
      }

      userPerformanceBox.put(performance);
      _cachedUserPerformance = performance;

      debugPrint(
          '✅ LOCAL: Cached performance for user ${performance.user.target?.id}');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ===================================================
  // 🔄 UPDATE USER PERFORMANCE
  // ===================================================
  @override
  Future<void> updateUserPerformance(
      UserPerformanceModel performance) async {
    try {
      if (performance.objectBoxId <= 0) {
        throw const CacheException(
            message: 'Invalid ObjectBox ID');
      }

      userPerformanceBox.put(performance);
      _cachedUserPerformance = performance;

      debugPrint('✅ LOCAL: User performance updated');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ===================================================
  // 📊 CALCULATE DELIVERY ACCURACY
  // ===================================================
  @override
  Future<double> calculateDeliveryAccuracyByUserId(
      String userId) async {
    final perf = await getUserPerformanceByUserId(userId);

    final total = perf.totalDeliveries ?? 0;
    final success = perf.successfulDeliveries ?? 0;

    final accuracy =
        total > 0 ? (success / total) * 100 : 0.0;

    perf.deliveryAccuracy = accuracy;
    perf.updated = DateTime.now();

    await updateUserPerformance(perf);

    return accuracy;
  }

  // ===================================================
  // 🔁 SYNC USER PERFORMANCE (RELATION SAFE)
  // ===================================================
  @override
  Future<void> syncUserPerformance(
      UserPerformanceModel performance) async {
    try {
      final user = performance.user.target;
      if (user == null) {
        throw const CacheException(
            message: 'User relation missing');
      }

      await _cleanupUserPerformanceByUser(user);

      userPerformanceBox.put(performance);
      _cachedUserPerformance = performance;

      debugPrint('🔄 LOCAL: Synced performance for user ${user.id}');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ===================================================
  // 🗑️ DELETE USER PERFORMANCE
  // ===================================================
  @override
  Future<bool> deleteUserPerformance(String userId) async {
    try {
      final user =
          userBox.query(LocalUsersModel_.id.equals(userId)).build().findFirst();

      if (user == null) return false;

      final perfQuery = userPerformanceBox
          .query(UserPerformanceModel_.user.equals(user.objectBoxId))
          .build();

      final perf = perfQuery.findFirst();
      perfQuery.close();

      if (perf == null) return false;

      userPerformanceBox.remove(perf.objectBoxId);

      if (_cachedUserPerformance?.objectBoxId ==
          perf.objectBoxId) {
        _cachedUserPerformance = null;
      }

      return true;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ===================================================
  // 📋 GET ALL USER PERFORMANCE
  // ===================================================
  @override
  Future<List<UserPerformanceModel>> getAllUserPerformance() async {
    try {
      final all = userPerformanceBox.getAll();
      final output = <UserPerformanceModel>[];

      for (final perf in all) {
        if (perf.objectBoxId > 0) {
          output.add(await _loadCompleteUserPerformance(perf));
        }
      }

      return output;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ===================================================
  // 🔄 LOAD RELATIONS
  // ===================================================
  Future<UserPerformanceModel> _loadCompleteUserPerformance(
      UserPerformanceModel perf) async {
    if (perf.user.target == null &&
        perf.user.targetId > 0) {
      final user = userBox.get(perf.user.targetId);
      if (user != null) {
        perf.user.target = user;
      }
    }

    if (perf.objectBoxId > 0) {
      userPerformanceBox.put(perf);
    }

    return perf;
  }

  // ===================================================
  // 🧹 CLEANUP (RELATION-BASED)
  // ===================================================
  Future<void> _cleanupUserPerformanceByUser(
      LocalUsersModel user) async {
    final existing = userPerformanceBox
        .query(UserPerformanceModel_.user.equals(user.objectBoxId))
        .build()
        .find();

    if (existing.isNotEmpty) {
      userPerformanceBox.removeMany(
          existing.map((e) => e.objectBoxId).toList());
    }
  }
}
