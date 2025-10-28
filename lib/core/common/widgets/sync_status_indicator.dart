import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/services/offline_sync_service.dart';

/// Widget that displays sync status at the top of the screen
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  final _offlineSyncService = OfflineSyncService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: _offlineSyncService.syncStatusStream,
      initialData: _offlineSyncService.getCurrentStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;

        // Don't show anything if online and no pending operations
        if (status.isOnline && 
            status.queuedOperations == 0 && 
            status.failedOperations == 0 &&
            !status.isSyncing) {
          return const SizedBox.shrink();
        }

        return Material(
          color: _getBackgroundColor(status),
          elevation: 4,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildIcon(status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTitle(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (status.message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            status.message!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (status.isSyncing && status.progress != null) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: status.progress,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(SyncStatus status) {
    if (status.isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (!status.isOnline) {
      return const Icon(
        Icons.cloud_off,
        color: Colors.white,
        size: 20,
      );
    }

    if (status.failedOperations > 0) {
      return const Icon(
        Icons.error_outline,
        color: Colors.white,
        size: 20,
      );
    }

    if (status.queuedOperations > 0) {
      return const Icon(
        Icons.cloud_upload,
        color: Colors.white,
        size: 20,
      );
    }

    return const Icon(
      Icons.check_circle,
      color: Colors.white,
      size: 20,
    );
  }

  String _getTitle(SyncStatus status) {
    if (status.isSyncing) {
      return 'Syncing...';
    }

    if (!status.isOnline) {
      if (status.queuedOperations > 0) {
        return 'Offline - ${status.queuedOperations} pending';
      }
      return 'Working Offline';
    }

    if (status.failedOperations > 0) {
      return '${status.failedOperations} failed operations';
    }

    if (status.queuedOperations > 0) {
      return '${status.queuedOperations} operations queued';
    }

    return 'All synced';
  }

  Color _getBackgroundColor(SyncStatus status) {
    if (status.failedOperations > 0) {
      return Colors.red.shade700;
    }

    if (!status.isOnline) {
      return Colors.orange.shade700;
    }

    if (status.isSyncing) {
      return Colors.blue.shade700;
    }

    return Colors.green.shade700;
  }

  Widget _buildActionButton(SyncStatus status) {
    if (status.isSyncing) {
      return const SizedBox.shrink();
    }

    if (!status.isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${status.queuedOperations}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (status.queuedOperations > 0 || status.failedOperations > 0) {
      return TextButton(
        onPressed: () {
          _offlineSyncService.syncAll();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          backgroundColor: Colors.white24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Sync Now',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Floating sync status button (alternative to banner)
class SyncStatusButton extends StatefulWidget {
  const SyncStatusButton({super.key});

  @override
  State<SyncStatusButton> createState() => _SyncStatusButtonState();
}

class _SyncStatusButtonState extends State<SyncStatusButton> {
  final _offlineSyncService = OfflineSyncService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: _offlineSyncService.syncStatusStream,
      initialData: _offlineSyncService.getCurrentStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;

        // Don't show if everything is synced
        if (status.isOnline && 
            status.queuedOperations == 0 && 
            status.failedOperations == 0 &&
            !status.isSyncing) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: status.isSyncing ? null : () {
              if (status.isOnline) {
                _offlineSyncService.syncAll();
              } else {
                _showOfflineDialog(context, status);
              }
            },
            backgroundColor: _getBackgroundColor(status),
            icon: _buildIcon(status),
            label: Text(_getLabel(status)),
          ),
        );
      },
    );
  }

  Widget _buildIcon(SyncStatus status) {
    if (status.isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (!status.isOnline) {
      return const Icon(Icons.cloud_off);
    }

    if (status.failedOperations > 0) {
      return const Icon(Icons.error_outline);
    }

    return const Icon(Icons.cloud_upload);
  }

  String _getLabel(SyncStatus status) {
    if (status.isSyncing) {
      return 'Syncing...';
    }

    if (!status.isOnline) {
      return 'Offline (${status.queuedOperations})';
    }

    if (status.failedOperations > 0) {
      return 'Retry ${status.failedOperations}';
    }

    return 'Sync ${status.queuedOperations}';
  }

  Color _getBackgroundColor(SyncStatus status) {
    if (status.failedOperations > 0) {
      return Colors.red;
    }

    if (!status.isOnline) {
      return Colors.orange;
    }

    if (status.isSyncing) {
      return Colors.blue;
    }

    return Colors.green;
  }

  void _showOfflineDialog(BuildContext context, SyncStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
        title: const Text('Working Offline'),
        content: Text(
          'You have ${status.queuedOperations} operations queued.\n\n'
          'They will be automatically synced when internet connection is restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
