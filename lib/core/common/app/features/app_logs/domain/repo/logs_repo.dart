import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';

abstract class LogsRepo {
  const LogsRepo();

  /// Add a new log entry
  ResultFuture<void> addLog(LogEntryEntity logEntry);

  /// Get all logs
  ResultFuture<List<LogEntryEntity>> getAllLogs();

  /// Clear all logs
  ResultFuture<void> clearAllLogs();

  /// Download logs as PDF
  ResultFuture<String> downloadLogsAsPdf();

  /// Sync local logs to remote (PocketBase)
  ResultFuture<int> syncLogsToRemote();

  /// Get unsynced logs (for syncing)
  ResultFuture<List<LogEntryEntity>> getUnsyncedLogs();

  /// Mark logs as synced
  ResultFuture<void> markLogsAsSynced(List<String> logIds);
}
