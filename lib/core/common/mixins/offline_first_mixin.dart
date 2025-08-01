import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';

/// Mixin that provides offline-first functionality to BLoCs
/// 
/// This mixin implements the pattern:
/// 1. Load local data immediately for instant UI
/// 2. Attempt remote sync if online
/// 3. Handle network failures gracefully
/// 4. Cache remote data when successful
mixin OfflineFirstMixin<Event, State> on BlocBase<State> {
  
  /// Executes an offline-first operation
  /// 
  /// [localOperation] - Function that loads data from local storage
  /// [remoteOperation] - Function that loads data from remote API
  /// [onLocalSuccess] - Callback when local data is loaded successfully
  /// [onRemoteSuccess] - Callback when remote data is loaded successfully
  /// [onError] - Callback when both local and remote operations fail
  /// [connectivity] - Connectivity provider to check network status
  Future<void> executeOfflineFirst({
    required Future<void> Function() localOperation,
    required Future<void> Function() remoteOperation,
    required Function(dynamic data) onLocalSuccess,
    required Function(dynamic data) onRemoteSuccess,
    required Function(String error) onError,
    required ConnectivityProvider connectivity,
    bool forceRemote = false,
  }) async {
    bool localSucceeded = false;
    
    try {
      // 📱 STEP 1: Always try local first for instant UI
      debugPrint('📱 OFFLINE-FIRST: Loading local data...');
      await localOperation();
      localSucceeded = true;
      debugPrint('✅ Local data loaded successfully');
    } catch (e) {
      debugPrint('⚠️ Local data not available: $e');
    }
    
    // 🌐 STEP 2: Try remote if online or forced
    if (connectivity.isOnline || forceRemote) {
      try {
        debugPrint('🌐 OFFLINE-FIRST: Syncing remote data...');
        await remoteOperation();
        debugPrint('✅ Remote data synced successfully');
      } catch (e) {
        debugPrint('❌ Remote sync failed: $e');
        
        // If local also failed, report error
        if (!localSucceeded) {
          onError('No data available: Local and remote failed');
        } else {
          debugPrint('📱 Using cached data due to remote failure');
        }
      }
    } else {
      debugPrint('📱 OFFLINE: Using cached data only');
      
      // If offline and no local data, report error
      if (!localSucceeded) {
        onError('No cached data available and device is offline');
      }
    }
  }
  
  /// Queues an operation for later execution when online
  void queueForLaterSync(String operationId, Map<String, dynamic> data) {
    debugPrint('📝 Queuing operation for later sync: $operationId');
    // This would integrate with your sync service
  }
  
  /// Handles network state changes
  void onNetworkStateChanged(bool isOnline) {
    if (isOnline) {
      debugPrint('🌐 Network restored - triggering sync');
      // Trigger any pending sync operations
    } else {
      debugPrint('📱 Network lost - switching to offline mode');
    }
  }
}

/// Extension to provide offline-first functionality to any BLoC
extension OfflineFirstExtension<Event, State> on BlocBase<State> {
  
  /// Helper method to check if data is fresh enough
  bool isDataFresh(DateTime? lastSync, {Duration maxAge = const Duration(minutes: 5)}) {
    if (lastSync == null) return false;
    return DateTime.now().difference(lastSync) < maxAge;
  }
  
  /// Helper method to determine sync strategy based on network quality
  SyncStrategy getSyncStrategy(ConnectivityProvider connectivity) {
    if (!connectivity.isOnline) {
      return SyncStrategy.cacheOnly;
    }
    
    // You could add network quality detection here
    // For now, always use smartSync when online
    return SyncStrategy.smartSync;
  }
}

/// Enum defining different sync strategies
enum SyncStrategy {
  /// Only use cached data
  cacheOnly,
  
  /// Load cache first, then sync in background
  smartSync,
  
  /// Force remote sync (for refresh scenarios)
  forceRemote,
}

/// Helper class for managing offline-first state
class OfflineFirstState<T> {
  final T? cachedData;
  final T? remoteData;
  final bool isLoading;
  final bool isOffline;
  final String? error;
  final DateTime? lastSync;
  
  const OfflineFirstState({
    this.cachedData,
    this.remoteData,
    this.isLoading = false,
    this.isOffline = false,
    this.error,
    this.lastSync,
  });
  
  /// Get the best available data (remote if available, otherwise cached)
  T? get bestData => remoteData ?? cachedData;
  
  /// Check if we have any data available
  bool get hasData => bestData != null;
  
  /// Check if we're showing cached data
  bool get isShowingCachedData => cachedData != null && remoteData == null;
  
  OfflineFirstState<T> copyWith({
    T? cachedData,
    T? remoteData,
    bool? isLoading,
    bool? isOffline,
    String? error,
    DateTime? lastSync,
  }) {
    return OfflineFirstState<T>(
      cachedData: cachedData ?? this.cachedData,
      remoteData: remoteData ?? this.remoteData,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      error: error ?? this.error,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
