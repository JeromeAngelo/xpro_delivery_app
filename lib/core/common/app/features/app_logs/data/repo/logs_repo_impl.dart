import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/data/datasource/local_datasource/logs_local_datasource/logs_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/data/datasource/remote_datasource/logs_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/data/model/log_entry_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';

class LogsRepoImpl implements LogsRepo {
  const LogsRepoImpl({
    required LogsLocalDatasource logsLocalDatasource,
    required LogsRemoteDataSource logsRemoteDataSource,
  }) : _logsLocalDatasource = logsLocalDatasource,
       _logsRemoteDataSource = logsRemoteDataSource;

  final LogsLocalDatasource _logsLocalDatasource;
  final LogsRemoteDataSource _logsRemoteDataSource;

  @override
  ResultFuture<void> addLog(LogEntryEntity logEntry) async {
    try {
      final logModel = LogEntryModel(
        id: logEntry.id,
        message: logEntry.message,
        level: logEntry.level,
        category: logEntry.category,
        timestamp: logEntry.timestamp,
        details: logEntry.details,
        userId: logEntry.userId,
        tripId: logEntry.tripId,
        deliveryId: logEntry.deliveryId,
        stackTrace: logEntry.stackTrace,
      );
      
      await _logsLocalDatasource.addLog(logModel);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  ResultFuture<List<LogEntryEntity>> getAllLogs() async {
    try {
      final logs = await _logsLocalDatasource.getAllLogs();
      return Right(logs);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  ResultFuture<void> clearAllLogs() async {
    try {
      await _logsLocalDatasource.clearAllLogs();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  ResultFuture<String> downloadLogsAsPdf() async {
    try {
      final filePath = await _logsLocalDatasource.generateLogsPdf();
      return Right(filePath);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  ResultFuture<int> syncLogsToRemote() async {
    try {
      debugPrint('🔄 Starting logs sync to remote');
      
      // Get unsynced logs from local storage
      final unsyncedLogs = await _logsLocalDatasource.getUnsyncedLogs();
      debugPrint('📊 Found ${unsyncedLogs.length} unsynced logs');
      
      if (unsyncedLogs.isEmpty) {
        debugPrint('✅ No unsynced logs to upload');
        return const Right(0);
      }

      // Check if remote is available
      final isRemoteAvailable = await _logsRemoteDataSource.isRemoteLoggingAvailable();
      if (!isRemoteAvailable) {
        return Left(ServerFailure(
          message: 'Remote logging service is not available',
          statusCode: '503',
        ));
      }

      // Upload logs to remote
      final uploadedLogIds = await _logsRemoteDataSource.uploadLogsToRemote(unsyncedLogs);
      debugPrint('✅ Uploaded ${uploadedLogIds.length} logs to remote');

      // Mark uploaded logs as synced in local storage
      await _logsLocalDatasource.markLogsAsSynced(uploadedLogIds);
      debugPrint('✅ Marked ${uploadedLogIds.length} logs as synced locally');

      return Right(uploadedLogIds.length);
    } on ServerException catch (e) {
      debugPrint('❌ Server error during sync: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('❌ Cache error during sync: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ Unexpected error during sync: $e');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<LogEntryEntity>> getUnsyncedLogs() async {
    try {
      final unsyncedLogs = await _logsLocalDatasource.getUnsyncedLogs();
      return Right(unsyncedLogs);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  ResultFuture<void> markLogsAsSynced(List<String> logIds) async {
    try {
      await _logsLocalDatasource.markLogsAsSynced(logIds);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }
}
