import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/services/app_logger.dart';

import '../enums/log_level.dart';

class AppDebugLogger {
  static final AppDebugLogger _instance = AppDebugLogger._internal();
  factory AppDebugLogger() => _instance;
  AppDebugLogger._internal();

  static AppDebugLogger get instance => _instance;

  // Log levels for different types of operations
  
  // Current user context
  String? _currentUserId;
  String? _currentTripId;
  
  void setUserContext({String? userId, String? tripId}) {
    _currentUserId = userId;
    _currentTripId = tripId;
    logInfo('User context updated: User=$userId, Trip=$tripId');
  }

  // ===== AUTHENTICATION LOGS =====
  void logAuthStart(String email) {
    AppLogger.instance.logAuth(
      '🔐 Authentication started for: $email',
      level: LogLevel.info,
      userId: _currentUserId,
    );
    debugPrint('🔐 AUTH: Authentication started for: $email');
  }

  void logAuthSuccess(String userId, String userType) {
    AppLogger.instance.logAuth(
      '✅ Authentication successful - User: $userId, Type: $userType',
      level: LogLevel.success,
      userId: userId,
      details: 'User type: $userType',
    );
    debugPrint('✅ AUTH: Authentication successful - $userId ($userType)');
  }

  void logAuthError(String error, {String? userId}) {
    AppLogger.instance.logAuth(
      '❌ Authentication failed: $error',
      level: LogLevel.error,
      userId: userId ?? _currentUserId,
      details: error,
    );
    debugPrint('❌ AUTH: Authentication failed - $error');
  }

  void logLogout(String userId) {
    AppLogger.instance.logAuth(
      '👋 User logout: $userId',
      level: LogLevel.info,
      userId: userId,
    );
    debugPrint('👋 AUTH: User logout - $userId');
  }

  // ===== TRIP MANAGEMENT LOGS =====
  void logTripAcceptStart(String tripId, String qrCode) {
    AppLogger.instance.logTrip(
      '🎫 Trip acceptance started: $tripId (QR: $qrCode)',
      level: LogLevel.info,
      userId: _currentUserId,
      tripId: tripId,
      details: 'QR Code: $qrCode',
    );
    debugPrint('🎫 TRIP: Acceptance started - $tripId');
  }

  void logTripAcceptSuccess(String tripId, String tripNumber) {
    AppLogger.instance.logTrip(
      '✅ Trip accepted successfully: $tripNumber',
      level: LogLevel.success,
      userId: _currentUserId,
      tripId: tripId,
      details: 'Trip Number: $tripNumber',
    );
    debugPrint('✅ TRIP: Accepted successfully - $tripNumber');
  }

  void logTripError(String error, {String? tripId}) {
    AppLogger.instance.logTrip(
      '❌ Trip operation failed: $error',
      level: LogLevel.error,
      userId: _currentUserId,
      tripId: tripId ?? _currentTripId,
      details: error,
    );
    debugPrint('❌ TRIP: Operation failed - $error');
  }

  void logTripEnd(String tripId, int deliveriesCount) {
    AppLogger.instance.logTrip(
      '🏁 Trip ended: $tripId (Completed $deliveriesCount deliveries)',
      level: LogLevel.success,
      userId: _currentUserId,
      tripId: tripId,
      details: 'Deliveries completed: $deliveriesCount',
    );
    debugPrint('🏁 TRIP: Trip ended - $tripId ($deliveriesCount deliveries)');
  }

  // ===== DELIVERY LOGS =====
  void logDeliveryStatusUpdate(String customerId, String oldStatus, String newStatus) {
    AppLogger.instance.logDelivery(
      '📝 Delivery status updated: $oldStatus → $newStatus',
      level: LogLevel.info,
      userId: _currentUserId,
      tripId: _currentTripId,
      deliveryId: customerId,
      details: 'Status change: $oldStatus → $newStatus',
    );
    debugPrint('📝 DELIVERY: Status updated - $customerId: $oldStatus → $newStatus');
  }

  void logDeliveryArrival(String customerId, String location) {
    AppLogger.instance.logDelivery(
      '📍 Delivery arrival confirmed: $customerId',
      level: LogLevel.success,
      userId: _currentUserId,
      tripId: _currentTripId,
      deliveryId: customerId,
      details: 'Location: $location',
    );
    debugPrint('📍 DELIVERY: Arrival confirmed - $customerId at $location');
  }

  void logDeliveryCompletion(String customerId, String customerName, double totalAmount) {
    AppLogger.instance.logDelivery(
      '✅ Delivery completed: $customerName (₱${totalAmount.toStringAsFixed(2)})',
      level: LogLevel.success,
      userId: _currentUserId,
      tripId: _currentTripId,
      deliveryId: customerId,
      details: 'Customer: $customerName, Amount: ₱${totalAmount.toStringAsFixed(2)}',
    );
    debugPrint('✅ DELIVERY: Completed - $customerName (₱${totalAmount.toStringAsFixed(2)})');
  }

  void logDeliveryError(String customerId, String error) {
    AppLogger.instance.logDelivery(
      '❌ Delivery error: $error',
      level: LogLevel.error,
      userId: _currentUserId,
      tripId: _currentTripId,
      deliveryId: customerId,
      details: error,
    );
    debugPrint('❌ DELIVERY: Error - $customerId: $error');
  }

  // ===== INVOICE LOGS =====
  void logInvoiceStatusChange(String invoiceId, String status) {
    AppLogger.instance.logDelivery(
      '📋 Invoice status changed: $status',
      level: LogLevel.info,
      userId: _currentUserId,
      tripId: _currentTripId,
      deliveryId: invoiceId,
      details: 'Invoice ID: $invoiceId, Status: $status',
    );
    debugPrint('📋 INVOICE: Status changed - $invoiceId: $status');
  }

  void logInvoiceItemsLoad(String invoiceId, int itemCount) {
    AppLogger.instance.logDelivery(
      '📦 Invoice items loaded: $itemCount items',
      level: LogLevel.info,
      userId: _currentUserId,
      tripId: _currentTripId,
      deliveryId: invoiceId,
      details: 'Invoice: $invoiceId, Items: $itemCount',
    );
    debugPrint('📦 INVOICE: Items loaded - $invoiceId: $itemCount items');
  }

  // ===== SYNC LOGS =====
  void logSyncStart(String operation) {
    AppLogger.instance.logSync(
      '🔄 Sync started: $operation',
      level: LogLevel.info,
      userId: _currentUserId,
      details: operation,
    );
    debugPrint('🔄 SYNC: Started - $operation');
  }

  void logSyncSuccess(String operation, {String? details}) {
    AppLogger.instance.logSync(
      '✅ Sync completed: $operation',
      level: LogLevel.success,
      userId: _currentUserId,
      details: details ?? operation,
    );
    debugPrint('✅ SYNC: Completed - $operation');
  }

  void logSyncError(String operation, String error) {
    AppLogger.instance.logSync(
      '❌ Sync failed: $operation - $error',
      level: LogLevel.error,
      userId: _currentUserId,
      details: 'Operation: $operation, Error: $error',
    );
    debugPrint('❌ SYNC: Failed - $operation: $error');
  }

  // ===== LOGS SYNC TO REMOTE =====
  void logRemoteSyncStart(int unsyncedCount) {
    logInfo('☁️ Starting remote logs sync', details: 'Unsynced logs: $unsyncedCount');
  }

  void logRemoteSyncSuccess(int syncedCount) {
    logSuccess('☁️ Remote logs sync completed', details: 'Synced $syncedCount logs to PocketBase');
  }

  void logRemoteSyncError(String error) {
    logError('☁️ Remote logs sync failed', details: error);
  }

  // ===== NETWORK LOGS =====
  void logNetworkRequest(String endpoint, String method) {
    AppLogger.instance.logNetwork(
      '📡 API Request: $method $endpoint',
      level: LogLevel.info,
      details: 'Method: $method, Endpoint: $endpoint',
    );
    debugPrint('📡 NETWORK: Request - $method $endpoint');
  }

  void logNetworkSuccess(String endpoint, int statusCode, {String? details}) {
    AppLogger.instance.logNetwork(
      '✅ API Success: $endpoint (${statusCode})',
      level: LogLevel.success,
      details: details ?? 'Status: $statusCode',
    );
    debugPrint('✅ NETWORK: Success - $endpoint ($statusCode)');
  }

  void logNetworkError(String endpoint, String error, {int? statusCode}) {
    AppLogger.instance.logNetwork(
      '❌ API Error: $endpoint - $error',
      level: LogLevel.error,
      details: 'Endpoint: $endpoint, Error: $error, Status: ${statusCode ?? 'Unknown'}',
    );
    debugPrint('❌ NETWORK: Error - $endpoint: $error');
  }

  // ===== NAVIGATION LOGS =====
  void logNavigation(String from, String to, {String? reason}) {
    logInfo('🧭 Navigation: $from → $to${reason != null ? ' ($reason)' : ''}');
    debugPrint('🧭 NAV: $from → $to${reason != null ? ' ($reason)' : ''}');
  }

  void logNavigationError(String route, String error) {
    logError('❌ Navigation failed: $route - $error');
    debugPrint('❌ NAV: Failed to navigate to $route - $error');
  }

  // ===== PERMISSION LOGS =====
  void logPermissionRequest(String permission) {
    logInfo('🔐 Permission requested: $permission');
    debugPrint('🔐 PERMISSION: Requested - $permission');
  }

  void logPermissionGranted(String permission) {
    logSuccess('✅ Permission granted: $permission');
    debugPrint('✅ PERMISSION: Granted - $permission');
  }

  void logPermissionDenied(String permission) {
    logWarning('⚠️ Permission denied: $permission');
    debugPrint('⚠️ PERMISSION: Denied - $permission');
  }

  // ===== GENERAL LOGS =====
  void logInfo(String message, {String? details}) {
    AppLogger.instance.logSync(
      message,
      level: LogLevel.info,
      userId: _currentUserId,
      details: details,
    );
    debugPrint('ℹ️ INFO: $message');
  }

  void logSuccess(String message, {String? details}) {
    AppLogger.instance.logSync(
      message,
      level: LogLevel.success,
      userId: _currentUserId,
      details: details,
    );
    debugPrint('✅ SUCCESS: $message');
  }

  void logWarning(String message, {String? details}) {
    AppLogger.instance.logSync(
      message,
      level: LogLevel.warning,
      userId: _currentUserId,
      details: details,
    );
    debugPrint('⚠️ WARNING: $message');
  }

  void logError(String message, {String? details, String? stackTrace}) {
    AppLogger.instance.logSync(
      message,
      level: LogLevel.error,
      userId: _currentUserId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('❌ ERROR: $message');
  }

  void logDebug(String message, {String? details}) {
    AppLogger.instance.logSync(
      message,
      level: LogLevel.info,
      userId: _currentUserId,
      details: details,
    );
    debugPrint('🐛 DEBUG: $message');
  }

  // ===== BLOC STATE LOGS =====
  void logBlocEvent(String blocName, String event, {String? details}) {
    logInfo('📤 BLoC Event: $blocName → $event', details: details);
  }

  void logBlocState(String blocName, String state, {String? details}) {
    logInfo('📥 BLoC State: $blocName → $state', details: details);
  }

  void logBlocError(String blocName, String error) {
    logError('❌ BLoC Error: $blocName - $error');
  }

  // ===== DATA LOADING LOGS =====
  void logDataLoadStart(String dataType, String operation) {
    logInfo('📥 Loading: $dataType ($operation)');
  }

  void logDataLoadSuccess(String dataType, int count, {String? details}) {
    logSuccess('✅ Loaded: $dataType - $count items', details: details);
  }

  void logDataLoadError(String dataType, String error) {
    logError('❌ Load Failed: $dataType - $error');
  }

  // ===== PERFORMANCE LOGS =====
  void logPerformance(String operation, Duration duration, {String? details}) {
    final message = '⚡ Performance: $operation took ${duration.inMilliseconds}ms';
    if (duration.inMilliseconds > 1000) {
      logWarning(message, details: details);
    } else {
      logInfo(message, details: details);
    }
  }

  void logMemoryUsage(String context, {String? details}) {
    logDebug('💾 Memory: $context', details: details);
  }
}

// Extension to easily add logging to any widget
extension WidgetLogging on State {
  AppDebugLogger get logger => AppDebugLogger.instance;
}

// Extension to easily add logging to any class
extension ClassLogging on Object {
  AppDebugLogger get logger => AppDebugLogger.instance;
}
