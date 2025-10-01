import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_status/data/datasources/local_datasource/invoice_status_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_status/data/datasources/remote_datasource/invoice_status_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_status/domain/entity/invoice_status_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_status/domain/repo/invoice_status_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class InvoiceStatusRepoImpl implements InvoiceStatusRepo {
  const InvoiceStatusRepoImpl({
    required InvoiceStatusRemoteDataSource remoteDataSource,
    required InvoiceStatusLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final InvoiceStatusRemoteDataSource _remoteDataSource;
  final InvoiceStatusLocalDataSource _localDataSource;

  @override
  ResultFuture<List<InvoiceStatusEntity>> getInvoiceStatusByInvoiceId(String invoiceId) async {
    try {
      debugPrint('🌐 Fetching invoice status for invoice: $invoiceId');
      
      // Try to get from remote first
      try {
        final remoteInvoiceStatus = await _remoteDataSource.getInvoiceStatusByInvoiceId(invoiceId);
        debugPrint('✅ Retrieved ${remoteInvoiceStatus.length} invoice status records from remote');
        
        // Cache the data locally
        await _localDataSource.cacheInvoiceStatus(remoteInvoiceStatus);
        
        return Right(remoteInvoiceStatus);
      } on ServerException catch (e) {
        debugPrint('⚠️ Remote fetch failed, trying local cache: ${e.message}');
        
        // If remote fails, try local cache
        try {
          final localInvoiceStatus = await _localDataSource.getInvoiceStatusByInvoiceId(invoiceId);
          debugPrint('✅ Retrieved ${localInvoiceStatus.length} invoice status records from local cache');
          return Right(localInvoiceStatus);
        } on CacheException catch (localError) {
          debugPrint('❌ Both remote and local failed: ${localError.message}');
          return Left(ServerFailure(
            message: 'Failed to load invoice status: ${e.message}',
            statusCode: e.statusCode,
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Unexpected error: ${e.toString()}');
      return Left(ServerFailure(
        message: 'Unexpected error loading invoice status: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }
}
