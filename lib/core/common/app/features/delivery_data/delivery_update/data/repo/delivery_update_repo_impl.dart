import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_datasource/delivery_update_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_datasource/delivery_update_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../../../objectbox.g.dart';
import '../../../../../../../enums/sync_status_enums.dart';
import '../../../../delivery_status_choices/data/model/delivery_status_choices_model.dart';
class DeliveryUpdateRepoImpl extends DeliveryUpdateRepo {
  const DeliveryUpdateRepoImpl(this._remoteDataSource, this._localDataSource);

  final DeliveryUpdateDatasource _remoteDataSource;
  final DeliveryUpdateLocalDatasource _localDataSource;
@override
ResultFuture<List<DeliveryUpdateEntity>> getDeliveryStatusChoices(
  String customerId,
) async {
  debugPrint('📦 [OFFLINE-FIRST] GetDeliveryStatusChoices($customerId)');

  // 1️⃣ LOCAL FIRST
  try {
    debugPrint('📱 Checking local cached status choices...');
    final localChoices = await _localDataSource.getDeliveryStatusChoices(customerId);

    if (localChoices.isNotEmpty) {
      debugPrint('✅ Local choices found: ${localChoices.length} items');

      // Return local immediately
      // BUT also refresh in the background from remote
     // _refreshChoicesInBackground(customerId);

      return Right(localChoices);
    } else {
      debugPrint('⚠️ No local choices, switching to remote...');
    }
  } catch (e) {
    debugPrint('⚠️ Local fetch failed: $e');
  }

  // 2️⃣ REMOTE FALLBACK
  try {
    debugPrint('🌐 Fetching delivery status choices from remote...');
    final remoteChoices = await _remoteDataSource.getDeliveryStatusChoices(customerId);

    debugPrint('✅ Remote returned ${remoteChoices.length} choices');

    // 3️⃣ Save remote to local for next offline use
    try {
      await _localDataSource.saveDeliveryStatusChoices(customerId, remoteChoices);
      debugPrint('💾 Cached status choices locally');
    } catch (e) {
      debugPrint('⚠️ Failed to cache remote choices (non-fatal): $e');
    }

    return Right(remoteChoices);

  } on ServerException catch (e) {
    debugPrint('❌ Remote failed: ${e.message}');

    return Left(
      ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ),
    );
  }
}



  // @override
  // ResultFuture<void> updateDeliveryStatus(String customerId, String statusId) async {
  //   try {
  //     // Update local first
  //     debugPrint('💾 Updating local delivery status');
  //     await _localDataSource.updateDeliveryStatus(customerId, statusId);

  //     // Then sync with remote
  //     debugPrint('🌐 Syncing status update to remote');
  //     await _remoteDataSource.updateDeliveryStatus(customerId, statusId);

  //     return const Right(null);
  //   } on CacheException catch (e) {
  //     return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  //   } on ServerException catch (e) {
  //     debugPrint('⚠️ Remote update failed, but local update succeeded');
  //     return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  //   }
  // }

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
    // -------------------------------------------------------
    // 1️⃣ LOCAL FIRST — fastest & offline-safe
    // -------------------------------------------------------
    debugPrint('📱 REPO: Checking end delivery status (LOCAL) for trip: $tripId');

    final localResult =
        await _localDataSource.checkEndDeliverStatus(tripId);

    debugPrint('✅ REPO: Local delivery status found');
    return Right(localResult);

  } on CacheException catch (localError) {
    debugPrint(
      '⚠️ REPO: Local check failed → ${localError.message}, trying REMOTE',
    );

    // -------------------------------------------------------
    // 2️⃣ FALLBACK — Remote source
    // -------------------------------------------------------
    try {
      debugPrint('🌐 REPO: Checking end delivery status (REMOTE)');

      final remoteResult =
          await _remoteDataSource.checkEndDeliverStatus(tripId);

      debugPrint('✅ REPO: Remote delivery status retrieved');
      return Right(remoteResult);

    } on ServerException catch (serverError) {
      debugPrint(
        '❌ REPO: Remote check also failed → ${serverError.message}',
      );

      return Left(
        CacheFailure(
          message: localError.message,
          statusCode: localError.statusCode,
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ REPO: Unexpected error → $e');
    return Left(
      CacheFailure(message: e.toString(), statusCode: '500'),
    );
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
          await _localDataSource.updateDeliveryStatus(customerId, update as DeliveryStatusChoicesModel);
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
  String statusId,
  String remarks,
  String image,
) async {
  try {
    // --------------------------------------------------
    // 1️⃣ LOCAL UPDATE (OFFLINE-FIRST)
    // --------------------------------------------------
    debugPrint('💾 LOCAL: Updating queue remarks');

    await _localDataSource.updateQueueRemarks(
      statusId,
      remarks,
      image,
    );

    // --------------------------------------------------
    // 2️⃣ MARK AS PENDING FOR BACKGROUND SYNC
    // --------------------------------------------------
    final q = _localDataSource.deliveryUpdateBox
        .query(DeliveryUpdateModel_.id.equals(statusId))
        .build();
    final localUpdate = q.findFirst();
    q.close();

    if (localUpdate != null) {
      localUpdate.syncStatus = SyncStatus.pending.name;
      localUpdate.lastLocalUpdatedAt = DateTime.now();
      _localDataSource.deliveryUpdateBox.put(localUpdate);
    }

    // --------------------------------------------------
    // 3️⃣ TRY REMOTE SYNC (BEST EFFORT)
    // --------------------------------------------------
    try {
      debugPrint('🌐 REMOTE: Syncing queue remarks');

      await _remoteDataSource.updateQueueRemarks(
        statusId,
        remarks,
        image,
      );

      // --------------------------------------------------
      // 4️⃣ MARK AS SYNCED IF SUCCESS
      // --------------------------------------------------
      if (localUpdate != null) {
        localUpdate.syncStatus = SyncStatus.synced.name;
        localUpdate.retryCount = 0;
        localUpdate.updated = DateTime.now();
        _localDataSource.deliveryUpdateBox.put(localUpdate);
      }

      debugPrint('✅ REMOTE: Queue remarks synced');
    } on ServerException catch (e) {
      // 🔁 Remote failed → background worker will retry
      debugPrint('⚠️ REMOTE FAILED (will retry): ${e.message}');

      if (localUpdate != null) {
        localUpdate.syncStatus = SyncStatus.failed.name;
        localUpdate.retryCount += 1;
        _localDataSource.deliveryUpdateBox.put(localUpdate);
      }
    }

    return const Right(null);
  } on CacheException catch (e) {
    debugPrint('❌ LOCAL FAILED: ${e.message}');
    return Left(
      CacheFailure(
        message: e.message,
        statusCode: e.statusCode,
      ),
    );
  }
}


@override
ResultFuture<void> pinArrivedLocation(String deliveryId) async {
  try {
    debugPrint('📍 Pinning arrived location for delivery: $deliveryId');
    
    // Pin location to remote
    await _remoteDataSource.pinArrivedLocation(deliveryId);
    
    debugPrint('✅ Successfully pinned arrived location');
    return const Right(null);
  } on ServerException catch (e) {
    debugPrint('❌ Failed to pin arrived location: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    debugPrint('❌ Unexpected error pinning location: ${e.toString()}');
    return Left(ServerFailure(
      message: 'Failed to pin arrived location: ${e.toString()}',
      statusCode: '500',
    ));
  }
}

  @override
ResultFuture<void> bulkUpdateDeliveryStatus(
  List<String> customerIds,
  String statusId,
) async {
  try {
    debugPrint('💾 Starting bulk delivery status update locally');
    await _localDataSource.bulkUpdateDeliveryStatus(customerIds, statusId);
    debugPrint('✅ Local bulk update completed for ${customerIds.length} customers');

    try {
      debugPrint('🌐 Syncing bulk delivery status update to remote');
      await _remoteDataSource.bulkUpdateDeliveryStatus(customerIds, statusId);
      debugPrint('✅ Remote bulk update completed successfully');
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote bulk update failed, but local update succeeded');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }

    return const Right(null);
  } on CacheException catch (e) {
    debugPrint('❌ Local bulk update failed: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    debugPrint('❌ Unexpected error during bulk update: $e');
    return Left(ServerFailure(
      message: 'Unexpected error during bulk update: ${e.toString()}',
      statusCode: '500',
    ));
  }
}

    @override
  ResultFuture<Map<String, List<DeliveryUpdateEntity>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  ) async {
    try {
      debugPrint('🌐 Fetching bulk delivery status choices from remote');
      final remoteMap = await _remoteDataSource.getBulkDeliveryStatusChoices(customerIds);

      // ✅ Sync valid remote updates locally
      for (final entry in remoteMap.entries) {
        final customerId = entry.key;
        final updates = entry.value;

        for (var update in updates) {
          if (update.id != null && update.id!.isNotEmpty) {
            await _localDataSource.updateDeliveryStatus(customerId, update.id! as DeliveryStatusChoicesModel);
          }
        }
      }

      return Right(remoteMap);
    } on ServerException catch (_) {
      debugPrint('⚠️ Remote bulk fetch failed, falling back to local');
      try {
        final localMap = await _localDataSource.getBulkDeliveryStatusChoices(customerIds);
        return Right(localMap);
      } on CacheException catch (ce) {
        return Left(CacheFailure(message: ce.message, statusCode: ce.statusCode));
      }
    } catch (e) {
      debugPrint('❌ Unexpected error in getBulkDeliveryStatusChoices: $e');
      return Left(ServerFailure(
        message: 'Unexpected error during bulk fetch: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }
  
 @override
ResultFuture<List<DeliveryUpdateEntity>> syncDeliveryStatusChoices(String customerId) async {
  try {
    debugPrint('🔄 [REPO] Syncing delivery updates for customer: $customerId');

    // 1️⃣ Fetch from remote
    final remoteUpdates = await _remoteDataSource.syncDeliveryStatusChoices(customerId);
    debugPrint('🌐 [REMOTE] Synced ${remoteUpdates.length} updates for customer $customerId');

    // 2️⃣ Save synced updates to local storage
    await _localDataSource.saveDeliveryUpdateChoices(customerId, remoteUpdates);
    debugPrint('💾 [LOCAL] Saved ${remoteUpdates.length} delivery updates for $customerId');

    // 3️⃣ Return as domain entities
    final entities = remoteUpdates.map((e) => e.copyWith()).toList();

    debugPrint('✅ [REPO COMPLETE] Synced and cached ${entities.length} updates for $customerId');
    return Right(entities);
  } on ServerException catch (e) {
    debugPrint('❌ [SERVER ERROR] Failed to sync updates: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    debugPrint('❌ [CACHE ERROR] Failed to save updates locally: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    debugPrint('🚨 [UNEXPECTED ERROR] $e');
    return Left(CacheFailure(message: e.toString(), statusCode: 500));
  }
}

 @override
ResultFuture<void> updateDeliveryStatus(
  String deliveryDataId,
  DeliveryStatusChoicesEntity status,
) async {
  try {
    // ---------------------------------------------------
    // 1️⃣ Update LOCAL first (offline-first)
    // ---------------------------------------------------
    debugPrint('💾 Updating local delivery status');
    await _localDataSource.updateDeliveryStatus(
      deliveryDataId,
      status as DeliveryStatusChoicesModel,
    );

    // ---------------------------------------------------
    // 2️⃣ Sync with REMOTE
    // ---------------------------------------------------
    debugPrint('🌐 Syncing status update to remote');
    await _remoteDataSource.updateDeliveryStatus(
      deliveryDataId,
      status,
    );

    return const Right(null);
  } on CacheException catch (e) {
    return Left(
      CacheFailure(
        message: e.message,
        statusCode: e.statusCode,
      ),
    );
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote update failed, but local update succeeded');
    return Left(
      ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ),
    );
  }
}






}
