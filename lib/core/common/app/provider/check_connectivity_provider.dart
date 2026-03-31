import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  int _latency = 0;
int get latency => _latency;

String _connectionType = 'unknown';
String get connectionType => _connectionType;
  
  StreamSubscription? _subscription;
  final _connectivity = Connectivity();
  
  // Track sync status
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  // Track last sync time
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  // Track pending sync operations
  final List<String> _pendingSyncOperations = [];
  List<String> get pendingSyncOperations => List.unmodifiable(_pendingSyncOperations);

  ConnectivityProvider() {
    _checkInitialConnection();
   _subscription = _connectivity.onConnectivityChanged.listen((results) async {
  final wasOnline = _isOnline;

  final hasInternet = await InternetConnection().hasInternetAccess;

  // measure latency
  final start = DateTime.now();
  await InternetConnection().hasInternetAccess;
  _latency = DateTime.now().difference(start).inMilliseconds;

  _isOnline = hasInternet;

  if (results.contains(ConnectivityResult.wifi)) {
    _connectionType = 'wifi';
  } else if (results.contains(ConnectivityResult.mobile)) {
    _connectionType = 'mobile';
  } else {
    _connectionType = 'none';
  }

  debugPrint('🌐 Connection: $_connectionType');
  debugPrint('📡 Online: $_isOnline');
  debugPrint('⏱ Latency: ${_latency}ms');

  if (!wasOnline && _isOnline) {
    _triggerAutoSync();
  }

  if (!disposed) {
    notifyListeners();
  }
});
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.contains(ConnectivityResult.wifi) || 
                results.contains(ConnectivityResult.mobile);
    debugPrint('📡 Initial Connection Check: $results');
    debugPrint(_isOnline ? '✅ Initial status: Online' : '❌ Initial status: Offline');
    notifyListeners();
  }

  void addPendingSyncOperation(String operation) {
    if (!_pendingSyncOperations.contains(operation)) {
      _pendingSyncOperations.add(operation);
      debugPrint('📝 Added pending sync operation: $operation');
      notifyListeners();
    }
  }

  void removePendingSyncOperation(String operation) {
    _pendingSyncOperations.remove(operation);
    debugPrint('✅ Completed sync operation: $operation');
    notifyListeners();
  }

  void _triggerAutoSync() {
    if (_isSyncing || !_isOnline) return;
    
    debugPrint('🔄 Auto-sync triggered after connectivity restoration');
    _isSyncing = true;
    notifyListeners();
    
    // Process any pending sync operations when connection is restored
    Future.delayed(const Duration(seconds: 2), () {
      if (_isOnline && _pendingSyncOperations.isNotEmpty) {
        debugPrint('📋 Processing ${_pendingSyncOperations.length} pending operations');
        // Signal that pending operations should be processed
        _processPendingOperations();
      }
      _isSyncing = false;
      notifyListeners();
    });
  }

  void _processPendingOperations() {
    // Create a copy of pending operations
    final operationsToProcess = List<String>.from(_pendingSyncOperations);
    
    // Clear the pending list
    _pendingSyncOperations.clear();
    
    debugPrint('📤 Processing ${operationsToProcess.length} pending sync operations');
    
    // Here you can emit an event or call a callback to process operations
    // This will be handled by the sync service
    notifyListeners();
  }

  void setSyncStatus(bool syncing) {
    _isSyncing = syncing;
    if (!syncing) {
      _lastSyncTime = DateTime.now();
    }
    notifyListeners();
  }

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
