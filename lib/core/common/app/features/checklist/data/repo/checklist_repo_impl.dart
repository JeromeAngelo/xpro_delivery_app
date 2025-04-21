import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/datasource/local_datasource/checklist_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/datasource/remote_datasource/checklist_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/entity/checklist_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/repo/checklist_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class ChecklistRepoImpl extends ChecklistRepo {
  final ChecklistDatasource _remoteDatasource;
  final ChecklistLocalDatasource _localDatasource;

  ChecklistRepoImpl(this._remoteDatasource, this._localDatasource);

@override
ResultFuture<bool> checkItem(String id) async {
  try {
    debugPrint('📱 Checking item locally first: $id');
    final localResult = await _localDatasource.checkItem(id);
    
    try {
      debugPrint('🌐 Syncing check status to remote');
      final remoteResult = await _remoteDatasource.checkItem(id);
      return Right(remoteResult);
    } on ServerException catch (_) {
      debugPrint('⚠️ Remote sync failed, but local check succeeded');
      return Right(localResult);
    }
  } on CacheException catch (e) {
    debugPrint('❌ Local check failed');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}


  @override
  ResultFuture<List<ChecklistEntity>> loadChecklist() async {
    try {
      final remoteChecklist = await _remoteDatasource.getChecklist();
      await _localDatasource.getChecklist();
      return Right(remoteChecklist);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
ResultFuture<List<ChecklistEntity>> loadChecklistByTripId(String? tripId) async {
  try {
    debugPrint('🌐 Loading checklist from remote for trip: $tripId');
    final remoteChecklist = await _remoteDatasource.loadChecklistByTripId(tripId!);
    await _localDatasource.cacheChecklist(remoteChecklist);
    return Right(remoteChecklist);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<List<ChecklistEntity>> loadLocalChecklistByTripId(String? tripId) async {
  try {
    debugPrint('📱 Loading checklist from local storage for trip: $tripId');
    final localChecklist = await _localDatasource.loadChecklistByTripId(tripId!);
    return Right(localChecklist);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

  
  
}
