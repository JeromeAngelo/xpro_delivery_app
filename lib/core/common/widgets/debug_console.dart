import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_state.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});

  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load logs when console opens
    context.read<LogsBloc>().add(const LoadLogsEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getLogColor(String logLevel, BuildContext context) {
    switch (logLevel.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData _getLogIcon(String logLevel) {
    switch (logLevel.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Console Header
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
                if (_isExpanded) {
                  context.read<LogsBloc>().add(const RefreshLogsEvent());
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Debug Console',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    BlocBuilder<LogsBloc, LogsState>(
                      builder: (context, state) {
                        String countText = '';
                        Color? statusColor;
                        
                        if (state is LogsLoaded) {
                          countText = '(${state.logs.length})';
                        } else if (state is LogsSyncing) {
                          countText = '(Syncing...)';
                          statusColor = Colors.orange;
                        } else if (state is LogsSyncSuccess) {
                          countText = '(${state.syncedCount} synced)';
                          statusColor = Colors.green;
                        } else if (state is UnsyncedLogsLoaded) {
                          countText = '(${state.unsyncedLogs.length} unsynced)';
                          statusColor = Colors.red;
                        }
                        
                        return Text(
                          countText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
            // Console Body
            if (_isExpanded)
              Container(
                height: 300,
                child: Column(
                  children: [
                    // Console Controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                      ),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              context.read<LogsBloc>().add(const RefreshLogsEvent());
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              context.read<LogsBloc>().add(const SyncLogsToRemoteEvent());
                            },
                            icon: const Icon(Icons.cloud_upload, size: 16),
                            label: const Text('Sync'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              context.read<LogsBloc>().add(const ClearLogsEvent());
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              _scrollToBottom();
                            },
                            icon: const Icon(Icons.arrow_downward, size: 16),
                            label: const Text('Bottom'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Console Logs
                    Expanded(
                      child: BlocBuilder<LogsBloc, LogsState>(
                        builder: (context, state) {
                          if (state is LogsLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state is LogsError) {
                            return Center(
                              child: Text(
                                'Error: ${state.message}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          if (state is LogsLoaded) {
                            final logs = state.logs;
                            
                            if (logs.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No logs available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom();
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                final logLevel = log.level?.name ?? 'info';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getLogColor(logLevel, context).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getLogColor(logLevel, context).withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _getLogIcon(logLevel),
                                        size: 14,
                                        color: _getLogColor(logLevel, context),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        log.timestamp?.toString().substring(11, 19) ?? '',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontFamily: 'monospace',
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log.message ?? '',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontFamily: 'monospace',
                                                color: _getLogColor(logLevel, context),
                                              ),
                                            ),
                                            if (log.details != null && log.details!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                log.details!,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontFamily: 'monospace',
                                                  color: Theme.of(context).colorScheme.outline,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }

                          return const Center(
                            child: Text('No logs available'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
