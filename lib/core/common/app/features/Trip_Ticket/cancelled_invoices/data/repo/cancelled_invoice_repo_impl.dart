import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/repo/cancelled_invoice_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../model/cancelled_invoice_model.dart' show CancelledInvoiceModel;

class CancelledInvoiceRepoImpl implements CancelledInvoiceRepo {
  const CancelledInvoiceRepoImpl({
    required CancelledInvoiceRemoteDataSource remoteDataSource,
    required CancelledInvoiceLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final CancelledInvoiceRemoteDataSource _remoteDataSource;
  final CancelledInvoiceLocalDataSource _localDataSource;

  @override
  ResultFuture<List<CancelledInvoiceEntity>> loadCancelledInvoicesByTripId(String tripId) async {
    try {
      debugPrint('🌐 REPO: Loading cancelled invoices from remote for trip: $tripId');
      
      final remoteCancelledInvoices = await _remoteDataSource.loadCancelledInvoicesByTripId(tripId);
      
      debugPrint('📥 REPO: Caching ${remoteCancelledInvoices.length} cancelled invoices to local storage');
      await _localDataSource.cacheCancelledInvoices(remoteCancelledInvoices);
      
      debugPrint('✅ REPO: Successfully loaded and cached cancelled invoices from remote');
      return Right(remoteCancelledInvoices);
    } on ServerException catch (e) {
      debugPrint('⚠️ REPO: Remote fetch failed: ${e.message}');
      
      try {
        debugPrint('🔍 REPO: Attempting to load from local storage');
        final localCancelledInvoices = await _localDataSource.loadCancelledInvoicesByTripId(tripId);
        debugPrint('📱 REPO: Successfully loaded ${localCancelledInvoices.length} cancelled invoices from local storage');
        return Right(localCancelledInvoices);
      } on CacheException catch (cacheError) {
        debugPrint('❌ REPO: Local fetch also failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 404));
      }
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<CancelledInvoiceEntity>> loadLocalCancelledInvoicesByTripId(String tripId) async {
    try {
      debugPrint('📱 REPO: Loading cancelled invoices from local storage for trip: $tripId');
      
      final localCancelledInvoices = await _localDataSource.loadCancelledInvoicesByTripId(tripId);
      
      debugPrint('✅ REPO: Successfully loaded ${localCancelledInvoices.length} cancelled invoices from local storage');
      return Right(localCancelledInvoices);
    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local storage error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 404));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: '500'));
    }
  } 
  
   @override
  ResultFuture<CancelledInvoiceEntity> createCancelledInvoice(
    CancelledInvoiceEntity cancelledInvoice,
    String deliveryDataId,
  ) async {
    try {
      debugPrint('💾 REPO: Creating cancelled invoice locally first for delivery data: $deliveryDataId');
      debugPrint('📝 REPO: Reason: ${cancelledInvoice.reason.toString().split('.').last}');
      
      // Convert entity to model for local storage
      final cancelledInvoiceModel = CancelledInvoiceModel.fromEntity(cancelledInvoice);
      
      // Create in local storage first
      final localCancelledInvoice = await _localDataSource.createCancelledInvoice(
        cancelledInvoiceModel,
        deliveryDataId,
      );
      
      debugPrint('✅ REPO: Successfully created cancelled invoice in local storage');
      
      // Start background sync without waiting for it to complete
      _syncToRemoteInBackground(localCancelledInvoice, deliveryDataId);
      
      // Return immediately with local data for instant UI response
      return Right(localCancelledInvoice);
      
    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local creation failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error during creation: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  /// Background sync to remote - fire and forget
  void _syncToRemoteInBackground(
    CancelledInvoiceEntity localCancelledInvoice,
    String deliveryDataId,
  ) {
    // Use Future.microtask to ensure this runs asynchronously
    Future.microtask(() async {
      try {
        debugPrint('🌐 REPO: Starting background sync to remote');
        
        // Convert to model for remote sync
        final modelForSync = CancelledInvoiceModel.fromEntity(localCancelledInvoice);
        
        // Sync with remote
        final remoteCancelledInvoice = await _remoteDataSource.createCancelledInvoice(
          modelForSync,
          deliveryDataId,
        );
        
        debugPrint('📥 REPO: Updating local storage with remote data');
        await _localDataSource.updateCancelledInvoice(remoteCancelledInvoice);
        
        debugPrint('✅ REPO: Successfully synced cancelled invoice to remote');
      } on ServerException catch (e) {
        debugPrint('⚠️ REPO: Background sync failed: ${e.message}');
        // Could emit a sync failure event here if needed
      } catch (e) {
        debugPrint('❌ REPO: Background sync error: ${e.toString()}');
      }
    });
  }


  @override
  ResultFuture<bool> deleteCancelledInvoice(String cancelledInvoiceId) async {
    try {
      debugPrint('🗑️ REPO: Deleting cancelled invoice: $cancelledInvoiceId');
      
      // Delete from remote first
      try {
        debugPrint('🌐 REPO: Deleting from remote');
        final remoteSuccess = await _remoteDataSource.deleteCancelledInvoice(cancelledInvoiceId);
        
        if (remoteSuccess) {
          debugPrint('📱 REPO: Deleting from local storage');
          await _localDataSource.deleteCancelledInvoice(cancelledInvoiceId);
          debugPrint('✅ REPO: Successfully deleted cancelled invoice from both remote and local');
          return const Right(true);
        } else {
          debugPrint('⚠️ REPO: Remote deletion returned false');
          return Left(ServerFailure(message: 'Failed to delete from remote', statusCode: '500'));
        }
      } on ServerException catch (e) {
        debugPrint('⚠️ REPO: Remote deletion failed: ${e.message}');
        
        // Try local deletion anyway
        try {
          debugPrint('📱 REPO: Attempting local deletion only');
          final localSuccess = await _localDataSource.deleteCancelledInvoice(cancelledInvoiceId);
          
          if (localSuccess) {
            debugPrint('✅ REPO: Successfully deleted from local storage (remote failed)');
            return const Right(true);
          } else {
            debugPrint('❌ REPO: Local deletion also failed');
            return Left(CacheFailure(message: 'Failed to delete from local storage', statusCode: 404));
          }
        } on CacheException catch (cacheError) {
          debugPrint('❌ REPO: Local deletion failed: ${cacheError.message}');
          return Left(CacheFailure(message: cacheError.message, statusCode: cacheError.statusCode));
        }
      }
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error during deletion: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
  
    @override
  ResultFuture<CancelledInvoiceEntity> loadCancelledInvoicesById(String id) async {
    try {
      debugPrint('🌐 REPO: Loading cancelled invoice from remote by ID: $id');
      
      final remoteCancelledInvoices = await _remoteDataSource.loadCancelledInvoiceById(id);
      
      debugPrint('📥 REPO: Caching cancelled invoice to local storage');
     // await _localDataSource.cacheCancelledInvoices(remoteCancelledInvoices);
      
      debugPrint('✅ REPO: Successfully loaded and cached cancelled invoice from remote');
      return Right(remoteCancelledInvoices);
    } on ServerException catch (e) {
      debugPrint('⚠️ REPO: Remote fetch failed: ${e.message}');
      
      try {
        debugPrint('🔍 REPO: Attempting to load from local storage');
        final localCancelledInvoices = await _localDataSource.loadCancelledInvoicesById(id);
        debugPrint('📱 REPO: Successfully loaded cancelled invoice from local storage');
        return Right(localCancelledInvoices);
      } on CacheException catch (cacheError) {
        debugPrint('❌ REPO: Local fetch also failed: ${cacheError.message}');
        return Left(CacheFailure(message: cacheError.message, statusCode: 404));
      }
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<CancelledInvoiceEntity> loadLocalCancelledInvoicesById(String id) async {
    try {
      debugPrint('📱 REPO: Loading cancelled invoice from local storage by ID: $id');
      
      final localCancelledInvoices = await _localDataSource.loadCancelledInvoicesById(id);
      
      debugPrint('✅ REPO: Successfully loaded cancelled invoice from local storage');
      return Right(localCancelledInvoices);
    } on CacheException catch (e) {
      debugPrint('❌ REPO: Local storage error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: 404));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: ${e.toString()}');
      return Left(CacheFailure(message: e.toString(), statusCode: '500'));
    }
  }

}
