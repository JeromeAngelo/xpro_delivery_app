import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/data/datasources/local_datasource/user_performance_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/data/datasources/remote_datasource/user_performance_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/domain/entity/user_performance_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/domain/repo/user_performance_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../model/user_performance_model.dart';

class UserPerformanceRepoImpl implements UserPerformanceRepo {
  const UserPerformanceRepoImpl(this._remoteDataSource, this._localDataSource);

  final UserPerformanceRemoteDatasource _remoteDataSource;
  final UserPerformanceLocalDataSource _localDataSource;

  @override
  ResultFuture<UserPerformanceEntity> loadUserPerformanceByUserId(String userId) async {
    try {
      debugPrint('🌐 Fetching user performance from remote for user: $userId');
      final remoteUserPerformance = await _remoteDataSource.loadUserPerformanceByUserId(userId);
      debugPrint('✅ Retrieved user performance from remote');
      
      // Cache the data locally
      await _localDataSource.cacheUserPerformance(remoteUserPerformance);
      debugPrint('💾 Cached user performance to local storage');
      
      return Right(remoteUserPerformance);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      
      // Try to get data from local cache if remote fails
      try {
        debugPrint('🔍 Attempting to retrieve user performance from local cache');
        final localUserPerformance = await _localDataSource.getUserPerformanceByUserId(userId);
        debugPrint('📱 Retrieved user performance from local cache');
        return Right(localUserPerformance);
      } on CacheException catch (cacheError) {
        debugPrint('⚠️ Cache Error: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 404));
      }
      
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<UserPerformanceEntity> loadLocalUserPerformanceByUserId(String userId) async {
    try {
      debugPrint('📱 Fetching user performance from local storage for user: $userId');
      final localUserPerformance = await _localDataSource.getUserPerformanceByUserId(userId);
      debugPrint('✅ Retrieved user performance from local storage');
      return Right(localUserPerformance);
    } on CacheException catch (e) {
      debugPrint('⚠️ Cache Error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 404));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: 404));
    }
  }

  @override
  ResultFuture<double> calculateDeliveryAccuracy(String userId) async {
    try {
      debugPrint('🧮 Calculating delivery accuracy for user: $userId');
      
      // Try remote calculation first for most up-to-date data
      final remoteAccuracy = await _remoteDataSource.calculateDeliveryAccuracy(userId);
      debugPrint('✅ Remote calculation successful: ${remoteAccuracy.toStringAsFixed(2)}%');
      
      return Right(remoteAccuracy);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote calculation failed: ${e.message}');
      
      // Fallback to local calculation
      try {
        debugPrint('🔍 Attempting local delivery accuracy calculation');
        final localAccuracy = await _localDataSource.calculateDeliveryAccuracyByUserId(userId);
        debugPrint('📱 Local calculation successful: ${localAccuracy.toStringAsFixed(2)}%');
        return Right(localAccuracy);
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local calculation failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 404));
      }
    } catch (e) {
      debugPrint('❌ Unexpected error during delivery accuracy calculation: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  // Additional helper methods for comprehensive user performance management

  /// Sync user performance data from remote to local
  ResultFuture<UserPerformanceEntity> syncUserPerformance(String userId) async {
    try {
      debugPrint('🔄 Starting user performance sync for user: $userId');
      
      // Fetch user performance from remote
      final remoteUserPerformance = await _remoteDataSource.loadUserPerformanceByUserId(userId);
      debugPrint('✅ Retrieved user performance from remote');
      
      // Store synced data locally
      await _localDataSource.syncUserPerformance(remoteUserPerformance);
      debugPrint('💾 Successfully synced user performance to local storage');
      
      debugPrint('✅ User performance sync completed for user: $userId');
      debugPrint('📊 Sync Summary:');
      debugPrint('   🌐 Remote data: Retrieved');
      debugPrint('   💾 Local storage: Updated');
      debugPrint('   👤 User ID: $userId');
      debugPrint('   📈 Total Deliveries: ${remoteUserPerformance.totalDeliveries}');
      debugPrint('   🎯 Accuracy: ${remoteUserPerformance.deliveryAccuracy}%');
      
      return Right(remoteUserPerformance);
      
    } on ServerException catch (e) {
      debugPrint('❌ Remote sync failed for user $userId: ${e.message}');
      
      // Try to return local data if remote sync fails
      try {
        debugPrint('🔍 Attempting to retrieve local user performance for user: $userId');
        final localUserPerformance = await _localDataSource.getUserPerformanceByUserId(userId);
        debugPrint('📱 Retrieved user performance from local cache');
        
        debugPrint('✅ Using cached user performance for user: $userId');
        return Right(localUserPerformance);
        
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local cache retrieval failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 404));
      }
      
    } on CacheException catch (e) {
      debugPrint('❌ Local sync failed for user $userId: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 500));
      
    } catch (e) {
      debugPrint('❌ Unexpected error during user performance sync: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  /// Update user performance data
  ResultFuture<UserPerformanceEntity> updateUserPerformance(UserPerformanceEntity userPerformance) async {
    try {
      debugPrint('🔄 Updating user performance: ${userPerformance.id}');
      
      // Update local storage first
      await _localDataSource.updateUserPerformance(userPerformance as UserPerformanceModel);
      debugPrint('💾 Updated user performance in local storage');
      
      return Right(userPerformance);
    } on CacheException catch (e) {
      debugPrint('❌ Failed to update user performance: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 500));
    } catch (e) {
      debugPrint('❌ Unexpected error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  /// Delete user performance data
  ResultFuture<bool> deleteUserPerformance(String userId) async {
    try {
      debugPrint('🔄 Deleting user performance for user: $userId');
      
      final result = await _localDataSource.deleteUserPerformance(userId);
      debugPrint('✅ Successfully deleted user performance from local storage');
      
      return Right(result);
    } on CacheException catch (e) {
      debugPrint('❌ Failed to delete user performance: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 404));
    } catch (e) {
      debugPrint('❌ Unexpected error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  /// Get all user performance data
  ResultFuture<List<UserPerformanceEntity>> getAllUserPerformance() async {
    try {
      debugPrint('📱 Fetching all user performance data from local storage');
      final allUserPerformance = await _localDataSource.getAllUserPerformance();
      debugPrint('✅ Retrieved ${allUserPerformance.length} user performance records from local storage');
      return Right(allUserPerformance);
    } on CacheException catch (e) {
      debugPrint('⚠️ Cache Error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 404));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: 404));
    }
  }

  /// Recalculate and update delivery accuracy for a user
  ResultFuture<double> recalculateAndUpdateAccuracy(String userId) async {
    try {
      debugPrint('🔄 Recalculating and updating delivery accuracy for user: $userId');
      
      // Calculate accuracy using remote data source
      final accuracy = await _remoteDataSource.calculateDeliveryAccuracy(userId);
      debugPrint('✅ Recalculated accuracy: ${accuracy.toStringAsFixed(2)}%');
      
      // Also update local calculation
      try {
        await _localDataSource.calculateDeliveryAccuracyByUserId(userId);
        debugPrint('💾 Updated local accuracy calculation');
      } catch (localError) {
        debugPrint('⚠️ Failed to update local accuracy: $localError');
        // Continue even if local update fails
      }
      
      return Right(accuracy);
    } on ServerException catch (e) {
      debugPrint('❌ Failed to recalculate accuracy: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
}
