import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';

abstract class LogsState extends Equatable {
  const LogsState();

  @override
  List<Object> get props => [];
}

class LogsInitial extends LogsState {
  const LogsInitial();
}

class LogsLoading extends LogsState {
  const LogsLoading();
}

class LogsLoaded extends LogsState {
  const LogsLoaded(this.logs);

  final List<LogEntryEntity> logs;

  @override
  List<Object> get props => [logs];
}

class LogsError extends LogsState {
  const LogsError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

class LogsCleared extends LogsState {
  const LogsCleared();
}

class LogsPdfGenerated extends LogsState {
  const LogsPdfGenerated(this.filePath);

  final String filePath;

  @override
  List<Object> get props => [filePath];
}

class LogsPdfGenerating extends LogsState {
  const LogsPdfGenerating();
}

class LogsSyncing extends LogsState {
  const LogsSyncing();
}

class LogsSyncSuccess extends LogsState {
  const LogsSyncSuccess(this.syncedCount);

  final int syncedCount;

  @override
  List<Object> get props => [syncedCount];
}

class UnsyncedLogsLoaded extends LogsState {
  const UnsyncedLogsLoaded(this.unsyncedLogs);

  final List<LogEntryEntity> unsyncedLogs;

  @override
  List<Object> get props => [unsyncedLogs];
}
