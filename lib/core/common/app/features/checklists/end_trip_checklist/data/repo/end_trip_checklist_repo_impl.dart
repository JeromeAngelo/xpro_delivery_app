import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/remote_datasource/end_trip_checklist_remote_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/domain/entity/end_checklist_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/domain/repo/end_trip_checklist_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class EndTripChecklistRepoImpl extends EndTripChecklistRepo {
  EndTripChecklistRepoImpl(this._remoteDataSource, this._localDataSource);

  final EndTripChecklistRemoteDataSource _remoteDataSource;
  final EndTripChecklistLocalDataSource _localDataSource;

@override
ResultFuture<List<EndChecklistEntity>> generateEndTripChecklist(String tripId) async {
  try {
    debugPrint('📝 Generating checklist locally for trip: $tripId');
    
    // Generate and save locally first
    final localChecklist = await _remoteDataSource.generateEndTripChecklist(tripId);
    await _localDataSource.cacheChecklists(localChecklist);
    
    // Then sync with remote
    debugPrint('🌐 Syncing checklist to remote');
    final remoteChecklist = await _remoteDataSource.generateEndTripChecklist(tripId);
    
    return Right(remoteChecklist);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote generation failed, using local data');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

 @override
ResultFuture<bool> checkEndTripChecklistItem(String id) async {
  try {
    debugPrint('✓ Checking item in local storage first');
    
    // Check locally first
    final localResult = await _localDataSource.checkEndTripChecklistItem(id);
    
    // Then sync with remote
    debugPrint('🌐 Syncing check status to remote');
    await _remoteDataSource.checkEndTripChecklistItem(id);
    
    return Right(localResult);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote sync failed, local update maintained');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

  @override
  ResultFuture<List<EndChecklistEntity>> loadEndTripChecklist(String tripId) async {
    try {
      debugPrint('🌐 Fetching checklist from remote source for trip: $tripId');
      final remoteChecklist = await _remoteDataSource.loadEndTripChecklist(tripId);
      await _localDataSource.cacheChecklists(remoteChecklist);
      debugPrint('💾 Remote data synced locally');
      return Right(remoteChecklist);
    } on ServerException catch (_) {
      debugPrint('⚠️ Remote fetch failed, attempting local fallback');
      try {
        final localChecklist = await _localDataSource.loadEndTripChecklist(tripId);
        debugPrint('📱 Successfully loaded from local storage');
        return Right(localChecklist);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

  @override
  ResultFuture<List<EndChecklistEntity>> loadLocalEndTripChecklist(String tripId) async {
    try {
      debugPrint('📱 Loading checklist from local storage for trip: $tripId');
      final localChecklist = await _localDataSource.loadEndTripChecklist(tripId);
      debugPrint('✅ Successfully loaded from local storage');
      return Right(localChecklist);
    } on CacheException catch (e) {
      debugPrint('❌ Local storage fetch failed');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
