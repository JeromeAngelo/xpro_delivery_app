import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/datasource/remote_datasource/delivery_update_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/datasource/local_datasource/delivery_update_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class DeliveryUpdateRepoImpl extends DeliveryUpdateRepo {
  const DeliveryUpdateRepoImpl(this._remoteDataSource, this._localDataSource);

  final DeliveryUpdateDatasource _remoteDataSource;
  final DeliveryUpdateLocalDatasource _localDataSource;

 @override
ResultFuture<List<DeliveryUpdateEntity>> getDeliveryStatusChoices(String customerId) async {
  try {
    debugPrint('🌐 Fetching delivery status choices from remote');
    final remoteUpdates = await _remoteDataSource.getDeliveryStatusChoices(customerId);
    
    // Cache valid updates locally
    for (var update in remoteUpdates) {
      if (update.id != null && update.id!.isNotEmpty) {
        await _localDataSource.updateDeliveryStatus(customerId, update.id!);
      }
    }
    
    return Right(remoteUpdates);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

  @override
  ResultFuture<void> updateDeliveryStatus(String customerId, String statusId) async {
    try {
      // Update local first
      debugPrint('💾 Updating local delivery status');
      await _localDataSource.updateDeliveryStatus(customerId, statusId);

      // Then sync with remote
      debugPrint('🌐 Syncing status update to remote');
      await _remoteDataSource.updateDeliveryStatus(customerId, statusId);

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote update failed, but local update succeeded');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

   @override
  ResultFuture<void> completeDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint('🔄 Starting delivery completion process');
      debugPrint('📦 Delivery Data ID: ${deliveryData.id}');
      debugPrint('🚛 Trip ID: ${deliveryData.trip.target?.id}');
      
      // Complete locally first
      debugPrint('💾 Processing delivery completion locally');
      await _localDataSource.completeDelivery(deliveryData);
      debugPrint('✅ Local delivery completion successful');

      // Then sync with remote
      debugPrint('🌐 Syncing delivery completion to remote');
      await _remoteDataSource.completeDelivery(deliveryData);
      debugPrint('✅ Remote delivery completion successful');

      debugPrint('🎉 Delivery completion process finished successfully');
      return const Right(null);
      
    } on CacheException catch (e) {
      debugPrint('❌ Local delivery completion failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote delivery completion failed, but local completion succeeded');
      debugPrint('❌ Remote error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ Unexpected error during delivery completion: ${e.toString()}');
      return Left(ServerFailure(
        message: 'Unexpected error during delivery completion: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }


@override
ResultFuture<DataMap> checkEndDeliverStatus(String tripId) async {
  try {
    debugPrint('🔄 Checking delivery status for trip: $tripId');
    final remoteResult = await _remoteDataSource.checkEndDeliverStatus(tripId);
    return Right(remoteResult);
  } on ServerException {
    debugPrint('⚠️ Remote check failed, falling back to local data');
    try {
      final localResult = await _localDataSource.checkEndDeliverStatus(tripId);
      return Right(localResult);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

@override
ResultFuture<DataMap> checkLocalEndDeliverStatus(String tripId) async {
  try {
    debugPrint('📱 Checking local delivery status for trip: $tripId');
    final localResult = await _localDataSource.checkEndDeliverStatus(tripId);
    return Right(localResult);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}


  @override
  ResultFuture<void> initializePendingStatus(List<String> customerIds) async {
    try {
      await _localDataSource.initializePendingStatus(customerIds);
      await _remoteDataSource.initializePendingStatus(customerIds);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  }) async {
    try {
      // Create locally first
      await _localDataSource.createDeliveryStatus(
        customerId,
        title: title,
        subtitle: subtitle,
        time: time,
        isAssigned: isAssigned,
        image: image,
      );

      // Then sync with remote
      await _remoteDataSource.createDeliveryStatus(
        customerId,
        title: title,
        subtitle: subtitle,
        time: time,
        isAssigned: isAssigned,
        image: image,
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
@override
ResultFuture<List<DeliveryUpdateEntity>> getLocalDeliveryStatusChoices(String customerId) async {
  try {
    debugPrint('📱 Loading delivery status choices from local storage');
    final localUpdates = await _localDataSource.getDeliveryStatusChoices(customerId);
    debugPrint('✅ Found ${localUpdates.length} local delivery statuses');

    try {
      debugPrint('🌐 Updating with remote data in background');
      final remoteUpdates = await _remoteDataSource.getDeliveryStatusChoices(customerId);
      for (var update in remoteUpdates) {
        if (update.id != null) {
          await _localDataSource.updateDeliveryStatus(customerId, update.id!);
        }
      }
      return Right(remoteUpdates);
    } on ServerException {
      return Right(localUpdates);
    }
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

 @override
ResultFuture<void> updateQueueRemarks(
  String customerId,
  String queueCount,
) async {
  try {
    // Update remote first
    debugPrint('🌐 Updating queue remarks remotely');
    await _remoteDataSource.updateQueueRemarks(
      customerId,
      queueCount,
    );

    // Then update local
    debugPrint('💾 Syncing queue remarks locally');
    await _localDataSource.updateQueueRemarks(
      customerId,
      queueCount,
    );

    return const Right(null);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}


}
