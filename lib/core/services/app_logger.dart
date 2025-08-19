import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/usecases/add_log.dart';

import '../enums/log_level.dart';

class AppLogger {
  static AppLogger? _instance;
  static AppLogger get instance => _instance ??= AppLogger._internal();
  
  AppLogger._internal();

  AddLog? _addLog;

  void initialize(AddLog addLog) {
    _addLog = addLog;
    debugPrint('📝 AppLogger initialized');
  }

  void debug(
    String message, {
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: LogLevel.debug,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('🔍 [DEBUG] $message');
  }

  void info(
    String message, {
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: LogLevel.info,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('ℹ️ [INFO] $message');
  }

  void warning(
    String message, {
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: LogLevel.warning,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('⚠️ [WARNING] $message');
  }

  void error(
    String message, {
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: LogLevel.error,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('❌ [ERROR] $message');
  }

  void success(
    String message, {
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: LogLevel.success,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('✅ [SUCCESS] $message');
  }

  // Specific logging methods for different categories
  void logAuth(
    String message, {
    LogLevel level = LogLevel.info,
    String? userId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: level,
      category: LogCategory.authentication,
      userId: userId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('🔐 [AUTH] $message');
  }

  void logTrip(
    String message, {
    LogLevel level = LogLevel.info,
    String? userId,
    String? tripId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: level,
      category: LogCategory.tripManagement,
      userId: userId,
      tripId: tripId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('🚚 [TRIP] $message');
  }

  void logDelivery(
    String message, {
    LogLevel level = LogLevel.info,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: level,
      category: LogCategory.deliveryUpdate,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('📦 [DELIVERY] $message');
  }

  void logReceipt(
    String message, {
    LogLevel level = LogLevel.info,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: level,
      category: LogCategory.deliveryReceipt,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('🧾 [RECEIPT] $message');
  }

  void logSync(
    String message, {
    LogLevel level = LogLevel.info,
    String? userId,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: level,
      category: LogCategory.sync,
      userId: userId,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('🔄 [SYNC] $message');
  }

  void logNetwork(
    String message, {
    LogLevel level = LogLevel.info,
    String? details,
    String? stackTrace,
  }) {
    _log(
      message: message,
      level: level,
      category: LogCategory.network,
      details: details,
      stackTrace: stackTrace,
    );
    debugPrint('🌐 [NETWORK] $message');
  }

  void _log({
    required String message,
    required LogLevel level,
    required LogCategory category,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    if (_addLog == null) {
      debugPrint('⚠️ AppLogger not initialized, log not stored: $message');
      return;
    }

    final logEntry = LogEntryEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      level: level,
      category: category,
      timestamp: DateTime.now(),
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );

    _addLog!(AddLogParams(logEntry: logEntry));
  }
}

// Extension methods for easier usage
extension AppLoggerExtension on String {
  void logDebug({
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
  }) {
    AppLogger.instance.debug(
      this,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
    );
  }

  void logInfo({
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
  }) {
    AppLogger.instance.info(
      this,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
    );
  }

  void logWarning({
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
  }) {
    AppLogger.instance.warning(
      this,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
    );
  }

  void logError({
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
    String? stackTrace,
  }) {
    AppLogger.instance.error(
      this,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
      stackTrace: stackTrace,
    );
  }

  void logSuccess({
    LogCategory category = LogCategory.general,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? details,
  }) {
    AppLogger.instance.success(
      this,
      category: category,
      userId: userId,
      tripId: tripId,
      deliveryId: deliveryId,
      details: details,
    );
  }
}
