import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_bloc.dart';
import 'package:x_pro_delivery_app/core/common/widgets/debug_console.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';

import '../../services/injection_container.dart';

/// Wrapper widget that adds debug console to any screen
/// Usage: Wrap your main app or specific screens with this widget
class AppWithDebugConsole extends StatefulWidget {
  final Widget child;
  final bool showDebugConsole;

  const AppWithDebugConsole({
    super.key,
    required this.child,
    this.showDebugConsole = true, // Set to false for production
  });

  @override
  State<AppWithDebugConsole> createState() => _AppWithDebugConsoleState();
}

class _AppWithDebugConsoleState extends State<AppWithDebugConsole> {
  @override
  void initState() {
    super.initState();
    // Initialize logging when app starts
    AppDebugLogger.instance.logInfo('🚀 App started with debug console enabled');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showDebugConsole) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        // Debug console overlay
        BlocProvider(
          create: (context) => sl<LogsBloc>(),
          child: const DebugConsole(),
        ),
      ],
    );
  }
}

// Extension to easily add debug console to MaterialApp
extension DebugConsoleApp on MaterialApp {
  Widget withDebugConsole({bool enabled = true}) {
    return AppWithDebugConsole(
      showDebugConsole: enabled,
      child: this,
    );
  }
}

// Quick access methods for common logging patterns
class AppLogger {
  static void logScreenEntry(String screenName) {
    AppDebugLogger.instance.logNavigation('Previous', screenName, reason: 'Screen entered');
  }

  static void logScreenExit(String screenName) {
    AppDebugLogger.instance.logNavigation(screenName, 'Next', reason: 'Screen exited');
  }

  static void logBlocEvent(String blocName, String eventName, {Map<String, dynamic>? params}) {
    String details = '';
    if (params != null && params.isNotEmpty) {
      details = 'Params: ${params.toString()}';
    }
    AppDebugLogger.instance.logBlocEvent(blocName, eventName, details: details);
  }

  static void logBlocState(String blocName, String stateName, {Map<String, dynamic>? data}) {
    String details = '';
    if (data != null && data.isNotEmpty) {
      details = 'Data: ${data.toString()}';
    }
    AppDebugLogger.instance.logBlocState(blocName, stateName, details: details);
  }

  static void logApiCall(String endpoint, String method, {Map<String, dynamic>? params}) {
    if (params != null && params.isNotEmpty) {
    }
    AppDebugLogger.instance.logNetworkRequest(endpoint, method);
  }

  static void logApiSuccess(String endpoint, int statusCode, {dynamic responseData}) {
    String details = 'Status: $statusCode';
    if (responseData != null) {
      details += ', Response: ${responseData.toString()}';
    }
    AppDebugLogger.instance.logNetworkSuccess(endpoint, statusCode, details: details);
  }

  static void logApiError(String endpoint, String error, {int? statusCode}) {
    AppDebugLogger.instance.logNetworkError(endpoint, error, statusCode: statusCode);
  }

  static void logUserAction(String action, {String? details}) {
    AppDebugLogger.instance.logInfo('👆 User Action: $action', details: details);
  }

  static void logDataLoad(String dataType, String operation) {
    AppDebugLogger.instance.logDataLoadStart(dataType, operation);
  }

  static void logDataLoadComplete(String dataType, int count) {
    AppDebugLogger.instance.logDataLoadSuccess(dataType, count);
  }

  static void logError(String operation, String error, {String? stackTrace}) {
    AppDebugLogger.instance.logError('❌ $operation failed: $error', 
      details: error, 
      stackTrace: stackTrace
    );
  }
}
