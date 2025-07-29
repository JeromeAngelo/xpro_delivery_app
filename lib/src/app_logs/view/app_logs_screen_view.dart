import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/sync_data/cubit/sync_cubit.dart';
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  context.read<LogsBloc>().add(const RefreshLogsEvent());
                  break;
                case 'clear':
                  _showClearConfirmation();
                  break;
                case 'download':
                  context.read<LogsBloc>().add(const DownloadLogsPdfEvent());
                  break;
                case 'generate_test':
                  _generateTestLogs();
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
          } else if (state is LogsError) {
            return _buildErrorState(state.message);
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<LogsBloc>().add(const RefreshLogsEvent());
        },
        tooltip: 'Refresh Logs',
        child: const Icon(Icons.refresh),
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

  void _generateTestLogs() async {
    try {
      debugPrint('🧪 Generating test logs from UI...');
      
      final syncCubit = context.read<SyncCubit>();
      await syncCubit.generateDemoLogs();
      
      // Refresh the logs display
      context.read<LogsBloc>().add(const RefreshLogsEvent());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test logs generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to generate test logs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate test logs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
