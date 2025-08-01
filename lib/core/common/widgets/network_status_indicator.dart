import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';

/// Widget that shows network connection status and data freshness
class NetworkStatusIndicator extends StatelessWidget {
  final bool showWhenOnline;
  final DateTime? lastSync;
  final bool isLoading;
  
  const NetworkStatusIndicator({
    super.key,
    this.showWhenOnline = false,
    this.lastSync,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        // Don't show when online unless specifically requested
        if (connectivity.isOnline && !showWhenOnline && !isLoading) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(connectivity, context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(connectivity),
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                _getStatusText(connectivity),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(ConnectivityProvider connectivity, BuildContext context) {
    if (isLoading) {
      return Colors.blue;
    }
    
    if (!connectivity.isOnline) {
      return Colors.orange;
    }
    
    if (connectivity.isSyncing) {
      return Colors.blue;
    }
    
    // Check data freshness
    if (lastSync != null) {
      final age = DateTime.now().difference(lastSync!);
      if (age > const Duration(minutes: 10)) {
        return Colors.amber;
      }
    }
    
    return Colors.green;
  }

  IconData _getStatusIcon(ConnectivityProvider connectivity) {
    if (isLoading || connectivity.isSyncing) {
      return Icons.sync;
    }
    
    if (!connectivity.isOnline) {
      return Icons.cloud_off;
    }
    
    return Icons.cloud_done;
  }

  String _getStatusText(ConnectivityProvider connectivity) {
    if (isLoading) {
      return 'Loading...';
    }
    
    if (connectivity.isSyncing) {
      return 'Syncing...';
    }
    
    if (!connectivity.isOnline) {
      return 'Offline mode';
    }
    
    if (lastSync != null) {
      final age = DateTime.now().difference(lastSync!);
      if (age < const Duration(minutes: 1)) {
        return 'Just synced';
      } else if (age < const Duration(minutes: 5)) {
        return '${age.inMinutes}m ago';
      } else if (age < const Duration(hours: 1)) {
        return '${age.inMinutes}m ago';
      } else {
        return '${age.inHours}h ago';
      }
    }
    
    return 'Online';
  }
}

/// Widget that shows a persistent offline banner
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          color: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'You\'re in offline mode - showing cached data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget that wraps content with offline-first loading states
class OfflineFirstContainer extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final bool hasData;
  final bool isOffline;
  final String? error;
  final VoidCallback? onRetry;
  final DateTime? lastSync;

  const OfflineFirstContainer({
    super.key,
    required this.child,
    this.isLoading = false,
    this.hasData = true,
    this.isOffline = false,
    this.error,
    this.onRetry,
    this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Network status indicator
        if (isOffline || isLoading)
          NetworkStatusIndicator(
            showWhenOnline: true,
            lastSync: lastSync,
            isLoading: isLoading,
          ),
        
        // Main content
        Expanded(
          child: Stack(
            children: [
              // Content
              child,
              
              // Loading overlay (only when no cached data)
              if (isLoading && !hasData)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              
              // Error state
              if (error != null && !hasData)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isOffline ? Icons.cloud_off : Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isOffline 
                            ? 'No cached data available' 
                            : 'Failed to load data',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
