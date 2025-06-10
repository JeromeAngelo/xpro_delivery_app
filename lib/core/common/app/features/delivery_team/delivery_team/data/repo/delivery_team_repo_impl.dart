import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/local_datasource/delivery_team_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/remote_datasource/delivery_team_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/repo/delivery_team_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class DeliveryTeamRepoImpl implements DeliveryTeamRepo {
  final DeliveryTeamDatasource _remoteDatasource;
  final DeliveryTeamLocalDatasource _localDatasource;

  const DeliveryTeamRepoImpl(this._remoteDatasource, this._localDatasource);

  @override
  ResultFuture<DeliveryTeamEntity> loadDeliveryTeam(String tripId) async {
    try {
      debugPrint('🌐 Fetching delivery team from remote for trip: $tripId');
      final remoteTeam = await _remoteDatasource.loadDeliveryTeam(tripId);
      await _localDatasource.cacheDeliveryTeam(remoteTeam);
      debugPrint('💾 Cached delivery team locally');
      return Right(remoteTeam);
    } on ServerException catch (_) {
      debugPrint('⚠️ Remote fetch failed, attempting local fallback');
      try {
        final localTeam = await _localDatasource.loadDeliveryTeam(tripId);
        debugPrint('📱 Successfully loaded from local storage');
        return Right(localTeam);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

// delivery_team_repo_impl.dart
@override
ResultFuture<DeliveryTeamEntity> loadLocalDeliveryTeam(String tripId) async {
  try {
    debugPrint('📱 Loading delivery team from local storage');
    
    try {
      final localTeam = await _localDatasource.loadDeliveryTeam(tripId);
      debugPrint('✅ Found delivery team in local storage');
      return Right(localTeam);
    } on CacheException {
      debugPrint('📡 No local data found, fetching from remote');
      final remoteTeam = await _remoteDatasource.loadDeliveryTeam(tripId);
      await _localDatasource.cacheDeliveryTeam(remoteTeam);
      debugPrint('💾 Remote data cached locally');
      return Right(remoteTeam);
    }
  } catch (e) {
    debugPrint('❌ Error loading delivery team: ${e.toString()}');
    return Left(ServerFailure(
      message: 'Failed to load delivery team: $e',
      statusCode: '500',
    ));
  }
}



@override
ResultFuture<DeliveryTeamEntity> loadDeliveryTeamById(String deliveryTeamId) async {
  try {
    debugPrint('📱 Loading delivery team by ID from local storage');
    
    try {
      final localTeam = await _localDatasource.loadDeliveryTeamById(deliveryTeamId);
      debugPrint('✅ Found delivery team in local storage');
      return Right(localTeam);
    } on CacheException {
      debugPrint('📡 No local data found, fetching from remote');
      final remoteTeam = await _remoteDatasource.loadDeliveryTeamById(deliveryTeamId);
      await _localDatasource.cacheDeliveryTeam(remoteTeam);
      debugPrint('💾 Remote data cached locally');
      return Right(remoteTeam);
    }
  } catch (e) {
    return Left(CacheFailure(message: e.toString(), statusCode: 500));
  }
}

  
 @override
ResultFuture<DeliveryTeamEntity> loadLocalDeliveryTeamById(String deliveryTeamId) async {
  try {
    debugPrint('📱 Loading delivery team by ID from local storage');
    final localTeam = await _localDatasource.loadDeliveryTeamById(deliveryTeamId);
    debugPrint('✅ Found delivery team in local storage');
    
    try {
      debugPrint('🌐 Updating with remote data');
      final remoteTeam = await _remoteDatasource.loadDeliveryTeamById(deliveryTeamId);
      await _localDatasource.updateDeliveryTeam(remoteTeam);
      return Right(remoteTeam);
    } on ServerException {
      debugPrint('📦 Using cached delivery team data');
      return Right(localTeam);
    }
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<DeliveryTeamEntity> assignDeliveryTeamToTrip({
  required String tripId,
  required String deliveryTeamId,
}) async {
  try {
    debugPrint('🔄 Starting delivery team assignment process');
    
    // Local assignment first
    final localDeliveryTeam = await _localDatasource.assignDeliveryTeamToTrip(
      tripId: tripId,
      deliveryTeamId: deliveryTeamId,
    );
    
    // Then sync with remote and verify local data
    final remoteDeliveryTeam = await _remoteDatasource.assignDeliveryTeamToTrip(
      tripId: tripId,
      deliveryTeamId: deliveryTeamId,
    );
    
    // Verify local and remote data match
    if (localDeliveryTeam.id != remoteDeliveryTeam.id) {
      debugPrint('⚠️ Local and remote IDs mismatch, updating local data');
      await _localDatasource.assignDeliveryTeamToTrip(
        tripId: tripId,
        deliveryTeamId: remoteDeliveryTeam.id!,
      );
    }
    
    debugPrint('✅ Delivery team assignment completed successfully');
    return Right(remoteDeliveryTeam);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}



}
