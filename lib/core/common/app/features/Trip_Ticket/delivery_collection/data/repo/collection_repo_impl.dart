import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/data/datasource/local_datasource/collection_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/domain/repo/collection_repo.dart';
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
      debugPrint('🔄 REPO: Fetching collections from remote for trip: $tripId');
      
      // Try to fetch from remote first
      final remoteCollections = await _remoteDataSource.getCollectionsByTripId(tripId);
      
      debugPrint('📥 REPO: Starting sync for ${remoteCollections.length} remote collections');
      
      // Cache the remote data locally
      await _localDataSource.cacheCollections(remoteCollections);
      
      debugPrint('✅ REPO: Successfully fetched and cached collections from remote');
      return Right(remoteCollections);

    } on ServerException catch (e) {
      debugPrint('⚠️ REPO: Remote fetch failed: ${e.message}');
      
      try {
        // Fallback to local data
        debugPrint('📦 REPO: Attempting to load collections from local storage');
        final localCollections = await _localDataSource.getCollectionsByTripId(tripId);
        
        debugPrint('✅ REPO: Successfully loaded ${localCollections.length} collections from cache');
        return Right(localCollections);

      } on CacheException catch (cacheError) {
        debugPrint('❌ REPO: Local fallback also failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: cacheError.statusCode));
      }

    } on CacheException catch (e) {
      debugPrint('❌ REPO: Cache operation failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<CollectionEntity>> getLocalCollectionsByTripId(String tripId) async {
    try {
      debugPrint('📦 REPO: Fetching collections from local storage for trip: $tripId');
      
      final localCollections = await _localDataSource.getCollectionsByTripId(tripId);
      
      debugPrint('✅ REPO: Successfully loaded ${localCollections.length} collections from local storage');
      return Right(localCollections);

    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local fetch failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error in local fetch: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<CollectionEntity> getCollectionById(String collectionId) async {
    try {
      debugPrint('🔄 REPO: Fetching collection from remote by ID: $collectionId');
      
      // Try to fetch from remote first
      final remoteCollection = await _remoteDataSource.getCollectionById(collectionId);
      
      debugPrint('📥 REPO: Updating local storage with remote collection data');
      
      // Update local storage with the fetched data
      await _localDataSource.updateCollection(remoteCollection);
      
      debugPrint('✅ REPO: Successfully fetched and cached collection from remote');
      return Right(remoteCollection);

    } on ServerException catch (e) {
      debugPrint('⚠️ REPO: Remote fetch failed: ${e.message}');
      
      try {
        // Fallback to local data
        debugPrint('📦 REPO: Attempting to load collection from local storage');
        final localCollection = await _localDataSource.getCollectionById(collectionId);
        
        debugPrint('✅ REPO: Successfully loaded collection from cache');
        return Right(localCollection);

      } on CacheException catch (cacheError) {
        debugPrint('❌ REPO: Local fallback also failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: cacheError.statusCode));
      }

    } on CacheException catch (e) {
      debugPrint('❌ REPO: Cache operation failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<CollectionEntity> getLocalCollectionById(String collectionId) async {
    try {
      debugPrint('📦 REPO: Fetching collection from local storage by ID: $collectionId');
      
      final localCollection = await _localDataSource.getCollectionById(collectionId);
      
      debugPrint('✅ REPO: Successfully loaded collection from local storage');
      return Right(localCollection);

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
