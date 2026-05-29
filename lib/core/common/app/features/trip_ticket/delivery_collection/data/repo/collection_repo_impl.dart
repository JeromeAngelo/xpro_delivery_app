import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_datasource/collection_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_datasource/collection_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/repo/collection_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CollectionRepoImpl implements CollectionRepo {
  const CollectionRepoImpl({
    required CollectionRemoteDataSource remoteDataSource,
    required CollectionLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final CollectionRemoteDataSource _remoteDataSource;
  final CollectionLocalDataSource _localDataSource;
@override
ResultFuture<List<CollectionEntity>> getCollectionsByTripId(String tripId) async {
  try {
    debugPrint('📦 REPO: Attempting to load collections from local cache for trip: $tripId');

    // First, try to get data from local cache
    final localCollections = await _localDataSource.getCollectionsByTripId(tripId);

    if (localCollections.isNotEmpty) {
      debugPrint('✅ REPO: Loaded ${localCollections.length} collections from local cache');
      return Right(localCollections);
    }

    debugPrint('⚠️ REPO: No collections found in cache, fetching from remote for trip: $tripId');

    // Fetch from remote as fallback
    final remoteCollections = await _remoteDataSource.getCollectionsByTripId(tripId);

    debugPrint('📥 REPO: Fetched ${remoteCollections.length} collections from remote, caching locally');

    // Cache remote response locally
    await _localDataSource.cacheCollections(remoteCollections);

    debugPrint('✅ REPO: Remote collections cached successfully');
    return Right(remoteCollections);

  } on CacheException catch (cacheError) {
    debugPrint('❌ REPO: Failed to read/write local cache: ${cacheError.message}');
    
    try {
      // If cache fails, still try remote
      debugPrint('📡 REPO: Attempting to fetch collections from remote due to cache failure');
      final remoteCollections = await _remoteDataSource.getCollectionsByTripId(tripId);

      debugPrint('📥 REPO: Fetched ${remoteCollections.length} collections from remote despite cache failure');
      return Right(remoteCollections);

    } on ServerException catch (serverError) {
      debugPrint('❌ REPO: Remote fetch also failed: ${serverError.message}');
      return Left(ServerFailure(message: serverError.message, statusCode: serverError.statusCode));
    }
  } on ServerException catch (serverError) {
    debugPrint('⚠️ REPO: Remote fetch failed: ${serverError.message}, attempting local cache');

    try {
      final localCollections = await _localDataSource.getCollectionsByTripId(tripId);
      debugPrint('✅ REPO: Loaded ${localCollections.length} collections from local cache as fallback');
      return Right(localCollections);
    } on CacheException catch (cacheError) {
      debugPrint('❌ REPO: Local fallback also failed: ${cacheError.message}');
      return Left(CacheFailure(message: cacheError.message, statusCode: cacheError.statusCode));
    }
  } catch (e) {
    debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
    return Left(ServerFailure(message: e.toString(), statusCode: '500'));
  }
}

@override
ResultFuture<List<CollectionEntity>> getLocalCollectionsByTripId(
  String tripId,
) async {
  debugPrint('🔍 REPO: getLocalCollectionsByTripId($tripId) called');

  // ---------------------------------------------------
  // 1️⃣ LOCAL FIRST
  // ---------------------------------------------------
  try {
    debugPrint('📦 Checking local collections for trip: $tripId');

    final localCollections =
        await _localDataSource.getCollectionsByTripId(tripId);

    if (localCollections.isNotEmpty) {
      debugPrint(
        '✅ Local collections found: ${localCollections.length} records',
      );

      // 🔄 Activate watcher (ObjectBox will emit automatically)
      _localDataSource.watchAllCollections();

      return Right(localCollections);
    } else {
      debugPrint('⚠️ Local collections empty');
    }
  } catch (e) {
    debugPrint('⚠️ Local lookup failed: $e');
  }

  // ---------------------------------------------------
  // 2️⃣ REMOTE FALLBACK
  // ---------------------------------------------------
  try {
    debugPrint('🌐 Fetching collections remotely for trip: $tripId');

    final remoteCollections =
        await _remoteDataSource.getCollectionsByTripId(tripId);

    debugPrint(
      '✅ Remote collections retrieved: ${remoteCollections.length} records',
    );

    // ❌ NO WATCHER HERE
    // Remote sync updates ObjectBox → stream auto-emits

    return Right(remoteCollections);
  } on ServerException catch (e) {
    debugPrint('❌ Remote fetch failed: ${e.message}');
    return Left(
      ServerFailure(message: e.message, statusCode: e.statusCode),
    );
  }
}
@override
ResultFuture<CollectionEntity> getCollectionById(String collectionId) async {
  debugPrint('🔍 REPO: getCollectionById($collectionId) called');

  // ---------------------------------------------------
  // 1️⃣ LOCAL FIRST
  // ---------------------------------------------------
  try {
    debugPrint('📦 Checking local collection for ID: $collectionId');

    final localCollection =
        await _localDataSource.getCollectionById(collectionId);

    debugPrint('✅ Local collection found for ID: $collectionId');

    // 🔄 Activate watcher for this collection
    _localDataSource.watchCollectionById(collectionId);

    return Right(localCollection as CollectionEntity);
  } on CacheException catch (_) {
    debugPrint('⚠️ Local collection not found');
  } catch (e) {
    debugPrint('⚠️ Local lookup failed: $e');
  }

  // ---------------------------------------------------
  // 2️⃣ REMOTE FALLBACK
  // ---------------------------------------------------
  try {
    debugPrint('🌐 Fetching collection remotely for ID: $collectionId');

    final remoteCollection =
        await _remoteDataSource.getCollectionById(collectionId);

    debugPrint('✅ Remote collection retrieved for ID: $collectionId');

    // 🔄 Start watcher (local DB will update after save)
    _localDataSource.watchCollectionById(collectionId);

    return Right(remoteCollection);
  } on ServerException catch (e) {
    debugPrint('❌ Remote fetch failed: ${e.message}');
    return Left(
      ServerFailure(message: e.message, statusCode: e.statusCode),
    );
  }
}

  @override
  ResultFuture<CollectionEntity> getLocalCollectionById(String collectionId) async {
    try {
      debugPrint('📦 REPO: Fetching collection from local storage by ID: $collectionId');
      
      final localCollection = await _localDataSource.getCollectionById(collectionId);
      
      debugPrint('✅ REPO: Successfully loaded collection from local storage');
      return Right(localCollection as CollectionEntity);

    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local fetch failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error in local fetch: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<bool> deleteCollection(String collectionId) async {
    try {
      debugPrint('🔄 REPO: Deleting collection from remote: $collectionId');
      
      // Delete from remote first
      final remoteDeleted = await _remoteDataSource.deleteCollection(collectionId);
      
      if (remoteDeleted) {
        debugPrint('📥 REPO: Deleting collection from local storage');
        
        // Delete from local storage
        await _localDataSource.deleteCollection(collectionId);
        
        debugPrint('✅ REPO: Successfully deleted collection from both remote and local');
        return const Right(true);
      } else {
        debugPrint('⚠️ REPO: Remote deletion returned false');
        return Left(ServerFailure(message: 'Failed to delete collection from remote', statusCode: '500'));
      }

    } on ServerException catch (e) {
      debugPrint('⚠️ REPO: Remote deletion failed: ${e.message}');
      
      try {
        // Still try to delete from local storage
        debugPrint('📦 REPO: Attempting to delete from local storage only');
        final localDeleted = await _localDataSource.deleteCollection(collectionId);
        
        if (localDeleted) {
          debugPrint('✅ REPO: Successfully deleted collection from local storage (remote failed)');
          return const Right(true);
        } else {
          debugPrint('❌ REPO: Local deletion also failed');
          return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
        }

      } on CacheException catch (cacheError) {
        debugPrint('❌ REPO: Local deletion also failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: cacheError.statusCode));
      }

    } on CacheException catch (e) {
      debugPrint('❌ REPO: Cache operation failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error during deletion: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  ResultFuture<bool> deleteLocalCollection(String collectionId) async {
    try {
      debugPrint('📦 REPO: Deleting collection from local storage only: $collectionId');
      
      final localDeleted = await _localDataSource.deleteCollection(collectionId);
      
      if (localDeleted) {
        debugPrint('✅ REPO: Successfully deleted collection from local storage');
        return const Right(true);
      } else {
        debugPrint('❌ REPO: Local deletion failed');
        return Left(CacheFailure(message: 'Failed to delete collection from local storage', statusCode: '500'));
      }

    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local deletion failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error in local deletion: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: '500'));
    }
  }
}
