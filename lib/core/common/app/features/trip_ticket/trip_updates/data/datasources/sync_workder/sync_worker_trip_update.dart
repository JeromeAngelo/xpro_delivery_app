import 'dart:async';

import 'package:flutter/material.dart';

import '../local_datasource/trip_update_local_datasource.dart';
import '../remote_datasource/trip_update_remote_datasource.dart';

class TripUpdateSyncWorker {
  final TripUpdateLocalDatasourceImpl _local;
  final TripUpdateRemoteDatasource _remote;
  final Duration interval;

  Timer? _timer;
  bool _running = false;

  TripUpdateSyncWorker({
    required TripUpdateLocalDatasourceImpl local,
    required TripUpdateRemoteDatasource remote,
    this.interval = const Duration(seconds: 10),
  })  : _local = local,
        _remote = remote;

  /// ▶️ Start worker
  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(interval, (_) => _syncPendingTripUpdates());
    debugPrint('🟢 TripUpdateSyncWorker started');
  }

  /// ⏹ Stop worker
  void stop() {
    _timer?.cancel();
    _running = false;
    debugPrint('🔴 TripUpdateSyncWorker stopped');
  }

  /// 🔄 Sync all pending TripUpdates
  Future<void> _syncPendingTripUpdates() async {
    try {
      final pending = await _local.getPendingTripUpdates();

      if (pending.isEmpty) {
        debugPrint('📭 No pending TripUpdates to sync');
        return;
      }

      debugPrint(
        '🔄 Syncing ${pending.length} pending TripUpdates',
      );

      for (final update in pending) {
        try {
          // 1️⃣ Mark syncing
          await _local.markTripUpdateSyncing(update);

          // 2️⃣ Push to remote
          final remoteId = await _remote.createTripUpdate(
            tripId: update.tripId!,
           description: update.description!,
            image: update.image!,
            latitude: update.latitude!,
            longitude: update.longitude!,
            status: update.status!,
          );

          // 3️⃣ Mark synced
          await _local.markTripUpdateSynced(update, remoteId);
        } catch (e) {
          debugPrint(
            '⚠️ TripUpdate sync failed → OBX=${update.objectBoxId}: $e',
          );
          await _local.markTripUpdateFailed(update, e.toString());
        }
      }
    } catch (e, st) {
      debugPrint('❌ TripUpdateSyncWorker error: $e\n$st');
    }
  }
}
