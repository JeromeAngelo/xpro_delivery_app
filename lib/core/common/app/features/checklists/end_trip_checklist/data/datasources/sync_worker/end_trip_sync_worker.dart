// import 'dart:async';

// import 'package:flutter/foundation.dart';

// import '../../../../../../../../../objectbox.g.dart';
// import '../../../../../../../../enums/sync_status_enums.dart';
// import '../local_datasource/end_trip_checklist_local_data_src.dart';
// import '../remote_datasource/end_trip_checklist_remote_data_src.dart';

// class EndTripChecklistUpdateSyncWorker {
//   final EndTripChecklistLocalDataSourceImpl _local;
//   final EndTripChecklistRemoteDataSource _remote;
//   final Duration interval;
//   Timer? _timer;
//   bool _running = false;

//   EndTripChecklistUpdateSyncWorker({
//     required EndTripChecklistLocalDataSourceImpl local,
//     required EndTripChecklistRemoteDataSource remote,
//     this.interval = const Duration(seconds: 10),
//   }) : _local = local,
//        _remote = remote;

//   void start() {
//     if (_running) return;
//     _running = true;
//     _timer = Timer.periodic(interval, (_) => _syncPendingUpdates());
//     debugPrint('🟢 EndTripChecklistUpdateSyncWorker started');
//   }

//   void stop() {
//     _timer?.cancel();
//     _running = false;
//     debugPrint('🔴 EndTripChecklistUpdateSyncWorker stopped');
//   }

//   Future<void> _syncPendingUpdates() async {
//     try {
//       final q = _local.endTripChecklistBox
//           .query(
//             EndTripChecklistModel_.syncStatus.equals(
//               SyncStatus.pending.name,
//             ) &
//             EndTripChecklistModel_.isChecked.equals(true),
//           )
//           .build();

//       final pending = q.find();
//       q.close();

//       if (pending.isEmpty) {
//         debugPrint('📭 No pending checklist updates');
//         return;
//       }

//       debugPrint('🔄 Syncing ${pending.length} checklist updates');

//       for (final item in pending) {
//         if (item.id == null) continue; // must exist remotely

//         try {
//           item.syncStatus = SyncStatus.syncing.name;
//           item.lastLocalUpdatedAt = DateTime.now();
//           _local.endTripChecklistBox.put(item);

//           await _remote.checkEndTripChecklistItem(item);

//           item.syncStatus = SyncStatus.synced.name;
//           item.retryCount = 0;
//           _local.endTripChecklistBox.put(item);

//           debugPrint(
//             '✅ EndTripChecklist updated PB=${item.id}',
//           );
//         } catch (e) {
//           item.retryCount++;
//           item.syncStatus = SyncStatus.failed.name;
//           _local.endTripChecklistBox.put(item);

//           debugPrint(
//             '⚠️ Failed updating EndTripChecklist PB=${item.id}: $e',
//           );
//         }
//       }
//     } catch (e, st) {
//       debugPrint('❌ Update worker error: $e\n$st');
//     }
//   }
// }
