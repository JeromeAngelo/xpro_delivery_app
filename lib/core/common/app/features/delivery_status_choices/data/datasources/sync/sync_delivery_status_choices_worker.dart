import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../../../../../objectbox.g.dart';
import '../../../../delivery_data/delivery_update/data/models/delivery_update_model.dart';
import '../local_datasource/delivery_status_choices_local_datasource.dart';
import '../remote_datasource/delivery_status_choices_remote_datasource.dart';
import '../../model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/enums/sync_status_enums.dart';

class DeliveryStatusSyncWorker {
  final DeliveryStatusChoicesLocalDatasourceImpl _local;
  final DeliveryStatusChoicesRemoteDataSource _remote;
  final Duration interval;
  Timer? _timer;
  bool _running = false;

  DeliveryStatusSyncWorker({
    required DeliveryStatusChoicesLocalDatasourceImpl local,
    required DeliveryStatusChoicesRemoteDataSource remote,
    this.interval = const Duration(seconds: 10), // polling interval
  }) : _local = local,
       _remote = remote;

  /// Start the worker
  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(interval, (_) => _syncPendingStatuses());
    debugPrint('🟢 DeliveryStatusSyncWorker started');
  }

  /// Stop the worker
  void stop() {
    _timer?.cancel();
    _running = false;
    debugPrint('🔴 DeliveryStatusSyncWorker stopped');
  }

  /// Sync all pending DeliveryStatusChoices
  Future<void> _syncPendingStatuses() async {
    try {
      // New approach: sync pending DeliveryUpdateModel entries directly.
      final q =
          _local.deliveryUpdateBox
              .query(
                DeliveryUpdateModel_.syncStatus.equals(SyncStatus.pending.name),
              )
              .build();

      final pendingUpdates = q.find();
      q.close();

      if (pendingUpdates.isEmpty) {
        debugPrint('📭 No pending DeliveryUpdate entries to sync');
        return;
      }

      debugPrint(
        '🔄 Syncing ${pendingUpdates.length} pending DeliveryUpdate entries',
      );

      // ---------------------------------------------------
      // 🆕 DEDUPLICATION: Only sync ONE update per (deliveryDataPbId + statusChoicePbId)
      // This prevents multiple "unloading" updates from being synced to PocketBase
      // ---------------------------------------------------
      final seen = <String>{};
      final uniqueUpdates = <DeliveryUpdateModel>[];

      for (final update in pendingUpdates) {
        final key = '${update.deliveryDataPbId}_${update.statusChoicePbId}';
        if (seen.contains(key)) {
          debugPrint(
            '🚫 SYNC DEDUP: Skipping duplicate "${update.title}" for delivery ${update.deliveryDataPbId}',
          );
          // Mark the duplicate as failed so it won't be retried
          update.syncStatus = SyncStatus.failed.name;
          update.lastSyncError = 'Duplicate status — already syncing another';
          _local.deliveryUpdateBox.put(update);
          continue;
        }
        seen.add(key);
        uniqueUpdates.add(update);
      }

      if (uniqueUpdates.length < pendingUpdates.length) {
        debugPrint(
          '🧹 DEDUP: ${pendingUpdates.length} pending → ${uniqueUpdates.length} unique (removed ${pendingUpdates.length - uniqueUpdates.length} duplicates)',
        );
      }

      for (final update in uniqueUpdates) {
        try {
          // mark local update as syncing
          update.syncStatus = SyncStatus.syncing.name;
          update.lastLocalUpdatedAt = DateTime.now();
          _local.deliveryUpdateBox.put(update);

          // Build a small status model for the remote API
          final statusModel = DeliveryStatusChoicesModel(
            id: update.statusChoicePbId,
            title: update.title,
            subtitle: update.subtitle,
          );

          // Attempt remote creation and linking; remote returns remote update id
          final remoteId = await _remote.updateCustomerStatus(
            update.deliveryDataPbId ?? '',
            statusModel,
          );

          // Reconcile local update with remote id
          update.id = remoteId;
          update.syncStatus = SyncStatus.synced.name;
          update.retryCount = 0;
          update.updated = DateTime.now();
          _local.deliveryUpdateBox.put(update);

          debugPrint(
            '✅ Synced DeliveryUpdate OBX=${update.objectBoxId} → remoteId=$remoteId',
          );

          // Optionally, mark any corresponding DeliveryStatusChoicesModel as synced
          if (update.statusChoicePbId != null) {
            try {
              final statusQ =
                  _local.deliveryStatusChoicesBox
                      .query(
                        DeliveryStatusChoicesModel_.id.equals(
                          update.statusChoicePbId ?? '',
                        ),
                      )
                      .build();
              final localStatus = statusQ.findFirst();
              statusQ.close();
              if (localStatus != null) {
                await _local.markSynced(localStatus);
              }
            } catch (_) {}
          }
        } catch (e) {
          debugPrint(
            '⚠️ Failed syncing DeliveryUpdate OBX=${update.objectBoxId}: $e',
          );
          // Backoff / retry handling
          update.retryCount = (update.retryCount) + 1;
          update.syncStatus = SyncStatus.failed.name;
          _local.deliveryUpdateBox.put(update);
        }
      }
    } catch (e, st) {
      debugPrint('❌ Worker error: $e\n$st');
    }
  }
}
