import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/data/datasource/logs_local_datasource/logs_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/data/model/log_entry_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';

class LogsRepoImpl implements LogsRepo {
  const LogsRepoImpl({required LogsLocalDatasource logsLocalDatasource})
      : _logsLocalDatasource = logsLocalDatasource;

  final LogsLocalDatasource _logsLocalDatasource;

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
}
