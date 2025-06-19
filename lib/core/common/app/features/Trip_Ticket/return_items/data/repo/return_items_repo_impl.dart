import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/data/datasource/local_datasource/return_items_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/data/datasource/remote_datasource/return_items_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/data/model/return_items_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/domain/entity/return_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/domain/repo/return_items_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../../errors/failures.dart';

class ReturnItemsRepoImpl implements ReturnItemsRepo {
  const ReturnItemsRepoImpl({
    required ReturnItemsRemoteDataSource remoteDataSource,
    required ReturnItemsLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ReturnItemsRemoteDataSource _remoteDataSource;
  final ReturnItemsLocalDataSource _localDataSource;

  @override
  ResultFuture<List<ReturnItemsEntity>> getReturnItemsByTripId(String tripId) async {
    try {
      debugPrint('🔄 REPO: Fetching return items for trip ID: $tripId');

      // Try to get from remote first
      final remoteReturnItems = await _remoteDataSource.getReturnItemsByTripId(tripId);
      
      debugPrint('✅ REPO: Retrieved ${remoteReturnItems.length} return items from remote');

      // Sync to local storage
      await _localDataSource.syncReturnItemsByTripId(tripId, remoteReturnItems);
      
      debugPrint('💾 REPO: Synced return items to local storage');

      // Return the remote data as entities
      final entities = remoteReturnItems.cast<ReturnItemsEntity>();
      
      debugPrint('✅ REPO: Successfully processed ${entities.length} return items');
      
      return Right(entities);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error, trying local fallback: ${e.message}');
      
      try {
        // Fallback to local data
        final localReturnItems = await _localDataSource.getReturnItemsByTripId(tripId);
        
        debugPrint('📱 REPO: Retrieved ${localReturnItems.length} return items from local storage');
        
        final entities = localReturnItems.cast<ReturnItemsEntity>();
        return Right(entities);
      } on CacheException catch (cacheError) {
        debugPrint('❌ REPO: Local fallback failed: ${cacheError.message}');
        return Left(CacheFailure(
          message: 'Failed to get return items: ${e.message}. Local fallback: ${cacheError.message}',
          statusCode: e.statusCode,
        ));
      }
    } on CacheException catch (e) {
      debugPrint('❌ REPO: Cache error: ${e.message}');
      return Left(CacheFailure(
        message: e.message,
        statusCode: '500',
      ));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
      return Left(ServerFailure(
        message: 'Unexpected error occurred: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }

  @override
  ResultFuture<ReturnItemsEntity> getReturnItemById(String returnItemId) async {
    try {
      debugPrint('🔄 REPO: Fetching return item with ID: $returnItemId');

      // Try to get from remote first
      final remoteReturnItem = await _remoteDataSource.getReturnItemById(returnItemId);
      
      debugPrint('✅ REPO: Retrieved return item from remote: ${remoteReturnItem.id}');

      // Update local storage
      await _localDataSource.updateReturnItem(remoteReturnItem);
      
      debugPrint('💾 REPO: Updated return item in local storage');

      // Return as entity
      final entity = remoteReturnItem as ReturnItemsEntity;
      
      debugPrint('✅ REPO: Successfully processed return item: ${entity.id}');
      
      return Right(entity);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error, trying local fallback: ${e.message}');
      
      try {
        // Fallback to local data
        final localReturnItem = await _localDataSource.getReturnItemById(returnItemId);
        
        debugPrint('📱 REPO: Retrieved return item from local storage: ${localReturnItem.id}');
        
        final entity = localReturnItem as ReturnItemsEntity;
        return Right(entity);
      } on CacheException catch (cacheError) {
        debugPrint('❌ REPO: Local fallback failed: ${cacheError.message}');
        return Left(CacheFailure(
          message: 'Failed to get return item: ${e.message}. Local fallback: ${cacheError.message}',
          statusCode: e.statusCode,
        ));
      }
    } on CacheException catch (e) {
      debugPrint('❌ REPO: Cache error: ${e.message}');
      return Left(CacheFailure(
        message: e.message,
        statusCode: '500',
      ));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
      return Left(ServerFailure(
        message: 'Unexpected error occurred: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }

  @override
  ResultFuture<ReturnItemsEntity> addItemsToReturnItemsByDeliveryId(
    String deliveryId,
    ReturnItemsEntity returnItem,
  ) async {
    try {
      debugPrint('🔄 REPO: Adding return item to delivery ID: $deliveryId');

      // Convert entity to model for remote operation
      final returnItemModel = _convertEntityToModel(returnItem);
      
      debugPrint('📤 REPO: Converted entity to model for remote operation');

      // Add to remote
      final createdReturnItem = await _remoteDataSource.addItemsToReturnItemsByDeliveryId(
        deliveryId,
        returnItemModel,
      );
      
      debugPrint('✅ REPO: Created return item remotely: ${createdReturnItem.id}');

      // Add to local storage
      await _localDataSource.addReturnItem(createdReturnItem);
      
      debugPrint('💾 REPO: Added return item to local storage');

      // Return as entity
      final entity = createdReturnItem as ReturnItemsEntity;
      
      debugPrint('✅ REPO: Successfully processed created return item: ${entity.id}');
      
      return Right(entity);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error while adding return item: ${e.message}');
      return Left(ServerFailure(
        message: 'Failed to add return item: ${e.message}',
        statusCode: e.statusCode,
      ));
    } on CacheException catch (e) {
      debugPrint('❌ REPO: Cache error while adding return item: ${e.message}');
      return Left(CacheFailure(
        message: 'Failed to cache return item: ${e.message}',
        statusCode: '500',
      ));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error while adding return item: ${e.toString()}');
      return Left(ServerFailure(
        message: 'Unexpected error occurred: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }

  @override
  ResultFuture<List<ReturnItemsEntity>> loadLocalReturnItemsByTripId(String tripId) async {
    try {
      debugPrint('📱 REPO: Loading return items from local storage for trip ID: $tripId');

      final localReturnItems = await _localDataSource.getReturnItemsByTripId(tripId);
      
      debugPrint('✅ REPO: Retrieved ${localReturnItems.length} return items from local storage');

      // Convert to entities
      final entities = localReturnItems.cast<ReturnItemsEntity>();
      
      debugPrint('✅ REPO: Successfully processed ${entities.length} local return items');
      
      return Right(entities);
    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local storage error: ${e.message}');
      return Left(CacheFailure(
        message: e.message,
        statusCode: '500',
      ));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error loading local return items: ${e.toString()}');
      return Left(CacheFailure(
        message: 'Unexpected error occurred: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }

  @override
  ResultFuture<ReturnItemsEntity> getReturnItemByLocalById(String returnItemId) async {
    try {
      debugPrint('📱 REPO: Loading return item from local storage with ID: $returnItemId');

      final localReturnItem = await _localDataSource.getReturnItemById(returnItemId);
      
      debugPrint('✅ REPO: Retrieved return item from local storage: ${localReturnItem.id}');

      // Convert to entity
      final entity = localReturnItem as ReturnItemsEntity;
      
      debugPrint('✅ REPO: Successfully processed local return item: ${entity.id}');
      
      return Right(entity);
    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local storage error: ${e.message}');
      return Left(CacheFailure(
        message: e.message,
        statusCode: '500',
      ));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error loading local return item: ${e.toString()}');
      return Left(CacheFailure(
        message: 'Unexpected error occurred: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }

  /// Helper method to convert entity to model
  ReturnItemsModel _convertEntityToModel(ReturnItemsEntity entity) {
    try {
      debugPrint('🔄 REPO: Converting entity to model');

      final model = ReturnItemsModel(
        id: entity.id,
        collectionId: entity.collectionId,
        collectionName: entity.collectionName,
        refId: entity.refId,
        quantity: entity.quantity,
        uom: entity.uom,
        reason: entity.reason,
        created: entity.created,
        updated: entity.updated,
      );

      // Handle relations - convert targets if they exist
      if (entity.trip.target != null) {
        model.trip.target = entity.trip.target;
      }
      
      if (entity.deliveryData.target != null) {
        model.deliveryData.target = entity.deliveryData.target;
      }
      
      if (entity.invoiceItem.target != null) {
        model.invoiceItem.target = entity.invoiceItem.target;
      }
      
      if (entity.invoiceData.target != null) {
        model.invoiceData.target = entity.invoiceData.target;
      }

      debugPrint('✅ REPO: Successfully converted entity to model');
      return model;
    } catch (e) {
      debugPrint('❌ REPO: Error converting entity to model: ${e.toString()}');
      rethrow;
    }
  }

  /// Helper method to sync return items for a trip
  Future<void> syncReturnItemsForTrip(String tripId) async {
    try {
      debugPrint('🔄 REPO: Syncing return items for trip: $tripId');

      final remoteReturnItems = await _remoteDataSource.getReturnItemsByTripId(tripId);
      await _localDataSource.syncReturnItemsByTripId(tripId, remoteReturnItems);

      debugPrint('✅ REPO: Successfully synced ${remoteReturnItems.length} return items for trip: $tripId');
    } catch (e) {
      debugPrint('❌ REPO: Failed to sync return items for trip $tripId: ${e.toString()}');
      rethrow;
    }
  }

 
}
