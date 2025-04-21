import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  StreamSubscription? _subscription;
  final _connectivity = Connectivity();

  ConnectivityProvider() {
    _checkInitialConnection();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _isOnline = results.contains(ConnectivityResult.wifi) || 
                  results.contains(ConnectivityResult.mobile);
      debugPrint('🌐 Connection Status: $results');
      debugPrint(_isOnline ? '✅ Device is online' : '❌ Device is offline');
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

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
