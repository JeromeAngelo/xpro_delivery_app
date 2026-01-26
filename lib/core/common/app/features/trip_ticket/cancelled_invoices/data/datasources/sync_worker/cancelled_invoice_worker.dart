import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../../../../objectbox.g.dart';
import '../../../../../../../../enums/sync_status_enums.dart' show SyncStatus;
import '../local_datasource/cancelled_invoice_local_datasource.dart';
import '../remote_datasource/cancelled_invoice_remote_datasource.dart';
class CancelledInvoiceSyncWorker {
  final CancelledInvoiceLocalDataSourceImpl _local;
  final CancelledInvoiceRemoteDataSourceImpl _remote;
  final Duration interval;
  Timer? _timer;
  bool _running = false;

  CancelledInvoiceSyncWorker({
    required CancelledInvoiceLocalDataSourceImpl local,
    required CancelledInvoiceRemoteDataSourceImpl remote,
    this.interval = const Duration(seconds: 10),
  })  : _local = local,
        _remote = remote;

  /// 🟢 Start worker
  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(interval, (_) => _syncPendingCancelledInvoices());
    debugPrint('🟢 CancelledInvoiceSyncWorker started');
  }

  /// 🔴 Stop worker
  void stop() {
    _timer?.cancel();
    _running = false;
    debugPrint('🔴 CancelledInvoiceSyncWorker stopped');
  }

  /// 🔄 Sync pending cancelled invoices
  Future<void> _syncPendingCancelledInvoices() async {
    if (!_running) return;

    try {
      final q = _local.cancelledInvoiceBox
          .query(
            CancelledInvoiceModel_.syncStatus.equals(SyncStatus.pending.name),
          )
          .build();

      final pendingInvoices = q.find();
      q.close();

      if (pendingInvoices.isEmpty) {
        debugPrint('📭 No pending CancelledInvoice entries');
        return;
      }

      debugPrint(
        '🔄 Syncing ${pendingInvoices.length} CancelledInvoice entries',
      );

      for (final invoice in pendingInvoices) {
        // 🛑 HARD SAFETY GUARD — NEVER re-sync valid remote records
        if (invoice.syncStatus == SyncStatus.synced.name &&
            invoice.id != null) {
          debugPrint(
            '⛔ Skipping already-synced invoice OBX=${invoice.objectBoxId}',
          );
          continue;
        }

        try {
          // 🚧 Mark as syncing (MUTATE SAME ENTITY)
          invoice.syncStatus = SyncStatus.syncing.name;
          invoice.lastLocalUpdatedAt = DateTime.now();
          _local.cancelledInvoiceBox.put(invoice);

          // 🧩 Validate deliveryData link
          final deliveryDataId = invoice.deliveryData.target?.id;
          if (deliveryDataId == null || deliveryDataId.isEmpty) {
            throw Exception('Missing deliveryDataId');
          }

          // 🌐 Create remote cancelled invoice
          final remoteInvoice =
              await _remote.createCancelledInvoice(invoice, deliveryDataId);

          // ✅ RECONCILE — UPDATE SAME OBJECTBOX ENTITY
          invoice
            ..id = remoteInvoice.id
            ..syncStatus = SyncStatus.synced.name
            ..retryCount = 0
            ..lastSyncError = null
            ..updated = DateTime.now()
            ..lastLocalUpdatedAt = DateTime.now();

          _local.cancelledInvoiceBox.put(invoice);

          debugPrint(
            '✅ Synced CancelledInvoice OBX=${invoice.objectBoxId} → remoteId=${remoteInvoice.id}',
          );
        } catch (e) {
          debugPrint(
            '⚠️ Sync failed OBX=${invoice.objectBoxId}: $e',
          );

          // 🔁 Backoff & retry
          invoice
            ..retryCount = invoice.retryCount + 1
            ..syncStatus = SyncStatus.failed.name
            ..lastSyncError = e.toString()
            ..lastLocalUpdatedAt = DateTime.now();

          _local.cancelledInvoiceBox.put(invoice);
        }
      }
    } catch (e, st) {
      debugPrint('❌ CancelledInvoice worker fatal error: $e\n$st');
    }
  }
}
