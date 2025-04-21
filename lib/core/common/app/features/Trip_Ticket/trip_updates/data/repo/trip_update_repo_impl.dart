import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/datasources/local_datasource/trip_update_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/repo/trip_update_repo.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class TripUpdateRepoImpl extends TripUpdateRepo {
  TripUpdateRepoImpl(this._remoteDataSource, this._localDataSource);

  final TripUpdateRemoteDatasource _remoteDataSource;
  final TripUpdateLocalDatasource _localDataSource;

  @override
  ResultFuture<List<TripUpdateEntity>> getTripUpdates(String tripId) async {
    try {
      debugPrint('🔄 Fetching trip updates from remote source...');
      final remoteUpdates = await _remoteDataSource.getTripUpdates(tripId);
      
      debugPrint('📥 Starting sync for ${remoteUpdates.length} remote trip updates');
      await _localDataSource.cacheTripUpdates(remoteUpdates);
      
      return Right(remoteUpdates);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      
      try {
        final localUpdates = await _localDataSource.getTripUpdates(tripId);
        debugPrint('📦 Using ${localUpdates.length} updates from cache');
        return Right(localUpdates);
      } catch (cacheError) {
        debugPrint('❌ Cache Error: $cacheError');
      }
      
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
@override
ResultFuture<void> createTripUpdate({
  required String tripId,
  required String description,
  required String image,
  required String latitude,
  required String longitude,
  required TripUpdateStatus status,
}) async {
  try {
debugPrint('💾 Starting trip update creation process');
    debugPrint('📦 Local storage step initiated');    
    // Create in local storage first
    await _localDataSource.createTripUpdate(
      tripId: tripId,
      description: description,
      image: image,
      latitude: latitude,
      longitude: longitude,
      status: status,
    );
     debugPrint('✅ Successfully stored in local database');

    debugPrint('🌐 Syncing trip update to remote');
    
    // Then sync with remote
    await _remoteDataSource.createTripUpdate(
      tripId: tripId,
      description: description,
      image: image,
      latitude: latitude,
      longitude: longitude,
      status: status,
    );

    debugPrint('✅ Trip update created successfully');
    return const Right(null);
  } on CacheException catch (e) {
    debugPrint('❌ Local storage error: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote creation failed, but local creation succeeded');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

  
  @override
ResultFuture<List<TripUpdateEntity>> getLocalTripUpdates(String tripId) async {
  try {
    debugPrint('📦 Fetching trip updates from local storage...');
    final localUpdates = await _localDataSource.getTripUpdates(tripId);
    debugPrint('✅ Retrieved ${localUpdates.length} updates from local storage');
    return Right(localUpdates);
  } on CacheException catch (e) {
    debugPrint('❌ Local storage error: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

}
