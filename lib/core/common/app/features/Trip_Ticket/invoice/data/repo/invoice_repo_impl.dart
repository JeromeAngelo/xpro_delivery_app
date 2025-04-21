import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/datasource/remote_data_source/invoice_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/datasource/local_datasource/invoice_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/repo/invoice_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class InvoiceRepoImpl extends InvoiceRepo {
  const InvoiceRepoImpl(this._remoteDataSource, this._localDataSource);

  final InvoiceRemoteDatasource _remoteDataSource;
  final InvoiceLocalDatasource _localDataSource;

  @override
  ResultFuture<List<InvoiceEntity>> getInvoices() async {
    try {
      debugPrint('🔄 Fetching invoices from remote source...');
      final remoteInvoices = await _remoteDataSource.getInvoices();

      debugPrint(
        '📥 Starting sync for ${remoteInvoices.length} remote invoices',
      );

      await _localDataSource.cleanupInvalidEntries();

      for (var invoice in remoteInvoices) {
        if (invoice.pocketbaseId.isNotEmpty) {
          debugPrint('💾 Syncing valid invoice: ${invoice.invoiceNumber}');
          await _localDataSource.updateInvoice(invoice);
        }
      }

      debugPrint(
        '✅ Sync completed with ${remoteInvoices.length} valid invoices',
      );
      return Right(remoteInvoices);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');

      final localInvoices = await _localDataSource.getInvoices();
      if (localInvoices.isNotEmpty) {
        debugPrint('📦 Using ${localInvoices.length} invoices from cache');
        return Right(localInvoices);
      }

      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<InvoiceEntity>> loadLocalInvoices() async {
    try {
      debugPrint('📂 Loading invoices from local storage');
      final localInvoices = await _localDataSource.getInvoices();
      debugPrint('✅ Loaded ${localInvoices.length} invoices from cache');
      return Right(localInvoices);
    } on CacheException catch (e) {
      debugPrint('❌ Local cache retrieval failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<InvoiceEntity>> getInvoicesByCustomerId(
    String customerId,
  ) async {
    try {
      debugPrint('🔄 Fetching customer invoices from remote: $customerId');
      final remoteInvoices = await _remoteDataSource.getInvoicesByCustomerId(
        customerId,
      );

      for (var invoice in remoteInvoices) {
        await _localDataSource.updateInvoice(invoice);
      }

      return Right(remoteInvoices);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<InvoiceEntity>> getInvoicesByTripId(String tripId) async {
    try {
      debugPrint('🔄 Fetching trip invoices from remote: $tripId');
      final remoteInvoices = await _remoteDataSource.getInvoicesByTripId(
        tripId,
      );

      for (var invoice in remoteInvoices) {
        await _localDataSource.updateInvoice(invoice);
      }

      return Right(remoteInvoices);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<InvoiceEntity>> loadLocalInvoicesByCustomerId(
    String customerId,
  ) async {
    try {
      debugPrint('📂 Loading local invoices for customer: $customerId');
      final localInvoices = await _localDataSource.getInvoicesByCustomerId(
        customerId,
      );
      return Right(localInvoices);
    } on CacheException catch (e) {
      debugPrint('❌ Local fetch failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<InvoiceEntity>> loadLocalInvoicesByTripId(
    String tripId,
  ) async {
    try {
      debugPrint('📂 Loading local invoices for trip: $tripId');
      final localInvoices = await _localDataSource.getInvoicesByTripId(tripId);
      return Right(localInvoices);
    } on CacheException catch (e) {
      debugPrint('❌ Local fetch failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

 @override
ResultFuture<List<InvoiceEntity>> setAllInvoicesCompleted(String tripId) async {
  try {
    debugPrint('🔄 REPO: Setting all invoices to completed for trip: $tripId');
    
    // First try to update invoices in remote database
    List<InvoiceEntity> remoteInvoices = [];
    try {
      remoteInvoices = await _remoteDataSource.setAllInvoicesCompleted(tripId);
      debugPrint('✅ REPO: Successfully updated ${remoteInvoices.length} invoices in remote database');
      
      // If remote update is successful, also update local database to keep in sync
      if (remoteInvoices.isNotEmpty) {
        await _localDataSource.setAllInvoicesCompleted(tripId);
        debugPrint('✅ REPO: Synced remote changes to local database');
      }
    } on ServerException catch (e) {
      debugPrint('⚠️ REPO: Remote update failed: ${e.message}. Falling back to local update.');
      
      // If remote update fails, try to update local database only
      final localInvoices = await _localDataSource.setAllInvoicesCompleted(tripId);
      debugPrint('✅ REPO: Updated ${localInvoices.length} invoices in local database only');
      
      // Return local invoices if remote update failed
      if (localInvoices.isNotEmpty) {
        return Right(localInvoices);
      }
      
      // If both remote and local updates failed, throw the original error
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
    
    return Right(remoteInvoices);
  } on CacheException catch (e) {
    debugPrint('❌ REPO: Cache error setting invoices to completed: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    debugPrint('❌ REPO: Unexpected error setting invoices to completed: $e');
    return Left(ServerFailure(message: e.toString(), statusCode: '500'));
  }
}

}
