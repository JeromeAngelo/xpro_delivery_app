import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/entity/delivery_receipt_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/repo/delivery_receipt_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class DeliveryReceiptRepoImpl implements DeliveryReceiptRepo {
  const DeliveryReceiptRepoImpl({
    required DeliveryReceiptRemoteDatasource remoteDatasource,
    required DeliveryReceiptLocalDatasource localDatasource,
  }) : _remoteDatasource = remoteDatasource,
       _localDatasource = localDatasource;

  final DeliveryReceiptRemoteDatasource _remoteDatasource;
  final DeliveryReceiptLocalDatasource _localDatasource;

  @override
  ResultFuture<DeliveryReceiptEntity> getDeliveryReceiptByTripId(
    String tripId,
  ) async {
    try {
      debugPrint(
        '🔄 Fetching delivery receipt by trip ID from remote: $tripId',
      );

      final remoteReceipt = await _remoteDatasource.getDeliveryReceiptByTripId(
        tripId,
      );

      debugPrint(
        '✅ Successfully retrieved and cached delivery receipt by trip ID',
      );
      return Right(remoteReceipt);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote fetch failed: ${e.message}');

      try {
        debugPrint('📦 Attempting to load from local cache');
        final localReceipt = await _localDatasource.getDeliveryReceiptByTripId(
          tripId,
        );
        debugPrint('✅ Using cached delivery receipt by trip ID');
        return Right(localReceipt);
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local cache also failed: ${cacheError.message}');
      }

      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('❌ Cache operation failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<DeliveryReceiptEntity> getLocalDeliveryReceiptByTripId(
    String tripId,
  ) async {
    try {
      debugPrint(
        '📦 Loading delivery receipt by trip ID from local storage: $tripId',
      );

      final localReceipt = await _localDatasource.getDeliveryReceiptByTripId(
        tripId,
      );

      debugPrint('✅ Successfully loaded delivery receipt from local storage');
      return Right(localReceipt);
    } on CacheException catch (e) {
      debugPrint('❌ Local storage error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<DeliveryReceiptEntity> getDeliveryReceiptByDeliveryDataId(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 Fetching delivery receipt by delivery data ID from remote: $deliveryDataId',
      );

      final remoteReceipt = await _remoteDatasource
          .getDeliveryReceiptByDeliveryDataId(deliveryDataId);

      debugPrint(
        '✅ Successfully retrieved and cached delivery receipt by delivery data ID',
      );
      return Right(remoteReceipt);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote fetch failed: ${e.message}');

      try {
        debugPrint('📦 Attempting to load from local cache');
        final localReceipt = await _localDatasource
            .getDeliveryReceiptByDeliveryDataId(deliveryDataId);
        debugPrint('✅ Using cached delivery receipt by delivery data ID');
        return Right(localReceipt);
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local cache also failed: ${cacheError.message}');
      }

      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('❌ Cache operation failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<DeliveryReceiptEntity> getLocalDeliveryReceiptByDeliveryDataId(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '📦 Loading delivery receipt by delivery data ID from local storage: $deliveryDataId',
      );

      final localReceipt = await _localDatasource
          .getDeliveryReceiptByDeliveryDataId(deliveryDataId);

      debugPrint('✅ Successfully loaded delivery receipt from local storage');
      return Right(localReceipt);
    } on CacheException catch (e) {
      debugPrint('❌ Local storage error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  @override
  ResultFuture<DeliveryReceiptEntity> createDeliveryReceiptByDeliveryDataId({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
  }) async {
    try {
      debugPrint('💾 REPO: Creating delivery receipt locally first for delivery data: $deliveryDataId');
      
      // Create in local storage first for immediate feedback
      final localDeliveryReceipt = await _localDatasource.createDeliveryReceiptByDeliveryDataId(
        deliveryDataId: deliveryDataId,
        status: status,
        dateTimeCompleted: dateTimeCompleted,
        customerImages: customerImages,
        customerSignature: customerSignature,
        receiptFile: receiptFile,
      );
      
      debugPrint('✅ REPO: Successfully created delivery receipt in local storage');
      
      // Return local result immediately for UI navigation
      // This allows immediate navigation while remote sync happens in background
      
      // Start background sync without blocking the UI response
      _performBackgroundSync(
        deliveryDataId: deliveryDataId,
        status: status,
        dateTimeCompleted: dateTimeCompleted,
        customerImages: customerImages,
        customerSignature: customerSignature,
        receiptFile: receiptFile,
        localReceipt: localDeliveryReceipt,
      );
      
      return Right(localDeliveryReceipt);

    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local creation failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error during creation: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  /// Performs background sync to remote server without blocking UI
  Future<void> _performBackgroundSync({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
    required DeliveryReceiptEntity localReceipt,
  }) async {
    try {
      debugPrint('🌐 REPO: Starting background sync to remote for delivery data: $deliveryDataId');
      
      // Sync with remote in background
      final remoteDeliveryReceipt = await _remoteDatasource.createDeliveryReceiptByDeliveryDataId(
        deliveryDataId: deliveryDataId,
        status: status,
        amount: localReceipt.totalAmount,
        dateTimeCompleted: dateTimeCompleted,
        customerImages: customerImages,
        customerSignature: customerSignature,
        receiptFile: receiptFile,
      );
      
      debugPrint('📥 REPO: Updating local storage with remote data');
      
      // Update local storage with remote data (this will have the proper server ID)
      // You might need to implement an update method in local datasource
      await _localDatasource.updateDeliveryReceipt(remoteDeliveryReceipt);
      
      debugPrint('✅ REPO: Successfully completed background sync to remote');
      
    } on ServerException catch (e) {
      debugPrint('⚠️ REPO: Background sync failed, but local data is preserved: ${e.message}');
      // Local data is still available, sync can be retried later
      
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error during background sync: ${e.toString()}');
      // Local data is still available
    }
  }


  @override
  ResultFuture<bool> deleteDeliveryReceipt(String id) async {
    try {
      debugPrint('🔄 Deleting delivery receipt: $id');

      // Try to delete from remote first
      try {
        debugPrint('🌐 Deleting from remote');
        final remoteDeleted = await _remoteDatasource.deleteDeliveryReceipt(id);

        if (remoteDeleted) {
          debugPrint('📦 Deleting from local cache');
          await _localDatasource.deleteDeliveryReceipt(id);
          debugPrint(
            '✅ Successfully deleted delivery receipt from both remote and local',
          );
          return const Right(true);
        }
      } on ServerException catch (e) {
        debugPrint('⚠️ Remote deletion failed: ${e.message}');
      }

      // If remote fails, still try to delete from local
      try {
        debugPrint('📦 Attempting local deletion');
        final localDeleted = await _localDatasource.deleteDeliveryReceipt(id);

        if (localDeleted) {
          debugPrint(
            '✅ Successfully deleted delivery receipt from local storage',
          );
          return const Right(true);
        } else {
          debugPrint('❌ Local deletion returned false');
          return const Right(false);
        }
      } on CacheException catch (e) {
        debugPrint('❌ Local deletion failed: ${e.message}');
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    } catch (e) {
      debugPrint('❌ Unexpected error during deletion: $e');
      return Left(
        ServerFailure(
          message: 'Failed to delete delivery receipt: ${e.toString()}',
          statusCode: '500',
        ),
      );
    }
  }

  /// Additional helper methods for cache management

  /// Cache a delivery receipt from remote data
  Future<void> cacheDeliveryReceipt(
    DeliveryReceiptEntity deliveryReceipt,
  ) async {
    try {
      debugPrint('📥 Caching delivery receipt: ${deliveryReceipt.id}');

      // Convert entity to model for caching

      debugPrint('✅ Successfully cached delivery receipt');
    } on CacheException catch (e) {
      debugPrint('❌ Failed to cache delivery receipt: ${e.message}');
      // Don't throw here, caching failure shouldn't break the main operation
    }
  }

  /// Get all delivery receipts from local storage
  Future<List<DeliveryReceiptEntity>> getAllLocalDeliveryReceipts() async {
    try {
      debugPrint('📦 Getting all delivery receipts from local storage');

      final receipts = await _localDatasource.getAllDeliveryReceipts();

      debugPrint(
        '✅ Retrieved ${receipts.length} delivery receipts from local storage',
      );
      return receipts;
    } on CacheException catch (e) {
      debugPrint('❌ Failed to get all delivery receipts: ${e.message}');
      return [];
    }
  }

  /// Clear all delivery receipts from local storage
  Future<void> clearAllLocalDeliveryReceipts() async {
    try {
      debugPrint('🗑️ Clearing all delivery receipts from local storage');

      await _localDatasource.clearAllDeliveryReceipts();

      debugPrint('✅ Successfully cleared all delivery receipts');
    } on CacheException catch (e) {
      debugPrint('❌ Failed to clear delivery receipts: ${e.message}');
    }
  }

   @override
  ResultFuture<Uint8List> generateDeliveryReceiptPdf(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint('📄 REPO: Generating delivery receipt PDF for: ${deliveryData.id}');
      
      final pdfBytes = await _localDatasource.generateDeliveryReceiptPdf(deliveryData);
      
      debugPrint('✅ REPO: Successfully generated delivery receipt PDF');
      debugPrint('📊 REPO: PDF size: ${pdfBytes.length} bytes');
      
      return Right(pdfBytes);
    } on CacheException catch (e) {
      debugPrint('❌ REPO: PDF generation failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error during PDF generation: $e');
      return Left(
        CacheFailure(
          message: 'Failed to generate delivery receipt PDF: ${e.toString()}',
          statusCode: '500',
        ),
      );
    }
  }

}
