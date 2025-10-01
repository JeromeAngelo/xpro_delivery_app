import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/data/model/user_performance_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

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
  final Box<UserPerformanceModel> _userPerformanceBox;
  final Store _store;
  UserPerformanceModel? _cachedUserPerformance;

  UserPerformanceLocalDataSourceImpl(this._userPerformanceBox, this._store);

  @override
  Future<UserPerformanceModel> getUserPerformanceByUserId(String userId) async {
    try {
      debugPrint('📱 LOCAL: Fetching user performance for user ID: $userId');

      final userPerformance = _userPerformanceBox
          .query(UserPerformanceModel_.userId.equals(userId))
          .build()
          .findFirst();

      if (userPerformance != null) {
        debugPrint('✅ LOCAL: Found user performance in local storage');
        
        // Load complete user performance data with relations
        final completeUserPerformance = await _loadCompleteUserPerformance(userPerformance);
        
        debugPrint('📊 LOCAL: Performance Stats:');
        debugPrint('   📦 ID: ${completeUserPerformance.id}');
        debugPrint('   👤 User: ${completeUserPerformance.user.target?.name ?? "null"}');
        debugPrint('   📈 Total Deliveries: ${completeUserPerformance.totalDeliveries ?? "null"}');
        debugPrint('   ✅ Successful: ${completeUserPerformance.successfulDeliveries ?? "null"}');
        debugPrint('   ❌ Cancelled: ${completeUserPerformance.cancelledDeliveries ?? "null"}');
        debugPrint('   🎯 Accuracy: ${completeUserPerformance.deliveryAccuracy ?? "null"}%');
        
        return completeUserPerformance;
      }

      throw const CacheException(
        message: 'User performance not found in local storage',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheUserPerformance(UserPerformanceModel userPerformance) async {
    try {
      debugPrint('💾 LOCAL: Starting user performance caching process...');
      debugPrint('📥 LOCAL: Caching performance for user: ${userPerformance.userId}');

      // Ensure userId is set if user is assigned
      if (userPerformance.user.target != null) {
        userPerformance.userId = userPerformance.user.target?.id;
      }

      _userPerformanceBox.put(userPerformance);
      _cachedUserPerformance = userPerformance;

      debugPrint('✅ LOCAL: User performance cached successfully');
      debugPrint('📊 LOCAL: Cache Stats:');
      debugPrint('   📦 Performance ID: ${userPerformance.id}');
      debugPrint('   👤 User ID: ${userPerformance.userId}');
      debugPrint('   📈 Total Deliveries: ${userPerformance.totalDeliveries}');
      debugPrint('   🎯 Accuracy: ${userPerformance.deliveryAccuracy}%');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateUserPerformance(UserPerformanceModel userPerformance) async {
    try {
      debugPrint('📱 LOCAL: Updating user performance: ${userPerformance.id}');

      // Ensure userId is set if user is assigned
      if (userPerformance.user.target != null) {
        userPerformance.userId = userPerformance.user.target?.id;
      }

      _userPerformanceBox.put(userPerformance);
      _cachedUserPerformance = userPerformance;
      
      debugPrint('✅ LOCAL: User performance updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<double> calculateDeliveryAccuracyByUserId(String userId) async {
    try {
      debugPrint('📱 LOCAL: Calculating delivery accuracy for user: $userId');

      final userPerformance = await getUserPerformanceByUserId(userId);

      final totalDeliveries = userPerformance.totalDeliveries ?? 0.0;
      final successfulDeliveries = userPerformance.successfulDeliveries ?? 0.0;

      debugPrint('📊 LOCAL: Calculation data - Total: $totalDeliveries, Successful: $successfulDeliveries');

      // Calculate accuracy: (successfulDeliveries / totalDeliveries) * 100
      double accuracy = 0.0;
      if (totalDeliveries > 0) {
        accuracy = (successfulDeliveries / totalDeliveries) * 100;
      }

      debugPrint('✅ LOCAL: Calculated delivery accuracy: ${accuracy.toStringAsFixed(2)}%');

      // Update the accuracy in local storage
      final updatedPerformance = userPerformance.copyWith(
        deliveryAccuracy: accuracy,
        updated: DateTime.now(),
      );
      
      await updateUserPerformance(updatedPerformance);
      debugPrint('📝 LOCAL: Updated accuracy in local storage');

      return accuracy;
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to calculate delivery accuracy: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> syncUserPerformance(UserPerformanceModel userPerformance) async {
    try {
      debugPrint('💾 LOCAL: Starting user performance sync...');
      debugPrint('📥 LOCAL: Syncing performance for user: ${userPerformance.userId}');

      // Clear existing performance data for this user
      await _cleanupUserPerformanceByUserId(userPerformance.userId!);

      // Store synced performance data
      _userPerformanceBox.put(userPerformance);

      debugPrint('✅ LOCAL: Sync verification: User performance stored for user: ${userPerformance.userId}');
      debugPrint('📊 LOCAL: Sync Stats:');
      debugPrint('   📦 Performance ID: ${userPerformance.id}');
      debugPrint('   👤 User ID: ${userPerformance.userId}');
      debugPrint('   📈 Total Deliveries: ${userPerformance.totalDeliveries}');
      debugPrint('   🎯 Accuracy: ${userPerformance.deliveryAccuracy}%');

      // Update cached data
      _cachedUserPerformance = userPerformance;
      debugPrint('🔄 LOCAL: Cache memory updated with synced data');
    } catch (e) {
      debugPrint('❌ LOCAL: Sync failed for user ${userPerformance.userId}: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteUserPerformance(String userId) async {
    try {
      debugPrint('📱 LOCAL: Deleting user performance for user: $userId');

      final userPerformance = _userPerformanceBox
          .query(UserPerformanceModel_.userId.equals(userId))
          .build()
          .findFirst();

      if (userPerformance == null) {
        throw const CacheException(
          message: 'User performance not found in local storage',
        );
      }

      _userPerformanceBox.remove(userPerformance.objectBoxId);
      
      // Clear cached data if it matches
      if (_cachedUserPerformance?.userId == userId) {
        _cachedUserPerformance = null;
      }
      
      debugPrint('✅ LOCAL: Successfully deleted user performance');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<UserPerformanceModel>> getAllUserPerformance() async {
    try {
      debugPrint('📱 LOCAL: Fetching all user performance data');

      final allPerformance = _userPerformanceBox.getAll();

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total stored user performance: ${_userPerformanceBox.count()}');
      debugPrint('Found user performance records: ${allPerformance.length}');

      // Process each performance record to ensure all relationships are loaded
      final processedPerformance = <UserPerformanceModel>[];
      
      for (var performance in allPerformance) {
        if (performance.id == null || performance.id!.isEmpty) {
          debugPrint('⚠️ Skipping performance with null/empty ID');
          continue;
        }
        
        final processedData = await _loadCompleteUserPerformance(performance);
        processedPerformance.add(processedData);
      }

      return processedPerformance;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<UserPerformanceModel> _loadCompleteUserPerformance(UserPerformanceModel userPerformance) async {
    try {
      debugPrint('🔄 Loading complete user performance for: ${userPerformance.id}');
      
      // Load user data if not already loaded
      if (userPerformance.user.target == null && userPerformance.user.targetId > 0) {
        final userBox = _store.box<LocalUsersModel>();
        final user = userBox.get(userPerformance.user.targetId);
        if (user != null) {
          userPerformance.user.target = user;
          debugPrint('✅ Loaded user: ${user.name}');
        } else {
          debugPrint('⚠️ User not found in local storage: ${userPerformance.user.targetId}');
        }
      } else if (userPerformance.user.targetId <= 0) {
        debugPrint('⚠️ Invalid user targetId: ${userPerformance.user.targetId}');
      }
      
      // Save the updated user performance only if it has a valid objectBoxId
      if (userPerformance.objectBoxId > 0) {
        _userPerformanceBox.put(userPerformance);
        debugPrint('✅ Updated user performance saved to ObjectBox');
      } else {
        debugPrint('⚠️ Cannot save user performance with invalid objectBoxId: ${userPerformance.objectBoxId}');
      }
      
      debugPrint('✅ Complete user performance loaded for: ${userPerformance.id}');
      return userPerformance;
      
    } catch (e) {
      debugPrint('❌ Failed to load complete user performance: $e');
      debugPrint('   - Performance ID: ${userPerformance.id}');
      debugPrint('   - ObjectBox ID: ${userPerformance.objectBoxId}');
      debugPrint('   - User targetId: ${userPerformance.user.targetId}');
      
      // Return original data if loading fails to prevent crashes
      return userPerformance;
    }
  }

  Future<void> _cleanupUserPerformanceByUserId(String userId) async {
    try {
      debugPrint('🧹 LOCAL: Cleaning up existing user performance for user: $userId');
      
      final existingData = _userPerformanceBox
          .query(UserPerformanceModel_.userId.equals(userId))
          .build()
          .find();

      if (existingData.isNotEmpty) {
        final idsToRemove = existingData.map((data) => data.objectBoxId).toList();
        _userPerformanceBox.removeMany(idsToRemove);
        debugPrint('🗑️ LOCAL: Removed ${existingData.length} existing user performance records for user: $userId');
      } else {
        debugPrint('ℹ️ LOCAL: No existing user performance found for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed for user $userId: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
