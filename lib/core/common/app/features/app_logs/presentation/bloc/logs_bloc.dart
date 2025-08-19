import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/usecases/add_log.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/usecases/clear_logs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/usecases/download_logs_pdf.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/usecases/get_logs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/usecases/get_unsynced_logs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/usecases/sync_logs_to_remote.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_state.dart';

class LogsBloc extends Bloc<LogsEvent, LogsState> {
  LogsBloc({
    required GetLogs getLogs,
    required ClearLogs clearLogs,
    required DownloadLogsPdf downloadLogsPdf,
    required AddLog addLog,
    required SyncLogsToRemote syncLogsToRemote,
    required GetUnsyncedLogs getUnsyncedLogs,
  }) : _getLogs = getLogs,
       _clearLogs = clearLogs,
       _downloadLogsPdf = downloadLogsPdf,
       _addLog = addLog,
       _syncLogsToRemote = syncLogsToRemote,
       _getUnsyncedLogs = getUnsyncedLogs,
       super(const LogsInitial()) {
    on<LoadLogsEvent>(_onLoadLogs);
    on<ClearLogsEvent>(_onClearLogs);
    on<DownloadLogsPdfEvent>(_onDownloadLogsPdf);
    on<RefreshLogsEvent>(_onRefreshLogs);
    on<SyncLogsToRemoteEvent>(_onSyncLogsToRemote);
    on<LoadUnsyncedLogsEvent>(_onLoadUnsyncedLogs);
  }

  final GetLogs _getLogs;
  final ClearLogs _clearLogs;
  final DownloadLogsPdf _downloadLogsPdf;
  final AddLog _addLog;
  final SyncLogsToRemote _syncLogsToRemote;
  final GetUnsyncedLogs _getUnsyncedLogs;

  Future<void> _onLoadLogs(
    LoadLogsEvent event,
    Emitter<LogsState> emit,
  ) async {
    emit(const LogsLoading());

    final result = await _getLogs();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load logs: ${failure.message}');
        emit(LogsError(failure.message));
      },
      (logs) {
        debugPrint('✅ Loaded ${logs.length} logs');
        emit(LogsLoaded(logs));
      },
    );
  }

  Future<void> _onClearLogs(
    ClearLogsEvent event,
    Emitter<LogsState> emit,
  ) async {
    emit(const LogsLoading());

    final result = await _clearLogs();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to clear logs: ${failure.message}');
        emit(LogsError(failure.message));
      },
      (_) {
        debugPrint('✅ Logs cleared successfully');
        emit(const LogsCleared());
        // Reload logs to show empty state
        add(const LoadLogsEvent());
      },
    );
  }

  Future<void> _onDownloadLogsPdf(
    DownloadLogsPdfEvent event,
    Emitter<LogsState> emit,
  ) async {
    emit(const LogsPdfGenerating());

    final result = await _downloadLogsPdf();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to generate PDF: ${failure.message}');
        emit(LogsError(failure.message));
      },
      (filePath) {
        debugPrint('✅ PDF generated at: $filePath');
        emit(LogsPdfGenerated(filePath));
      },
    );
  }

  Future<void> _onRefreshLogs(
    RefreshLogsEvent event,
    Emitter<LogsState> emit,
  ) async {
    // Simply reload logs
    add(const LoadLogsEvent());
  }

  Future<void> _onSyncLogsToRemote(
    SyncLogsToRemoteEvent event,
    Emitter<LogsState> emit,
  ) async {
    emit(const LogsSyncing());
    debugPrint('🔄 Starting logs sync to remote');

    final result = await _syncLogsToRemote();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to sync logs: ${failure.message}');
        emit(LogsError(failure.message));
      },
      (syncedCount) {
        debugPrint('✅ Synced $syncedCount logs to remote');
        emit(LogsSyncSuccess(syncedCount));
        // Reload logs to reflect sync status changes
        add(const LoadLogsEvent());
      },
    );
  }

  Future<void> _onLoadUnsyncedLogs(
    LoadUnsyncedLogsEvent event,
    Emitter<LogsState> emit,
  ) async {
    emit(const LogsLoading());
    debugPrint('🔄 Loading unsynced logs');

    final result = await _getUnsyncedLogs();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load unsynced logs: ${failure.message}');
        emit(LogsError(failure.message));
      },
      (unsyncedLogs) {
        debugPrint('✅ Loaded ${unsyncedLogs.length} unsynced logs');
        emit(UnsyncedLogsLoaded(unsyncedLogs));
      },
    );
  }
}
