import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/datasource/local_datasource/return_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/datasource/remote_datasource/return_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/repo/return_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class ReturnRepoImpl extends ReturnRepo {
  const ReturnRepoImpl(this._remoteDataSource, this._localDataSource);

  final ReturnRemoteDatasource _remoteDataSource;
  final ReturnLocalDatasource _localDataSource;

 @override
ResultFuture<List<ReturnEntity>> getReturns(String tripId) async {
  try {
    debugPrint('🔄 Fetching returns from remote source...');
    final remoteReturns = await _remoteDataSource.getReturns(tripId);
    
    debugPrint('📥 Starting sync for ${remoteReturns.length} remote returns');
    
    for (var returnItem in remoteReturns) {
      debugPrint('💾 Syncing return: ${returnItem.productName}');
      await _localDataSource.updateReturn(returnItem);
    }
    
    return Right(remoteReturns);
    
  } on ServerException catch (e) {
    debugPrint('⚠️ API Error: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<List<ReturnEntity>> loadLocalReturns(String tripId) async {
  try {
    debugPrint('📱 Loading returns from local storage');
    
    try {
      final localReturns = await _localDataSource.getReturns(tripId);
      debugPrint('✅ Found ${localReturns.length} returns in local storage');
      return Right(localReturns);
    } on CacheException {
      debugPrint('📡 No local data found, fetching from remote');
      final remoteReturns = await _remoteDataSource.getReturns(tripId);
      
      for (var returnItem in remoteReturns) {
        await _localDataSource.updateReturn(returnItem);
      }
      debugPrint('💾 Remote data cached locally');
      return Right(remoteReturns);
    }
  } catch (e) {
    return Left(CacheFailure(message: e.toString(), statusCode: 404));
  }
}

  
 @override
Future<Either<Failure, ReturnEntity>> getReturnByCustomerId(String customerId) async {
  try {
    final returnItem = await _remoteDataSource.getReturnByCustomerId(customerId);
    await _localDataSource.updateReturn(returnItem);
    return Right(returnItem);
  } on ServerException {
    debugPrint('⚠️ Remote fetch failed, attempting local cache retrieval');
    try {
      final localReturn = await _localDataSource.getReturnByCustomerId(customerId);
      return Right(localReturn);
    } on CacheException catch (e) {
      debugPrint('❌ Local cache retrieval failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

}
