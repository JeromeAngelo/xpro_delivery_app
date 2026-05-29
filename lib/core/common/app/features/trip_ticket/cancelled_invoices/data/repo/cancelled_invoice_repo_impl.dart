import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_datasource/cancelled_invoice_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_datasource/cancelled_invoice_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/repo/cancelled_invoice_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../../enums/sync_status_enums.dart';
import '../datasources/sync_worker/cancelled_invoice_worker.dart';
import '../model/cancelled_invoice_model.dart' show CancelledInvoiceModel;

class CancelledInvoiceRepoImpl implements CancelledInvoiceRepo {
  const CancelledInvoiceRepoImpl({
    required CancelledInvoiceRemoteDataSource remoteDataSource,
    required CancelledInvoiceLocalDataSource localDataSource,
    required CancelledInvoiceSyncWorker syncWorker,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _syncWorker = syncWorker;

  final CancelledInvoiceRemoteDataSource _remoteDataSource;
  final CancelledInvoiceLocalDataSource _localDataSource;
  final CancelledInvoiceSyncWorker _syncWorker;
  @override
  ResultFuture<List<CancelledInvoiceEntity>> loadCancelledInvoicesByTripId(
    String tripId,
  ) async {
    debugPrint('🔍 REPO: loadCancelledInvoicesByTripId($tripId) called');

    // ---------------------------------------------------
    // 1️⃣ LOCAL FIRST (offline-first)
    // ---------------------------------------------------
    try {
      debugPrint(
        '📦 REPO: Checking local cancelled invoices for trip: $tripId',
      );

      final localCancelled = await _localDataSource
          .forceLoadCancelledInvoicesByTripId(tripId);

      if (localCancelled.isNotEmpty) {
        debugPrint(
          '✅ REPO: Local cancelled invoices found → ${localCancelled.length}',
        );

        // 👀 Activate watcher (ObjectBox stream)
        // _localDataSource.watchCancelledInvoicesByTripId(tripId);

        return Right(localCancelled);
      } else {
        debugPrint('⚠️ REPO: Local cancelled invoices empty');
      }
    } catch (e) {
      debugPrint('⚠️ REPO: Local lookup failed: $e');
    }

    // ---------------------------------------------------
    // 2️⃣ REMOTE FALLBACK
    // ---------------------------------------------------
    try {
      debugPrint(
        '🌐 REPO: Fetching cancelled invoices remotely for trip: $tripId',
      );

      final remoteCancelled = await _remoteDataSource
          .loadCancelledInvoicesByTripId(tripId);

      debugPrint(
        '✅ REPO: Remote cancelled invoices retrieved → '
        '${remoteCancelled.length}',
      );

      // ❌ NO WATCHER HERE
      // ❌ NO MANUAL CACHE CALL
      // Remote sync → ObjectBox put() → watcher emits automatically

      return Right(remoteCancelled);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: $e');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<CancelledInvoiceEntity>> loadLocalCancelledInvoicesByTripId(
    String tripId,
  ) async {
    debugPrint('🔍 REPO: loadLocalCancelledInvoicesByTripId($tripId) called');

    // ---------------------------------------------------
    // 1️⃣ LOCAL FIRST
    // ---------------------------------------------------
    try {
      debugPrint(
        '📦 REPO: Checking local cancelled invoices for trip: $tripId',
      );

      final localCancelled = await _localDataSource
          .loadCancelledInvoicesByTripId(tripId);

      if (localCancelled.isNotEmpty) {
        debugPrint(
          '✅ REPO: Local cancelled invoices found → ${localCancelled.length}',
        );

        // 👀 Start watching local changes
        // _localDataSource.watchCancelledInvoicesByTripId(tripId);

        return Right(localCancelled);
      } else {
        debugPrint('⚠️ REPO: Local cancelled invoices empty');
      }
    } catch (e) {
      debugPrint('⚠️ REPO: Local lookup failed: $e');
    }

    // ---------------------------------------------------
    // 2️⃣ REMOTE FALLBACK (SAFE)
    // ---------------------------------------------------
    try {
      debugPrint('🌐 REPO: Local empty → fetching cancelled invoices remotely');

      final remoteCancelled = await _remoteDataSource
          .loadCancelledInvoicesByTripId(tripId);

      debugPrint(
        '✅ REPO: Remote cancelled invoices retrieved → '
        '${remoteCancelled.length}',
      );

      // ❌ No manual cache
      // Remote sync → ObjectBox put() → watcher emits automatically

      return Right(remoteCancelled);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error: $e');
      return Left(CacheFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<CancelledInvoiceEntity> createCancelledInvoice(
    CancelledInvoiceEntity cancelledInvoice,
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '💾 REPO: Creating cancelled invoice locally first for deliveryDataId=$deliveryDataId',
      );
      debugPrint(
        '📝 REPO: Reason: ${cancelledInvoice.reason.toString().split('.').last}',
      );

      // ---------------------------------------------------
      // 1️⃣ Convert entity → model
      // ---------------------------------------------------
     
    // ---------------------------------------------------
    // 1️⃣ Convert ENTITY → MODEL (SAFE)
    // ---------------------------------------------------
    final CancelledInvoiceModel invoiceModel =
        cancelledInvoice is CancelledInvoiceModel
            ? cancelledInvoice
            : CancelledInvoiceModel.fromEntity(cancelledInvoice);


      // ---------------------------------------------------
      // 2️⃣ Create LOCAL record (offline-first)
      // ---------------------------------------------------
      final localInvoice = await _localDataSource.createCancelledInvoice(
       invoiceModel,
        deliveryDataId,
      );

      // ---------------------------------------------------
      // 3️⃣ Mark as PENDING for sync
      // ---------------------------------------------------
      final pendingInvoice = localInvoice.copyWith(
        syncStatus: SyncStatus.pending.name,
        retryCount: 0,
       
      );

      _localDataSource.cancelledInvoiceBox.put(pendingInvoice);

      debugPrint('🟡 REPO: Cancelled invoice queued for background sync');

      // ---------------------------------------------------
      // 4️⃣ Start background worker
      // ---------------------------------------------------
      _syncWorker.start();

      debugPrint('✅ REPO: Local cancelled invoice created successfully');

      // ---------------------------------------------------
      // 5️⃣ Return immediately (UI-friendly)
      // ---------------------------------------------------
      return Right(pendingInvoice);
    } on CacheException catch (e, st) {
      debugPrint('❌ REPO: Local creation failed: ${e.message}');
      debugPrint('❌ Failed to create cancelled invoice');
      debugPrint('❌ Error: $e');
      debugPrint('📌 Stack trace:\n$st');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error during creation: $e');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }


  @override
  ResultFuture<bool> deleteCancelledInvoice(String cancelledInvoiceId) async {
    try {
      debugPrint('🗑️ REPO: Deleting cancelled invoice: $cancelledInvoiceId');

      // Delete from remote first
      try {
        debugPrint('🌐 REPO: Deleting from remote');
        final remoteSuccess = await _remoteDataSource.deleteCancelledInvoice(
          cancelledInvoiceId,
        );

        if (remoteSuccess) {
          debugPrint('📱 REPO: Deleting from local storage');
          await _localDataSource.deleteCancelledInvoice(cancelledInvoiceId);
          debugPrint(
            '✅ REPO: Successfully deleted cancelled invoice from both remote and local',
          );
          return const Right(true);
        } else {
          debugPrint('⚠️ REPO: Remote deletion returned false');
          return Left(
            ServerFailure(
              message: 'Failed to delete from remote',
              statusCode: '500',
            ),
          );
        }
      } on ServerException catch (e) {
        debugPrint('⚠️ REPO: Remote deletion failed: ${e.message}');

        // Try local deletion anyway
        try {
          debugPrint('📱 REPO: Attempting local deletion only');
          final localSuccess = await _localDataSource.deleteCancelledInvoice(
            cancelledInvoiceId,
          );

          if (localSuccess) {
            debugPrint(
              '✅ REPO: Successfully deleted from local storage (remote failed)',
            );
            return const Right(true);
          } else {
            debugPrint('❌ REPO: Local deletion also failed');
            return Left(
              CacheFailure(
                message: 'Failed to delete from local storage',
                statusCode: 404,
              ),
            );
          }
        } on CacheException catch (cacheError) {
          debugPrint('❌ REPO: Local deletion failed: ${cacheError.message}');
          return Left(
            CacheFailure(
              message: cacheError.message,
              statusCode: cacheError.statusCode,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error during deletion: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<CancelledInvoiceEntity> loadCancelledInvoicesById(
    String id,
  ) async {
    try {
      debugPrint('🌐 REPO: Loading cancelled invoice from remote by ID: $id');

      final remoteCancelledInvoices = await _remoteDataSource
          .loadCancelledInvoiceById(id);

      debugPrint('📥 REPO: Caching cancelled invoice to local storage');
      // await _localDataSource.cacheCancelledInvoices(remoteCancelledInvoices);

      debugPrint(
        '✅ REPO: Successfully loaded and cached cancelled invoice from remote',
      );
      return Right(remoteCancelledInvoices);
    } on ServerException catch (e) {
      debugPrint('⚠️ REPO: Remote fetch failed: ${e.message}');

      try {
        debugPrint('🔍 REPO: Attempting to load from local storage');
        final localCancelledInvoices = await _localDataSource
            .loadCancelledInvoicesById(id);
        debugPrint(
          '📱 REPO: Successfully loaded cancelled invoice from local storage',
        );
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
  ResultFuture<CancelledInvoiceEntity> loadLocalCancelledInvoicesById(
    String id,
  ) async {
    try {
      debugPrint(
        '📱 REPO: Loading cancelled invoice from local storage by ID: $id',
      );

      final localCancelledInvoices = await _localDataSource
          .loadCancelledInvoicesById(id);

      debugPrint(
        '✅ REPO: Successfully loaded cancelled invoice from local storage',
      );
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
