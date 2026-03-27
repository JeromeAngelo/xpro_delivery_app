import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/repo/delivery_data_repo.dart';
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
      debugPrint(
        '✅ Retrieved ${remoteDeliveryData.length} delivery data records',
      );

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
        debugPrint(
          '📱 Retrieved ${localDeliveryData.length} delivery data records from local cache',
        );
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
  ResultFuture<List<DeliveryDataEntity>> getDeliveryDataByTripId(
    String tripId,
  ) async {
    debugPrint('🔍 REPO: getDeliveryDataByTripId($tripId) called');

    // ---------------------------------------------------
    // 1️⃣ LOCAL FIRST
    // ---------------------------------------------------
    try {
      debugPrint('📦 Checking local delivery data for trip: $tripId');
      final localData = await _localDataSource
          .forceReloadDeliveryUpdatesByTripId(tripId);

      if (localData.isNotEmpty) {
        debugPrint('✅ Local delivery data found: ${localData.length} records');

        _localDataSource.watchAllDeliveryData();

        return Right(localData);
      } else {
        debugPrint('⚠️ Local delivery data empty');
      }
    } catch (e) {
      debugPrint('⚠️ Local lookup failed: $e');
    }

    // ---------------------------------------------------
    // 2️⃣ REMOTE FALLBACK
    // ---------------------------------------------------
    try {
      debugPrint('🌐 Fetching delivery data remotely...');
      final remoteData = await _remoteDataSource.getDeliveryDataByTripId(
        tripId,
      );

      debugPrint(
        '✅ Remote delivery data retrieved: ${remoteData.length} records',
      );

      // ❌ NO WATCHER HERE
      // Remote sync will trigger ObjectBox changes,
      // which automatically emits via watchAllDeliveryData()

      return Right(remoteData);
    } on ServerException catch (e) {
      debugPrint('❌ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<DeliveryDataEntity> getDeliveryDataById(String id) async {
    debugPrint('🔍 REPO: getDeliveryDataById($id) called');

    // 1️⃣ LOCAL FIRST
    try {
      debugPrint('📦 Checking local delivery data for ID: $id');
      final localData = await _localDataSource.getDeliveryDataById(id);

      if (localData != null) {
        debugPrint('✅ Local delivery data found for ID: $id');

        // 🔄 Activate watcher for this item
        _startWatchingSingle(id);

        return Right(localData);
      } else {
        debugPrint('⚠️ Local record is NULL');
      }
    } catch (e) {
      debugPrint('⚠️ Local lookup failed: $e');
    }

    // 2️⃣ REMOTE FALLBACK
    try {
      debugPrint('🌐 Fetching delivery data remotely for ID: $id');
      final remoteData = await _remoteDataSource.getDeliveryDataById(id);

      debugPrint('✅ Remote delivery data retrieved for ID: $id');

      // 🔄 Start stream watch for the entity
      _startWatchingSingle(id);

      return Right(remoteData);
    } on ServerException catch (e) {
      debugPrint('❌ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
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
      return Right(localDeliveryData as DeliveryDataEntity);
    } on CacheException catch (e) {
      debugPrint('⚠️ Local Cache Error: ${e.message}');

      // Try to get data from remote if local fails
      try {
        debugPrint('🌐 Attempting to retrieve delivery data from remote');
        final remoteDeliveryData = await _remoteDataSource.getDeliveryDataById(
          id,
        );
        debugPrint('✅ Retrieved delivery data with ID: $id from remote');

        // Cache the remote data locally for future use
        try {
          await _localDataSource.updateDeliveryData(remoteDeliveryData);
          debugPrint('💾 Cached remote delivery data to local storage');
        } catch (cacheError) {
          debugPrint('⚠️ Failed to cache remote data locally: $cacheError');
          // Continue even if caching fails
        }

        return Right(remoteDeliveryData);
      } on ServerException catch (serverError) {
        debugPrint('❌ Remote fetch also failed: ${serverError.message}');
        return Left(
          ServerFailure(
            message: serverError.message,
            statusCode: serverError.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: 404));
    }
  }

  @override
  ResultFuture<List<DeliveryDataEntity>> getLocalDeliveryDataByTripId(
    String tripId,
  ) async {
    try {
      debugPrint(
        '📱 Fetching delivery data for trip ID: $tripId from local storage',
      );
      final localDeliveryData = await _localDataSource.getDeliveryDataByTripId(
        tripId,
      );
      debugPrint(
        '✅ Retrieved ${localDeliveryData.length} delivery data records for trip ID: $tripId from local storage',
      );
      return Right(localDeliveryData);
    } on CacheException catch (e) {
      debugPrint('⚠️ Local Cache Error: ${e.message}');

      // Try to get data from remote if local fails
      try {
        debugPrint('🌐 Attempting to retrieve delivery data from remote');
        final remoteDeliveryData = await _remoteDataSource
            .getDeliveryDataByTripId(tripId);
        debugPrint(
          '✅ Retrieved ${remoteDeliveryData.length} delivery data records for trip ID: $tripId from remote',
        );

        // Cache the remote data locally for future use
        try {
          await _localDataSource.cacheDeliveryData(remoteDeliveryData);
          debugPrint('💾 Cached remote delivery data to local storage');
        } catch (cacheError) {
          debugPrint('⚠️ Failed to cache remote data locally: $cacheError');
          // Continue even if caching fails
        }

        return Right(remoteDeliveryData);
      } on ServerException catch (serverError) {
        debugPrint('❌ Remote fetch also failed: ${serverError.message}');
        return Left(
          ServerFailure(
            message: serverError.message,
            statusCode: serverError.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: 404));
    }
  }

  @override
  ResultFuture<int> calculateDeliveryTimeByDeliveryId(String deliveryId) async {
    final id = deliveryId.trim();
    if (id.isEmpty) {
      return Left(
        CacheFailure(message: 'Delivery ID is required', statusCode: 400),
      );
    }

    debugPrint('⏱️ REPO: Calculating delivery time for deliveryId=$id');

    // ---------------------------------------------------
    // 1️⃣ OFFLINE FIRST (LOCAL)
    // ---------------------------------------------------
    try {
      debugPrint('📱 REPO: Trying local delivery time calculation...');
      final localTime = await _localDataSource
          .calculateDeliveryTimeByDeliveryId(id);

      debugPrint('✅ REPO: Local calculation successful: $localTime minutes');
      return Right(localTime);
    } on CacheException catch (e) {
      debugPrint('⚠️ REPO: Local calculation failed: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ REPO: Local unexpected error: $e');
    }

    // ---------------------------------------------------
    // 2️⃣ REMOTE FALLBACK
    // ---------------------------------------------------
    try {
      debugPrint('🌐 REPO: Falling back to remote calculation...');
      final remoteTime = await _remoteDataSource
          .calculateDeliveryTimeByDeliveryId(id);

      debugPrint('✅ REPO: Remote calculation successful: $remoteTime minutes');
      return Right(remoteTime);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Remote calculation failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Remote unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<DeliveryDataEntity>> syncDeliveryDataByTripId(
    String tripId,
  ) async {
    try {
      debugPrint('🔄 Starting delivery data sync for trip: $tripId');

      // Fetch delivery data from remote
      final remoteDeliveryData = await _remoteDataSource
          .syncDeliveryDataByTripId(tripId);
      debugPrint(
        '✅ Retrieved ${remoteDeliveryData.length} delivery data records from remote',
      );

      // Store synced data locally
      await _localDataSource.saveDeliveryDataByTripId(
        tripId,
        remoteDeliveryData,
      );
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
        debugPrint(
          '🔍 Attempting to retrieve local delivery data for trip: $tripId',
        );
        final localDeliveryData = await _localDataSource
            .getDeliveryDataByTripId(tripId);
        debugPrint(
          '📱 Retrieved ${localDeliveryData.length} delivery data records from local cache',
        );

        if (localDeliveryData.isNotEmpty) {
          debugPrint('✅ Using cached delivery data for trip: $tripId');
          return Right(localDeliveryData);
        } else {
          debugPrint('⚠️ No cached delivery data found for trip: $tripId');
          return Left(
            CacheFailure(
              message: 'No delivery data available for sync',
              statusCode: 404,
            ),
          );
        }
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local cache retrieval failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 404));
      }
    } on CacheException catch (e) {
      debugPrint('❌ Local sync failed for trip $tripId: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 500));
    } catch (e) {
      debugPrint(
        '❌ Unexpected error during delivery data sync: ${e.toString()}',
      );
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<DeliveryDataEntity> setInvoiceIntoUnloading(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 [REPO] Offline-first setInvoiceIntoUnloading for deliveryDataId=$deliveryDataId',
      );

      // -------------------------------------------------------
      // 1️⃣ OFFLINE FIRST (local)
      // -------------------------------------------------------
      DeliveryDataEntity? localResult;
      try {
        final local = await _localDataSource.setInvoiceIntoUnloading(
          deliveryDataId,
        );
        localResult = local;
        debugPrint('✅ [REPO] Local setInvoiceIntoUnloading SUCCESS (fast UI)');
      } catch (e) {
        debugPrint('⚠️ [REPO] Local setInvoiceIntoUnloading FAILED: $e');
        // Continue to remote even if local fails
      }

      // -------------------------------------------------------
      // 2️⃣ REMOTE (source of truth)
      // -------------------------------------------------------
      try {
        final remoteResult = await _remoteDataSource.setInvoiceIntoUnloading(
          deliveryDataId,
        );

        debugPrint('✅ [REPO] Remote setInvoiceIntoUnloading SUCCESS');

        // -------------------------------------------------------
        // 3️⃣ Update local again using remote success
        //    (ensures local matches server)
        // -------------------------------------------------------
        try {
          await _localDataSource.setInvoiceIntoUnloading(deliveryDataId);
          debugPrint('💾 [REPO] Local updated after remote success');
        } catch (e) {
          debugPrint('⚠️ [REPO] Failed local update after remote success: $e');
        }

        return Right(remoteResult);
      } on ServerException catch (e) {
        debugPrint('❌ [REPO] Remote FAILED: ${e.message}');

        // If local already succeeded, return local as "success" to avoid UI error
        if (localResult != null) {
          debugPrint(
            '✅ [REPO] Returning LOCAL success result despite remote failure (offline-first behavior)',
          );
          return Right(localResult);
        }

        return Left(
          ServerFailure(message: e.message, statusCode: e.statusCode),
        );
      }
    } catch (e) {
      debugPrint('❌ [REPO] Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<DeliveryDataEntity> setInvoiceIntoUnloaded(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 [REPO] Offline-first setInvoiceIntoUnloaded for deliveryDataId=$deliveryDataId',
      );

      // -------------------------------------------------------
      // 1️⃣ OFFLINE FIRST (local)
      // -------------------------------------------------------
      DeliveryDataEntity? localResult;
      try {
        final local = await _localDataSource.setInvoiceIntoUnloaded(
          deliveryDataId,
        );
        localResult = local;
        debugPrint('✅ [REPO] Local setInvoiceIntoUnloaded SUCCESS (fast UI)');
      } catch (e) {
        debugPrint('⚠️ [REPO] Local setInvoiceIntoUnloaded FAILED: $e');
        // Continue to remote even if local fails
      }

      // -------------------------------------------------------
      // 2️⃣ REMOTE (source of truth)
      // -------------------------------------------------------
      try {
        final remoteResult = await _remoteDataSource.setInvoiceIntoUnloaded(
          deliveryDataId,
        );

        debugPrint('✅ [REPO] Remote setInvoiceIntoUnloaded SUCCESS');

        // -------------------------------------------------------
        // 3️⃣ Update local again using remote success
        //    (ensures local matches server)
        // -------------------------------------------------------
        try {
          await _localDataSource.setInvoiceIntoUnloaded(deliveryDataId);
          debugPrint('💾 [REPO] Local updated after remote success');
        } catch (e) {
          debugPrint('⚠️ [REPO] Failed local update after remote success: $e');
        }

        return Right(remoteResult);
      } on ServerException catch (e) {
        debugPrint('❌ [REPO] Remote FAILED: ${e.message}');

        // If local already succeeded, return local as "success" to avoid UI error
        if (localResult != null) {
          debugPrint(
            '✅ [REPO] Returning LOCAL success result despite remote failure (offline-first behavior)',
          );
          return Right(localResult);
        }

        return Left(
          ServerFailure(message: e.message, statusCode: e.statusCode),
        );
      }
    } catch (e) {
      debugPrint('❌ [REPO] Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<DeliveryDataEntity> updateDeliveryLocation(
    String id,
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('🔄 Updating delivery location for ID: $id');
      debugPrint('📍 Coordinates: Lat: $latitude, Long: $longitude');

      final result = await _remoteDataSource.updateDeliveryLocation(
        id,
        latitude,
        longitude,
      );
      debugPrint('✅ Successfully updated delivery location for ID: $id');

      // Update local cache with the updated data
      try {
        await _localDataSource.updateDeliveryData(result);
        debugPrint('💾 Updated delivery location in local storage');
      } catch (cacheError) {
        debugPrint('⚠️ Failed to update local cache: $cacheError');
        // Continue even if local update fails
      }

      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ Failed to update delivery location: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<DeliveryDataEntity> setInvoiceIntoCompleted(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 Setting invoice to completed for delivery data: $deliveryDataId',
      );

      final result = await _remoteDataSource.setInvoiceIntoCompleted(
        deliveryDataId,
      );
      debugPrint('✅ Successfully set invoice to completed');

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
      debugPrint('❌ Failed to set invoice to completed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultStream<List<DeliveryDataEntity>> watchLocalDeliveryDataByTripId(
    String tripId,
  ) {
    try {
      debugPrint(
        '👀 OFFLINE-FIRST: Watching local delivery data for trip ID: $tripId',
      );

      // Step 1: Get live updates from the local datasource (ObjectBox watch stream)
      final stream = _localDataSource.watchDeliveryDataByTripId(tripId).asyncMap((
        models,
      ) async {
        debugPrint(
          '📦 LOCAL STREAM: Received ${models.length} records from local storage',
        );

        // Step 2: Convert models to domain entities
        final entities = models.map((model) => model.copyWith()).toList();

        debugPrint('✅ Converted ${entities.length} models to domain entities');
        return entities;
      });

      return stream;
    } on CacheException catch (e) {
      debugPrint('⚠️ LOCAL STREAM ERROR: ${e.message}');
      // Return a stream that emits an empty list when cache fails (avoids breaking the stream)
      return Stream.value([]);
    } catch (e) {
      debugPrint('❌ Unexpected error in watchLocalDeliveryDataByTripId: $e');
      return Stream.value([]);
    }
  }

  @override
  ResultStream<DeliveryDataEntity?> watchLocalDeliveryDataById(
    String deliveryId,
  ) {
    try {
      debugPrint(
        '👀 OFFLINE-FIRST: Watching local delivery data by ID: $deliveryId',
      );

      // Step 1: Get live updates from local datasource (ObjectBox stream)
      final stream = _localDataSource.watchDeliveryDataById(deliveryId).asyncMap((
        model,
      ) async {
        if (model == null) {
          debugPrint('⚠️ LOCAL STREAM: No data found for ID: $deliveryId');
          return null;
        }

        debugPrint(
          '📦 LOCAL STREAM: Received delivery data update for ID: $deliveryId',
        );

        // Step 2: Convert model to domain entity (deep copy if needed)
        final entity = model.copyWith();

        debugPrint('✅ Converted model to domain entity for ID: $deliveryId');
        return entity;
      });

      return stream;
    } on CacheException catch (e) {
      debugPrint('⚠️ LOCAL STREAM ERROR (by ID): ${e.message}');
      // Emit null to avoid breaking stream listeners
      return Stream.value(null);
    } catch (e) {
      debugPrint('❌ Unexpected error in watchLocalDeliveryDataById: $e');
      return Stream.value(null);
    }
  }

  // void _startWatchingTrip(String tripId) {
  //   try {
  //     debugPrint('👀 REPO: Activating watch for trip = $tripId');

  //     // We do not listen here — UI will subscribe.
  //     _localDataSource.watchDeliveryDataByTripId(tripId);
  //   } catch (e) {
  //     debugPrint('⚠️ Failed to start trip watcher: $e');
  //   }
  // }

  void _startWatchingSingle(String id) {
    try {
      debugPrint('👀 REPO: Activating watch for delivery ID = $id');

      // If you also have a watchDeliveryDataById(), call it here
      _localDataSource.watchDeliveryDataById(id);
    } catch (e) {
      debugPrint('⚠️ Failed to start ID watcher: $e');
    }
  }

  @override
  ResultStream<List<DeliveryDataEntity>> watchAllLocalDeliveryData() {
    try {
      debugPrint('👀 OFFLINE-FIRST: Watching all local delivery data');

      // Step 1️⃣: Get live updates from the local datasource (ObjectBox watch stream)
      final stream = _localDataSource.watchAllDeliveryData().asyncMap((
        models,
      ) async {
        debugPrint(
          '📦 LOCAL STREAM: Received ${models.length} records from local storage',
        );

        // Step 2️⃣: Convert models to domain entities
        final entities = models.map((model) => model.copyWith()).toList();

        debugPrint('✅ Converted ${entities.length} models to domain entities');
        return entities;
      });

      return stream;
    } on CacheException catch (e) {
      debugPrint('⚠️ LOCAL STREAM ERROR: ${e.message}');
      // Return a stream that emits an empty list when cache fails (avoids breaking the stream)
      return Stream.value([]);
    } catch (e) {
      debugPrint('❌ Unexpected error in watchAllLocalDeliveryData: $e');
      return Stream.value([]);
    }
  }

  @override
  ResultFuture<DeliveryDataEntity> setInvoiceIntoCancelled(
    String deliveryDataId,
    String invoiceId,
  ) async {
    {
      try {
        debugPrint(
          '🔄 [REPO] Offline-first setInvoiceIntoUnloaded for deliveryDataId=$deliveryDataId',
        );

        // -------------------------------------------------------
        // 1️⃣ OFFLINE FIRST (local)
        // -------------------------------------------------------
        DeliveryDataEntity? localResult;
        try {
          final local = await _localDataSource.setInvoiceIntoCancelled(
            deliveryDataId,
            invoiceId,
          );
          localResult = local;
          debugPrint(
            '✅ [REPO] Local setInvoiceIntoCancelled SUCCESS (fast UI)',
          );
        } catch (e) {
          debugPrint('⚠️ [REPO] Local setInvoiceIntoCancelled FAILED: $e');
          // Continue to remote even if local fails
        }

        // -------------------------------------------------------
        // 2️⃣ REMOTE (source of truth)
        // -------------------------------------------------------
        try {
          final remoteResult = await _remoteDataSource.setInvoiceIntoCancelled(
            deliveryDataId,
            invoiceId,
          );

          debugPrint('✅ [REPO] Remote setInvoiceIntoCancelled SUCCESS');

          // -------------------------------------------------------
          // 3️⃣ Update local again using remote success
          //    (ensures local matches server)
          // -------------------------------------------------------
          try {
            await _localDataSource.setInvoiceIntoCancelled(
              deliveryDataId,
              invoiceId,
            );
            debugPrint('💾 [REPO] Local updated after remote success');
          } catch (e) {
            debugPrint(
              '⚠️ [REPO] Failed local update after remote success: $e',
            );
          }

          return Right(remoteResult);
        } on ServerException catch (e) {
          debugPrint('❌ [REPO] Remote FAILED: ${e.message}');

          // If local already succeeded, return local as "success" to avoid UI error
          if (localResult != null) {
            debugPrint(
              '✅ [REPO] Returning LOCAL success result despite remote failure (offline-first behavior)',
            );
            return Right(localResult);
          }

          return Left(
            ServerFailure(message: e.message, statusCode: e.statusCode),
          );
        }
      } catch (e) {
        debugPrint('❌ [REPO] Unexpected error: ${e.toString()}');
        return Left(ServerFailure(message: e.toString(), statusCode: '500'));
      }
    }
  }
}
