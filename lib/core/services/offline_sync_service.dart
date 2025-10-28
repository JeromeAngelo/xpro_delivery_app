import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';

/// Comprehensive offline-first sync service
/// Queues all operations when offline and syncs when connection is restored
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static const String _queueKey = 'offline_sync_queue';
  static const String _syncStatusKey = 'last_sync_status';
  static const String _syncTimestampKey = 'last_sync_timestamp';
  static const String _failedOperationsKey = 'failed_operations';

  final List<OfflineOperation> _operationQueue = [];
  final List<OfflineOperation> _failedOperations = [];
  
  StreamController<SyncStatus>? _syncStatusController;
  Stream<SyncStatus>? _syncStatusStream;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  bool _isSyncing = false;
  bool _isInitialized = false;
  bool _isOnline = false;
  DateTime? _lastSyncTime;
  int _totalQueuedOperations = 0;
  int _totalFailedOperations = 0;

  PocketBase? _pocketBase;

  /// Initialize the offline sync service
  Future<void> initialize(PocketBase pocketBase) async {
    if (_isInitialized) {
      debugPrint('⚠️ OfflineSyncService: Already initialized');
      return;
    }

    try {
      debugPrint('🔄 OfflineSyncService: Initializing...');
      
      _pocketBase = pocketBase;
      
      // Create sync status stream
      _syncStatusController = StreamController<SyncStatus>.broadcast();
      _syncStatusStream = _syncStatusController!.stream;

      // Load persisted queue and failed operations
      await _loadPersistedData();

      // Check initial connectivity
      _isOnline = await _checkConnectivity();
      debugPrint('🌐 OfflineSyncService: Initial connectivity: ${_isOnline ? "ONLINE" : "OFFLINE"}');

      // Listen to connectivity changes
      _setupConnectivityListener();

      // Start periodic sync (every 5 minutes when online)
      _startPeriodicSync();

      _isInitialized = true;
      
      // Emit initial status
      _emitStatus(SyncStatus(
        isSyncing: false,
        isOnline: _isOnline,
        queuedOperations: _operationQueue.length,
        failedOperations: _failedOperations.length,
        lastSyncTime: _lastSyncTime,
      ));

      debugPrint('✅ OfflineSyncService: Initialized successfully');
      debugPrint('   📊 Queued operations: ${_operationQueue.length}');
      debugPrint('   ❌ Failed operations: ${_failedOperations.length}');
      debugPrint('   🌐 Online: $_isOnline');
      
      // Auto-sync if online and has queued operations
      if (_isOnline && _operationQueue.isNotEmpty) {
        debugPrint('🔄 OfflineSyncService: Auto-syncing queued operations...');
        unawaited(syncAll());
      }
      
    } catch (e, st) {
      debugPrint('❌ OfflineSyncService: Initialization failed: $e\n$st');
      rethrow;
    }
  }

  /// Queue an operation for offline sync
  Future<void> queueOperation(OfflineOperation operation) async {
    try {
      debugPrint('📝 OfflineSyncService: Queuing operation: ${operation.type} ${operation.collection}/${operation.recordId}');
      
      // Add timestamp if not set
      operation.timestamp ??= DateTime.now();

      // Add to in-memory queue
      _operationQueue.add(operation);
      _totalQueuedOperations++;

      // Persist to storage
      await _persistQueue();

      // Emit status update
      _emitStatus(SyncStatus(
        isSyncing: _isSyncing,
        isOnline: _isOnline,
        queuedOperations: _operationQueue.length,
        failedOperations: _failedOperations.length,
        lastSyncTime: _lastSyncTime,
        message: 'Operation queued: ${operation.type} ${operation.collection}',
      ));

      debugPrint('✅ OfflineSyncService: Operation queued (${_operationQueue.length} total)');

      // Try to sync immediately if online
      if (_isOnline && !_isSyncing) {
        debugPrint('🔄 OfflineSyncService: Online - attempting immediate sync...');
        unawaited(syncAll());
      }
      
    } catch (e, st) {
      debugPrint('❌ OfflineSyncService: Failed to queue operation: $e\n$st');
      rethrow;
    }
  }

  /// Sync all queued operations
  Future<SyncResult> syncAll() async {
    if (!_isOnline) {
      debugPrint('⚠️ OfflineSyncService: Cannot sync - offline');
      return SyncResult(
        success: false,
        processed: 0,
        failed: 0,
        message: 'Device is offline',
      );
    }

    if (_isSyncing) {
      debugPrint('⚠️ OfflineSyncService: Sync already in progress');
      return SyncResult(
        success: false,
        processed: 0,
        failed: 0,
        message: 'Sync already in progress',
      );
    }

    if (_operationQueue.isEmpty && _failedOperations.isEmpty) {
      debugPrint('ℹ️ OfflineSyncService: No operations to sync');
      return SyncResult(
        success: true,
        processed: 0,
        failed: 0,
        message: 'No operations to sync',
      );
    }

    try {
      _isSyncing = true;
      final startTime = DateTime.now();
      
      debugPrint('🚀 OfflineSyncService: Starting sync...');
      debugPrint('   📊 Queued operations: ${_operationQueue.length}');
      debugPrint('   🔄 Retrying failed: ${_failedOperations.length}');

      _emitStatus(SyncStatus(
        isSyncing: true,
        isOnline: _isOnline,
        queuedOperations: _operationQueue.length,
        failedOperations: _failedOperations.length,
        lastSyncTime: _lastSyncTime,
        message: 'Syncing ${_operationQueue.length + _failedOperations.length} operations...',
      ));

      int processed = 0;
      int failed = 0;
      final List<OfflineOperation> remainingQueue = [];
      final List<OfflineOperation> newFailedOps = [];

      // Combine queue and failed operations
      final allOperations = [..._operationQueue, ..._failedOperations];
      
      // Process each operation
      for (int i = 0; i < allOperations.length; i++) {
        final operation = allOperations[i];
        
        try {
          debugPrint('🔄 OfflineSyncService: Processing ${i + 1}/${allOperations.length}: ${operation.type} ${operation.collection}/${operation.recordId}');
          
          // Execute the operation
          await _executeOperation(operation);
          
          processed++;
          debugPrint('✅ OfflineSyncService: Operation successful');
          
          // Emit progress
          _emitStatus(SyncStatus(
            isSyncing: true,
            isOnline: _isOnline,
            queuedOperations: allOperations.length - i - 1,
            failedOperations: _failedOperations.length,
            lastSyncTime: _lastSyncTime,
            message: 'Synced ${processed}/${allOperations.length}',
            progress: (i + 1) / allOperations.length,
          ));
          
        } catch (e) {
          debugPrint('❌ OfflineSyncService: Operation failed: $e');
          failed++;
          
          // Increment retry count
          operation.retryCount++;
          
          // If max retries reached, move to failed list
          if (operation.retryCount >= 3) {
            debugPrint('⚠️ OfflineSyncService: Max retries reached, marking as failed');
            newFailedOps.add(operation);
          } else {
            debugPrint('🔄 OfflineSyncService: Will retry (attempt ${operation.retryCount}/3)');
            remainingQueue.add(operation);
          }
        }
        
        // Small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Update queues
      _operationQueue.clear();
      _operationQueue.addAll(remainingQueue);
      
      _failedOperations.clear();
      _failedOperations.addAll(newFailedOps);
      
      _lastSyncTime = DateTime.now();
      
      // Persist changes
      await _persistQueue();
      await _persistFailedOperations();
      await _persistSyncStatus();

      final duration = DateTime.now().difference(startTime);
      
      final result = SyncResult(
        success: failed == 0,
        processed: processed,
        failed: failed,
        duration: duration,
        message: 'Synced $processed operations in ${duration.inSeconds}s (${failed} failed)',
      );

      debugPrint('✅ OfflineSyncService: Sync completed');
      debugPrint('   ✅ Processed: $processed');
      debugPrint('   ❌ Failed: $failed');
      debugPrint('   📊 Remaining in queue: ${_operationQueue.length}');
      debugPrint('   ⏱️ Duration: ${duration.inSeconds}s');

      // Emit final status
      _emitStatus(SyncStatus(
        isSyncing: false,
        isOnline: _isOnline,
        queuedOperations: _operationQueue.length,
        failedOperations: _failedOperations.length,
        lastSyncTime: _lastSyncTime,
        message: result.message,
        lastSyncResult: result,
      ));

      return result;
      
    } catch (e, st) {
      debugPrint('❌ OfflineSyncService: Sync failed: $e\n$st');
      
      _emitStatus(SyncStatus(
        isSyncing: false,
        isOnline: _isOnline,
        queuedOperations: _operationQueue.length,
        failedOperations: _failedOperations.length,
        lastSyncTime: _lastSyncTime,
        message: 'Sync failed: $e',
      ));
      
      return SyncResult(
        success: false,
        processed: 0,
        failed: _operationQueue.length,
        message: 'Sync failed: $e',
      );
      
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a single operation
  Future<void> _executeOperation(OfflineOperation operation) async {
    if (_pocketBase == null) {
      throw Exception('PocketBase client not initialized');
    }

    try {
      switch (operation.type) {
        case OperationType.create:
          await _pocketBase!.collection(operation.collection).create(
            body: operation.data,
          );
          break;
          
        case OperationType.update:
          await _pocketBase!.collection(operation.collection).update(
            operation.recordId,
            body: operation.data,
          );
          break;
          
        case OperationType.delete:
          await _pocketBase!.collection(operation.collection).delete(
            operation.recordId,
          );
          break;
          
        case OperationType.upsert:
          // Try update first, create if not exists
          try {
            await _pocketBase!.collection(operation.collection).update(
              operation.recordId,
              body: operation.data,
            );
          } catch (e) {
            if (e.toString().contains('404')) {
              await _pocketBase!.collection(operation.collection).create(
                body: {...operation.data, 'id': operation.recordId},
              );
            } else {
              rethrow;
            }
          }
          break;
      }
    } catch (e) {
      debugPrint('❌ OfflineSyncService: Failed to execute ${operation.type} on ${operation.collection}/${operation.recordId}: $e');
      rethrow;
    }
  }

  /// Check connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('⚠️ OfflineSyncService: Connectivity check failed: $e');
      return false;
    }
  }

  /// Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);
        
        debugPrint('🌐 OfflineSyncService: Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
        
        // Emit status
        _emitStatus(SyncStatus(
          isSyncing: _isSyncing,
          isOnline: _isOnline,
          queuedOperations: _operationQueue.length,
          failedOperations: _failedOperations.length,
          lastSyncTime: _lastSyncTime,
          message: _isOnline ? 'Connection restored' : 'Connection lost',
        ));
        
        // If just came online and has queued operations, sync
        if (_isOnline && !wasOnline && (_operationQueue.isNotEmpty || _failedOperations.isNotEmpty)) {
          debugPrint('🔄 OfflineSyncService: Connection restored - syncing queued operations...');
          await Future.delayed(const Duration(seconds: 2)); // Small delay to ensure connection is stable
          unawaited(syncAll());
        }
      },
    );
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_isOnline && !_isSyncing && (_operationQueue.isNotEmpty || _failedOperations.isNotEmpty)) {
        debugPrint('⏰ OfflineSyncService: Periodic sync triggered');
        await syncAll();
      }
    });
    
    debugPrint('⏰ OfflineSyncService: Periodic sync started (5 min interval)');
  }

  /// Load persisted data
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load queue
      final queueJson = prefs.getStringList(_queueKey) ?? [];
      _operationQueue.clear();
      for (final json in queueJson) {
        try {
          _operationQueue.add(OfflineOperation.fromJson(jsonDecode(json)));
        } catch (e) {
          debugPrint('⚠️ OfflineSyncService: Failed to parse queued operation: $e');
        }
      }
      
      // Load failed operations
      final failedJson = prefs.getStringList(_failedOperationsKey) ?? [];
      _failedOperations.clear();
      for (final json in failedJson) {
        try {
          _failedOperations.add(OfflineOperation.fromJson(jsonDecode(json)));
        } catch (e) {
          debugPrint('⚠️ OfflineSyncService: Failed to parse failed operation: $e');
        }
      }
      
      // Load last sync time
      final syncTimestamp = prefs.getString(_syncTimestampKey);
      if (syncTimestamp != null) {
        _lastSyncTime = DateTime.tryParse(syncTimestamp);
      }
      
      debugPrint('📊 OfflineSyncService: Loaded persisted data');
      debugPrint('   📝 Queued: ${_operationQueue.length}');
      debugPrint('   ❌ Failed: ${_failedOperations.length}');
      
    } catch (e, st) {
      debugPrint('❌ OfflineSyncService: Failed to load persisted data: $e\n$st');
    }
  }

  /// Persist queue
  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _operationQueue.map((op) => jsonEncode(op.toJson())).toList();
      await prefs.setStringList(_queueKey, queueJson);
    } catch (e) {
      debugPrint('❌ OfflineSyncService: Failed to persist queue: $e');
    }
  }

  /// Persist failed operations
  Future<void> _persistFailedOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedJson = _failedOperations.map((op) => jsonEncode(op.toJson())).toList();
      await prefs.setStringList(_failedOperationsKey, failedJson);
    } catch (e) {
      debugPrint('❌ OfflineSyncService: Failed to persist failed operations: $e');
    }
  }

  /// Persist sync status
  Future<void> _persistSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSyncTime != null) {
        await prefs.setString(_syncTimestampKey, _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      debugPrint('❌ OfflineSyncService: Failed to persist sync status: $e');
    }
  }

  /// Emit status update
  void _emitStatus(SyncStatus status) {
    if (_syncStatusController != null && !_syncStatusController!.isClosed) {
      _syncStatusController!.add(status);
    }
  }

  /// Get sync status stream
  Stream<SyncStatus>? get syncStatusStream => _syncStatusStream;

  /// Get current sync status
  SyncStatus getCurrentStatus() {
    return SyncStatus(
      isSyncing: _isSyncing,
      isOnline: _isOnline,
      queuedOperations: _operationQueue.length,
      failedOperations: _failedOperations.length,
      lastSyncTime: _lastSyncTime,
    );
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    _operationQueue.clear();
    await _persistQueue();
    debugPrint('🧹 OfflineSyncService: Queue cleared');
  }

  /// Clear failed operations
  Future<void> clearFailedOperations() async {
    _failedOperations.clear();
    await _persistFailedOperations();
    debugPrint('🧹 OfflineSyncService: Failed operations cleared');
  }

  /// Dispose
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    await _syncStatusController?.close();
    _isInitialized = false;
    debugPrint('🔌 OfflineSyncService: Disposed');
  }
}

/// Operation type enum
enum OperationType {
  create,
  update,
  delete,
  upsert,
}

/// Offline operation model
class OfflineOperation {
  final String id;
  final OperationType type;
  final String collection;
  final String recordId;
  final Map<String, dynamic> data;
  DateTime? timestamp;
  int retryCount;
  String? errorMessage;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.collection,
    required this.recordId,
    required this.data,
    this.timestamp,
    this.retryCount = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'collection': collection,
    'recordId': recordId,
    'data': data,
    'timestamp': timestamp?.toIso8601String(),
    'retryCount': retryCount,
    'errorMessage': errorMessage,
  };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: OperationType.values.firstWhere((e) => e.name == json['type']),
      collection: json['collection'],
      recordId: json['recordId'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      retryCount: json['retryCount'] ?? 0,
      errorMessage: json['errorMessage'],
    );
  }
}

/// Sync status model
class SyncStatus {
  final bool isSyncing;
  final bool isOnline;
  final int queuedOperations;
  final int failedOperations;
  final DateTime? lastSyncTime;
  final String? message;
  final double? progress;
  final SyncResult? lastSyncResult;

  SyncStatus({
    required this.isSyncing,
    required this.isOnline,
    required this.queuedOperations,
    required this.failedOperations,
    this.lastSyncTime,
    this.message,
    this.progress,
    this.lastSyncResult,
  });
}

/// Sync result model
class SyncResult {
  final bool success;
  final int processed;
  final int failed;
  final Duration? duration;
  final String message;

  SyncResult({
    required this.success,
    required this.processed,
    required this.failed,
    this.duration,
    required this.message,
  });
}
