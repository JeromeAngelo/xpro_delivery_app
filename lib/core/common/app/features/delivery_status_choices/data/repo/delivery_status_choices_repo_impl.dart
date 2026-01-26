import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart' show debugPrint;
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/enums/sync_status_enums.dart';

import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../errors/exceptions.dart';
import '../../../../../../errors/failures.dart';
import '../../domain/repo/delivery_status_choices_repo.dart';
import '../datasources/local_datasource/delivery_status_choices_local_datasource.dart';
import '../datasources/remote_datasource/delivery_status_choices_remote_datasource.dart';
import '../datasources/sync/sync_delivery_status_choices_worker.dart';
import '../model/delivery_status_choices_model.dart';

class DeliveryStatusChoicesRepoImpl implements DeliveryStatusChoicesRepo {
  final DeliveryStatusChoicesLocalDatasource _localDatasource;
  final DeliveryStatusChoicesRemoteDataSource _remoteDatasource;
  final DeliveryStatusSyncWorker _syncWorker;
  DeliveryStatusChoicesRepoImpl(
    this._localDatasource,
    this._remoteDatasource,
    this._syncWorker, // pass the worker
  );

  @override
  ResultFuture<List<DeliveryStatusChoicesEntity>>
  syncAllDeliveryStatusChoices() async {
    try {
      debugPrint('🔄 [REPO] Starting sync of all delivery status choices');

      // 1️⃣ Fetch all from remote PocketBase
      final remoteChoices =
          await _remoteDatasource.syncAllDeliveryStatusChoices();

      // 2️⃣ Save to local ObjectBox
      await _localDatasource.saveAllDeliveryStatusChoices(remoteChoices);

      debugPrint('✅ [REPO] Sync completed & cached successfully');

      // 3️⃣ Return the synced items (as entity list)
      return Right(remoteChoices);
    } on ServerException catch (e) {
      debugPrint('❌ [REPO] Remote sync failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('❌ [REPO] Local cache failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<DeliveryStatusChoicesEntity>>
  getAllAssignedDeliveryStatusChoices(String customerId) async {
    debugPrint('📦 [OFFLINE-FIRST] GetDeliveryStatusChoices($customerId)');

    // 1️⃣ LOCAL FIRST
    try {
      debugPrint('📱 Checking local cached status choices...');
      final localChoices = await _localDatasource.getDeliveryStatusChoices(
        customerId,
      );

      if (localChoices.isNotEmpty) {
        debugPrint('✅ Local choices found: ${localChoices.length} items');

        // Return local immediately
        // Optionally refresh in the background from remote
        // _refreshChoicesInBackground(customerId);

        return Right(localChoices); // ✅ now returns DeliveryStatusChoicesEntity
      } else {
        debugPrint('⚠️ No local choices, switching to remote...');
      }
    } catch (e) {
      debugPrint('⚠️ Local fetch failed: $e');
    }

    // 2️⃣ REMOTE FALLBACK
    try {
      debugPrint('🌐 Fetching delivery status choices from remote...');
      final remoteChoices = await _remoteDatasource
          .getAllAssignedDeliveryStatusChoices(customerId);

      debugPrint('✅ Remote returned ${remoteChoices.length} choices');

      // 3️⃣ Save remote to local for next offline use
      // try {
      //   await _localDatasource.saveAllDeliveryStatusChoices(customerId, remoteChoices);
      //   debugPrint('💾 Cached status choices locally');
      // } catch (e) {
      //   debugPrint('⚠️ Failed to cache remote choices (non-fatal): $e');
      // }

      return Right(remoteChoices);
    } on ServerException catch (e) {
      debugPrint('❌ Remote failed: ${e.message}');

      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> updateDeliveryStatus(
    String deliveryDataId,
    DeliveryStatusChoicesEntity status,
  ) async {
    try {
      final statusModel = status as DeliveryStatusChoicesModel;

      // ---------------------------------------------------
      // 1️⃣ Update LOCAL first (offline-first)
      // ---------------------------------------------------
      debugPrint('💾 Updating local delivery status');
      await _localDatasource.updateCustomerStatus(deliveryDataId, statusModel);

      // ---------------------------------------------------
      // 2️⃣ Queue REMOTE sync in background worker
      // ---------------------------------------------------
      debugPrint('🟡 Queuing remote sync for background worker');

      // Mark status as pending for sync
      statusModel.syncStatus = SyncStatus.pending.name;
      statusModel.lastLocalUpdatedAt = DateTime.now();
      statusModel.retryCount = 0;

      await _localDatasource.deliveryStatusChoicesBox.put(statusModel);

      // Enqueue in worker
      _syncWorker.start();

      debugPrint('✅ Status update queued for background sync');

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote update failed, local update succeeded');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesEntity status,
  ) {
    return _bulkUpdateDeliveryStatusImpl(customerIds, status);
  }

  @override
  ResultFuture<Map<String, List<DeliveryStatusChoicesEntity>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds) {
    return _getAllBulkDeliveryStatusChoicesImpl(customerIds);
  }

  // Implementation helpers
  ResultFuture<Map<String, List<DeliveryStatusChoicesEntity>>>
  _getAllBulkDeliveryStatusChoicesImpl(List<String> customerIds) async {
    try {
      debugPrint(
        '📦 [REPO OFFLINE-FIRST] getAllBulkDeliveryStatusChoices for ${customerIds.length} customers',
      );

      // 1️⃣ Try local first
      try {
        final local = await _localDatasource.getAllBulkDeliveryStatusChoices(
          customerIds,
        );
        // If any customer has choices, prefer local
        final hasAny = local.values.any((list) => list.isNotEmpty);
        if (hasAny) {
          debugPrint(
            '✅ Returning local bulk choices (some customers have choices)',
          );
          return Right(local);
        }
        debugPrint(
          '⚠️ Local returned empty choices for all customers — falling back to remote',
        );
      } catch (e) {
        debugPrint('⚠️ Local bulk fetch failed (non-fatal): $e');
      }

      // 2️⃣ Remote fallback
      try {
        final remote = await _remoteDatasource.getAllBulkDeliveryStatusChoices(
          customerIds,
        );
        debugPrint('✅ Remote bulk choices fetched');
        // Optionally cache remote results locally for future offline use
        try {
          final flattened = remote.values.expand((e) => e).toList();
          if (flattened.isNotEmpty) {
            await _localDatasource.saveAllDeliveryStatusChoices(flattened);
            debugPrint('💾 Cached remote bulk choices locally');
          }
        } catch (_) {}

        return Right(remote);
      } on ServerException catch (e) {
        debugPrint('❌ Remote bulk fetch failed: ${e.message}');
        return Left(
          ServerFailure(message: e.message, statusCode: e.statusCode),
        );
      }
    } catch (e) {
      debugPrint('❌ getAllBulkDeliveryStatusChoices failed: $e');
      return Left(CacheFailure(message: e.toString(), statusCode: '500'));
    }
  }

  ResultFuture<void> _bulkUpdateDeliveryStatusImpl(
    List<String> customerIds,
    DeliveryStatusChoicesEntity status,
  ) async {
    try {
      final statusModel = status as DeliveryStatusChoicesModel;

      debugPrint(
        '📦 [REPO] bulkUpdateDeliveryStatus offline-first for ${customerIds.length} customers',
      );

      // 1️⃣ Try local enqueue first
      try {
        await _localDatasource.bulkUpdateDeliveryStatus(
          customerIds,
          statusModel,
        );

        // Ensure a record exists for the status choice so worker can pick it up
        statusModel.syncStatus = SyncStatus.pending.name;
        statusModel.lastLocalUpdatedAt = DateTime.now();
        statusModel.retryCount = 0;

        try {
          await _localDatasource.deliveryStatusChoicesBox.put(statusModel);
        } catch (_) {}

        // Start background worker to sync pending DeliveryUpdate entries
        _syncWorker.start();

        debugPrint('✅ Local bulk enqueue succeeded; worker started');
        return Right(null);
      } catch (e) {
        debugPrint('⚠️ Local bulk enqueue failed (trying remote): $e');
      }

      // 2️⃣ Remote fallback
      try {
        await _remoteDatasource.bulkUpdateDeliveryStatus(
          customerIds,
          statusModel,
        );
        debugPrint('✅ Remote bulk update succeeded');
        return Right(null);
      } on ServerException catch (e) {
        debugPrint('❌ Remote bulk update failed: ${e.message}');
        return Left(
          ServerFailure(message: e.message, statusCode: e.statusCode),
        );
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ bulkUpdateDeliveryStatus failed: $e');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<void> setEndDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint('🔄 Starting delivery completion process');
      debugPrint('📦 Delivery Data ID: ${deliveryData.id}');
      debugPrint('🚛 Trip ID: ${deliveryData.trip.target?.id}');
      
      // Complete locally first
      debugPrint('💾 Processing delivery completion locally');
      await _localDatasource.setEndDelivery(deliveryData);
      debugPrint('✅ Local delivery completion successful');

      // Then sync with remote
      debugPrint('🌐 Syncing delivery completion to remote');
      await _remoteDatasource.setEndDelivery(deliveryData);
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
}
