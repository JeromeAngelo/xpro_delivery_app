import 'package:equatable/equatable.dart';

abstract class LogsEvent extends Equatable {
  const LogsEvent();

  @override
  List<Object> get props => [];
}

class LoadLogsEvent extends LogsEvent {
  const LoadLogsEvent();
}

class ClearLogsEvent extends LogsEvent {
  const ClearLogsEvent();
}

class DownloadLogsPdfEvent extends LogsEvent {
  const DownloadLogsPdfEvent();
}

class RefreshLogsEvent extends LogsEvent {
  const RefreshLogsEvent();
}

class SyncLogsToRemoteEvent extends LogsEvent {
  const SyncLogsToRemoteEvent();
}

class LoadUnsyncedLogsEvent extends LogsEvent {
  const LoadUnsyncedLogsEvent();
}
