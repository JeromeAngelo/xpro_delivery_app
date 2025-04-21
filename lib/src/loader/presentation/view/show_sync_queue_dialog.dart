import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/services/sync_service.dart';

Future<void> showSyncQueueDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StreamBuilder<double>(
      stream: sl<SyncService>().progressStream,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0.0;
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.sync, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Sync Progress'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 8),
              _buildSyncStatus(progress),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildSyncStatus(double progress) {
  String status = 'Starting sync...';
  if (progress > 0.2) status = 'Syncing delivery team data...';
  if (progress > 0.3) status = 'Syncing customer data...';
  if (progress > 0.4) status = 'Syncing invoice data...';
  if (progress > 0.5) status = 'Syncing product data...';
  if (progress > 0.6) status = 'Syncing delivery updates...';
  if (progress > 0.7) status = 'Syncing completed customers...';
  if (progress > 0.8) status = 'Syncing returns and undelivered...';
  if (progress > 0.9) status = 'Finalizing sync...';
  if (progress >= 1.0) status = 'Sync completed!';
  
  return Text(
    status,
    style: const TextStyle(fontSize: 12),
    textAlign: TextAlign.center,
  );
}
