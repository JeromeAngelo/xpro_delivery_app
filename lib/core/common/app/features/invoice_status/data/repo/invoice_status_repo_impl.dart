import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/invoice_status/data/datasource/remote_datasource/invoice_status_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/invoice_status/domain/entity/invoice_status_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/invoice_status/domain/repo/invoice_status_repo.dart'
    show InvoiceStatusRepo;
import 'package:xpro_delivery_admin_app/core/errors/failures.dart'
    show ServerFailure;
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

import '../../../../../../errors/exceptions.dart';

class InvoiceStatusRepoImpl implements InvoiceStatusRepo {
  const InvoiceStatusRepoImpl(this._remoteDatasource);

  final InvoiceStatusRemoteDatasource _remoteDatasource;

  @override
  ResultFuture<List<int>> exportInvoiceStatusesCsvBytes() async {
    try {
      debugPrint('🌐 Exporting invoice statuses as CSV bytes');
      final csvBytes = await _remoteDatasource.exportInvoiceStatusesCsvBytes();
      return Right(csvBytes);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<int>> exportInvoiceStatusesExcelBytes() async {
   try {
      debugPrint('🌐 Exporting invoice statuses as Excel bytes');
      final excelBytes = await _remoteDatasource.exportInvoiceStatusesExcelBytes();
      return Right(excelBytes);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<InvoiceStatusEntity>> getAllInvoiceStatuses() async {
    try {
      debugPrint('🌐 Fetching all invoice statuses from remote');
      final remoteList = await _remoteDatasource.getAllInvoiceStatuses();
      return Right(remoteList);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<InvoiceStatusEntity> getInvoiceStatusById(String id) async {
    try {
      debugPrint('🌐 Fetching invoice status by ID: $id');
      final remoteEntity = await _remoteDatasource.getInvoiceStatusById(id);
      return Right(remoteEntity);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
