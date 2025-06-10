import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';


class DeliveryDataRepoImpl implements DeliveryDataRepo {
  const DeliveryDataRepoImpl(this._remoteDataSource, this._localDataSource);

  final DeliveryDataRemoteDataSource _remoteDataSource;
  final DeliveryDataLocalDataSource _localDataSource;

  @override
  ResultFuture<List<DeliveryDataEntity>> getAllDeliveryData() async {
    try {
      debugPrint('🌐 Fetching all delivery data from remote');
      final remoteDeliveryData = await _remoteDataSource.getAllDeliveryData();
      debugPrint('✅ Retrieved ${remoteDeliveryData.length} delivery data records');
      
      // Cache the data locally
      await _localDataSource.cacheDeliveryData(remoteDeliveryData);
      debugPrint('💾 Cached delivery data to local storage');
      
      return Right(remoteDeliveryData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      
      // Try to get data from local cache if remote fails
      try {
        debugPrint('🔍 Attempting to retrieve data from local cache');
        final localDeliveryData = await _localDataSource.getAllDeliveryData();
        debugPrint('📱 Retrieved ${localDeliveryData.length} delivery data records from local cache');
        return Right(localDeliveryData);
      } on CacheException catch (cacheError) {
        debugPrint('⚠️ Cache Error: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 400));
      }
      
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<DeliveryDataEntity>> getDeliveryDataByTripId(String tripId) async {
    try {
      debugPrint('🌐 Fetching delivery data for trip ID: $tripId from remote');
      final remoteDeliveryData = await _remoteDataSource.getDeliveryDataByTripId(tripId);
      debugPrint('✅ Retrieved ${remoteDeliveryData.length} delivery data records for trip ID: $tripId');
      
      // Cache the data locally
      await _localDataSource.cacheDeliveryData(remoteDeliveryData);
      debugPrint('💾 Cached trip-specific delivery data to local storage');
      
      return Right(remoteDeliveryData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      
      // Try to get data from local cache if remote fails
      try {
        debugPrint('🔍 Attempting to retrieve trip data from local cache');
        final localDeliveryData = await _localDataSource.getDeliveryDataByTripId(tripId);
        debugPrint('📱 Retrieved ${localDeliveryData.length} delivery data records for trip ID: $tripId from local cache');
        return Right(localDeliveryData);
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
  ResultFuture<DeliveryDataEntity> getDeliveryDataById(String id) async {
    try {
      debugPrint('🌐 Fetching delivery data with ID: $id from remote');
      final remoteDeliveryData = await _remoteDataSource.getDeliveryDataById(id);
      debugPrint('✅ Retrieved delivery data with ID: $id');
      
      // Cache the data locally
      await _localDataSource.updateDeliveryData(remoteDeliveryData);
      debugPrint('💾 Updated specific delivery data in local storage');
      
      return Right(remoteDeliveryData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      
      // Try to get data from local cache if remote fails
      try {
        debugPrint('🔍 Attempting to retrieve delivery data from local cache');
        final localDeliveryData = await _localDataSource.getDeliveryDataById(id);
        debugPrint('📱 Retrieved delivery data with ID: $id from local cache');
        return Right(localDeliveryData);
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
  ResultFuture<bool> deleteDeliveryData(String id) async {
    try {
      debugPrint('🌐 Deleting delivery data with ID: $id from remote');
      final result = await _remoteDataSource.deleteDeliveryData(id);
      debugPrint('✅ Successfully deleted delivery data with ID: $id');
      
      // Also delete from local storage
      try {
        await _localDataSource.deleteDeliveryData(id);
        debugPrint('💾 Deleted delivery data from local storage');
      } catch (cacheError) {
        debugPrint('⚠️ Failed to delete from local cache: $cacheError');
        // Continue even if local deletion fails
      }
      
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
  
  @override
  ResultFuture<DeliveryDataEntity> getLocalDeliveryDataById(String id) async {
    try {
      debugPrint('📱 Fetching delivery data with ID: $id from local storage');
      final localDeliveryData = await _localDataSource.getDeliveryDataById(id);
      debugPrint('✅ Retrieved delivery data with ID: $id from local storage');
      return Right(localDeliveryData);
    } on CacheException catch (e) {
      debugPrint('⚠️ Cache Error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 404));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: 404));
    }
  }
  
  @override
  ResultFuture<List<DeliveryDataEntity>> getLocalDeliveryDataByTripId(String tripId) async {
    try {
      debugPrint('📱 Fetching delivery data for trip ID: $tripId from local storage');
      final localDeliveryData = await _localDataSource.getDeliveryDataByTripId(tripId);
      debugPrint('✅ Retrieved ${localDeliveryData.length} delivery data records for trip ID: $tripId from local storage');
      return Right(localDeliveryData);
    } on CacheException catch (e) {
      debugPrint('⚠️ Cache Error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 404));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: 404));
    }
  }
  
    @override
  ResultFuture<int> calculateDeliveryTimeByDeliveryId(String deliveryId) async {
    try {
      debugPrint('⏱️ Calculating delivery time for delivery ID: $deliveryId');
      
      // Try remote first for most up-to-date data
      final remoteTime = await _remoteDataSource.calculateDeliveryTimeByDeliveryId(deliveryId);
      debugPrint('✅ Remote calculation successful: $remoteTime minutes');
      
      return Right(remoteTime);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote calculation failed: ${e.message}');
      
      // Fallback to local calculation
      try {
        debugPrint('🔍 Attempting local delivery time calculation');
        final localTime = await _localDataSource.calculateDeliveryTimeByDeliveryId(deliveryId);
        debugPrint('📱 Local calculation successful: $localTime minutes');
        return Right(localTime);
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local calculation failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 404));
      }
    } catch (e) {
      debugPrint('❌ Unexpected error during delivery time calculation: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
  
  @override
  ResultFuture<List<DeliveryDataEntity>> syncDeliveryDataByTripId(String tripId) async {
    try {
      debugPrint('🔄 Starting delivery data sync for trip: $tripId');
      
      // Fetch delivery data from remote
      final remoteDeliveryData = await _remoteDataSource.syncDeliveryDataByTripId(tripId);
      debugPrint('✅ Retrieved ${remoteDeliveryData.length} delivery data records from remote');
      
      // Store synced data locally
      await _localDataSource.syncDeliveryDataByTripId(tripId, remoteDeliveryData);
      debugPrint('💾 Successfully synced delivery data to local storage');
      
      debugPrint('✅ Delivery data sync completed for trip: $tripId');
      debugPrint('📊 Sync Summary:');
      debugPrint('   🌐 Remote records: ${remoteDeliveryData.length}');
      debugPrint('   💾 Local storage: Updated');
      debugPrint('   🎫 Trip ID: $tripId');
      
      return Right(remoteDeliveryData);
      
    } on ServerException catch (e) {
      debugPrint('❌ Remote sync failed for trip $tripId: ${e.message}');
      
      // Try to return local data if remote sync fails
      try {
        debugPrint('🔍 Attempting to retrieve local delivery data for trip: $tripId');
        final localDeliveryData = await _localDataSource.getDeliveryDataByTripId(tripId);
        debugPrint('📱 Retrieved ${localDeliveryData.length} delivery data records from local cache');
        
        if (localDeliveryData.isNotEmpty) {
          debugPrint('✅ Using cached delivery data for trip: $tripId');
          return Right(localDeliveryData);
        } else {
          debugPrint('⚠️ No cached delivery data found for trip: $tripId');
          return Left(CacheFailure(message: 'No delivery data available for sync', statusCode: 404));
        }
        
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local cache retrieval failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 404));
      }
      
    } on CacheException catch (e) {
      debugPrint('❌ Local sync failed for trip $tripId: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 500));
      
    } catch (e) {
      debugPrint('❌ Unexpected error during delivery data sync: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
  
 @override
ResultFuture<DeliveryDataEntity> setInvoiceIntoUnloading(String deliveryDataId) async {
  try {
    debugPrint('🔄 Setting invoice to unloading for delivery data: $deliveryDataId');
    
    final result = await _remoteDataSource.setInvoiceIntoUnloading(deliveryDataId);
    debugPrint('✅ Successfully set invoice to unloading');
    
    // Update local cache
    try {
      await _localDataSource.updateDeliveryData(result);
      debugPrint('💾 Updated delivery data in local storage');
    } catch (cacheError) {
      debugPrint('⚠️ Failed to update local cache: $cacheError');
      // Continue even if local update fails
    }
    
    return Right(result);
  } on ServerException catch (e) {
    debugPrint('❌ Failed to set invoice to unloading: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    debugPrint('❌ Unexpected error: ${e.toString()}');
    return Left(ServerFailure(message: e.toString(), statusCode: '500'));
  }
}

  @override
  ResultFuture<DeliveryDataEntity> setInvoiceIntoUnloaded(String deliveryDataId) async {
     try {
    debugPrint('🔄 Setting invoice to unloading for delivery data: $deliveryDataId');
    
    final result = await _remoteDataSource.setInvoiceIntoUnloaded(deliveryDataId);
    debugPrint('✅ Successfully set invoice to unloaded');
    
    // Update local cache
    try {
      await _localDataSource.updateDeliveryData(result);
      debugPrint('💾 Updated delivery data in local storage');
    } catch (cacheError) {
      debugPrint('⚠️ Failed to update local cache: $cacheError');
      // Continue even if local update fails
    }
    
    return Right(result);
  } on ServerException catch (e) {
    debugPrint('❌ Failed to set invoice to unloading: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    debugPrint('❌ Unexpected error: ${e.toString()}');
    return Left(ServerFailure(message: e.toString(), statusCode: '500'));
  }
  }



}
