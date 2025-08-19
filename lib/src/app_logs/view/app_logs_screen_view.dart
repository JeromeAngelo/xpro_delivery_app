import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_state.dart';
import 'package:x_pro_delivery_app/src/app_logs/widgets/log_entry_tile.dart';

class AppLogsScreenView extends StatefulWidget {
  const AppLogsScreenView({super.key});

  @override
  State<AppLogsScreenView> createState() => _AppLogsScreenViewState();
}

class _AppLogsScreenViewState extends State<AppLogsScreenView> {
  @override
  void initState() {
    super.initState();
    // Load logs when screen initializes
    context.read<LogsBloc>().add(const LoadLogsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/homepage');
          },
        ),
        title: const Text('Application Logs'),
        actions: [
          // Sync to Remote Button
          BlocBuilder<LogsBloc, LogsState>(
            builder: (context, state) {
              return IconButton(
                onPressed: state is LogsSyncing ? null : () {
                  context.read<LogsBloc>().add(const SyncLogsToRemoteEvent());
                },
                icon: state is LogsSyncing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                tooltip: state is LogsSyncing ? 'Syncing...' : 'Sync Logs to Remote',
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  context.read<LogsBloc>().add(const RefreshLogsEvent());
                  break;
                case 'sync':
                  context.read<LogsBloc>().add(const SyncLogsToRemoteEvent());
                  break;
                case 'unsynced':
                  context.read<LogsBloc>().add(const LoadUnsyncedLogsEvent());
                  break;
                case 'clear':
                  _showClearConfirmation();
                  break;
                case 'download':
                  context.read<LogsBloc>().add(const DownloadLogsPdfEvent());
                  break;
                case 'generate_test':
                 // _generateTestLogs();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.cloud_upload, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Sync to Remote'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unsynced',
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Show Unsynced'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Logs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Download PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'generate_test',
                child: Row(
                  children: [
                    Icon(Icons.science, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Generate Test Logs'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<LogsBloc, LogsState>(
        listener: (context, state) {
          if (state is LogsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is LogsCleared) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All logs cleared successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is LogsPdfGenerated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('PDF generated successfully'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Share',
                  onPressed: () => _sharePdf(state.filePath),
                ),
              ),
            );
          } else if (state is LogsSyncSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.cloud_done, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Successfully synced ${state.syncedCount} logs to remote'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is LogsSyncing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Syncing logs to remote...'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LogsLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading logs...'),
                ],
              ),
            );
          } else if (state is LogsSyncing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Syncing logs to remote...'),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while logs are uploaded to PocketBase',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (state is LogsPdfGenerating) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            );
          } else if (state is LogsLoaded) {
            if (state.logs.isEmpty) {
              return _buildEmptyState();
            }
            return _buildLogsList(state.logs);
          } else if (state is UnsyncedLogsLoaded) {
            return _buildUnsyncedLogsList(state.unsyncedLogs);
          } else if (state is LogsError) {
            return _buildErrorState(state.message);
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: BlocBuilder<LogsBloc, LogsState>(
        builder: (context, state) {
          if (state is LogsSyncing) {
            return FloatingActionButton(
              onPressed: null,
              tooltip: 'Syncing...',
              backgroundColor: Colors.orange,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            );
          }
          
          return FloatingActionButton.extended(
            onPressed: () {
              context.read<LogsBloc>().add(const SyncLogsToRemoteEvent());
            },
            tooltip: 'Sync Logs to Remote',
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Sync'),
          );
        },
      ),
    );
  }

  Widget _buildLogsList(List<LogEntryEntity> logs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return LogEntryTile(log: log);
      },
    );
  }

  Widget _buildUnsyncedLogsList(List<LogEntryEntity> unsyncedLogs) {
    return Column(
      children: [
        // Header with sync status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unsynced Logs (${unsyncedLogs.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      'These logs have not been uploaded to remote storage',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<LogsBloc>().add(const SyncLogsToRemoteEvent());
                },
                icon: const Icon(Icons.cloud_upload, size: 16),
                label: const Text('Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Unsynced logs list
        Expanded(
          child: unsyncedLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_done,
                        size: 64,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'All logs are synced!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No logs pending upload to remote storage',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<LogsBloc>().add(const LoadLogsEvent());
                        },
                        child: const Text('Back to All Logs'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: unsyncedLogs.length,
                  itemBuilder: (context, index) {
                    final log = unsyncedLogs[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.orange.shade50,
                      ),
                      child: LogEntryTile(log: log),
                    );
                  },
                ),
        ),
      ],
    );
  }



  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No logs available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Logs will appear here as you use the app',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading logs',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<LogsBloc>().add(const LoadLogsEvent());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }



  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text(
          'Are you sure you want to clear all logs? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<LogsBloc>().add(const ClearLogsEvent());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _sharePdf(String filePath) {
    Share.shareXFiles([XFile(filePath)], text: 'Application Logs Report');
  }

  // void _generateTestLogs() async {
  //   try {
  //     debugPrint('🧪 Generating test logs from UI...');
      
  //     final syncCubit = context.read<SyncCubit>();
  //   //  await syncCubit.generateDemoLogs();
      
  //     // Refresh the logs display
  //     context.read<LogsBloc>().add(const RefreshLogsEvent());
      
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Test logs generated successfully!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     debugPrint('❌ Failed to generate test logs: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to generate test logs: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }
}
