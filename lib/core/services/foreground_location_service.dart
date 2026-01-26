import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';

/// 🎯 FOREGROUND LOCATION SERVICE
/// This service runs continuously in the background with a persistent notification
/// It tracks GPS location even when:
/// - App is closed
/// - Device is sleeping
/// - Screen is off
///
/// Key Features:
/// - Continuous tracking (every 1-2 minutes)
/// - Survives app closure
/// - Survives device sleep
/// - Shows persistent notification
/// - Battery optimized

class ForegroundLocationService {
  static const String _notificationChannelId = 'trip_tracking_channel';
  static const String _notificationChannelName = 'Trip Tracking';

  /// Initialize the foreground service
  static Future<void> initialize() async {
    debugPrint('🔧 Initializing Foreground Location Service...');

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _notificationChannelId,
        channelName: _notificationChannelName,
        channelDescription: 'Tracks your delivery trip location in real-time',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // 1 minute
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    debugPrint('✅ Foreground service initialized');
  }

  /// Start tracking location with foreground service
  static Future<bool> startTracking({
    required String tripId,
    String pocketBaseUrl = 'https://delivery-app.winganmarketing.com',
  }) async {
    try {
      debugPrint('🚀 Starting foreground location tracking...');
      debugPrint('   📋 Trip ID: $tripId');
      debugPrint('   🌐 API URL: $pocketBaseUrl');

      // Check if service is already running
      try {
        final dynamic isRunning = await FlutterForegroundTask.isRunningService;
        final bool serviceRunning =
            isRunning == true || isRunning.toString() == 'true';
        if (serviceRunning) {
          debugPrint('⚠️ Service already running, stopping first...');
          await stopTracking();
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        debugPrint('⚠️ Could not check service status: $e');
      }

      // Check and request notification permission properly
      final notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission == NotificationPermission.denied ||
          notificationPermission == NotificationPermission.permanently_denied) {
        NotificationPermission? result;
        try {
          result = await FlutterForegroundTask.requestNotificationPermission();
        } on PlatformException catch (e) {
          debugPrint(
            '❌ Notification permission request failed: ${e.code} - ${e.message}',
          );
          // If the user canceled the dialog or system cancelled the request,
          // treat it as a denial and surface a clear message.
          if (e.code == 'PermissionRequestCancelledException' ||
              e.code == 'PERMISSION_REQUEST_CANCELLED') {
            debugPrint(
              '⚠️ Notification permission request was cancelled by the user or system.',
            );
          }
          return false;
        } catch (e) {
          debugPrint(
            '❌ Unexpected error requesting notification permission: $e',
          );
          return false;
        }

        if (result == NotificationPermission.denied ||
            result == NotificationPermission.permanently_denied) {
          debugPrint('❌ Notification permission was not granted.');
          return false;
        }

        // Give Android a small delay to stabilize after dialog closes
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Save tracking parameters
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tracking_trip_id', tripId);
      await prefs.setString('tracking_pb_url', pocketBaseUrl);
      await prefs.setString(
        'tracking_start_time',
        DateTime.now().toIso8601String(),
      );

      // Start the foreground service
      await FlutterForegroundTask.startService(
        notificationTitle: 'Trip Tracking Active',
        notificationText: 'Tracking your delivery route...',
        callback: startCallback,
      );

      // Optional: Verify if it actually started
      final isRunningNow = await FlutterForegroundTask.isRunningService;
      final bool startedSuccessfully =
          isRunningNow == true || isRunningNow.toString() == 'true';

      if (startedSuccessfully) {
        debugPrint('✅ Foreground service started successfully');
        debugPrint('   📍 Updates every 1 minute');
        debugPrint('   🔋 Battery optimized with wake locks');
        return true;
      } else {
        debugPrint('❌ Failed to start foreground service');
        return false;
      }
    } catch (e, st) {
      debugPrint('❌ Error starting foreground tracking: $e');
      debugPrint('Stack trace: $st');
      return false;
    }
  }

  /// Stop tracking
  static Future<bool> stopTracking() async {
    try {
      debugPrint('🛑 Stopping foreground location tracking...');

      // Attempt to stop the service (no direct boolean return)
      await FlutterForegroundTask.stopService();

      // Check if the service actually stopped
      final dynamic isRunning = await FlutterForegroundTask.isRunningService;
      final bool isStillRunning =
          isRunning == true || isRunning.toString() == 'true';

      if (!isStillRunning) {
        // Clear tracking parameters
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('tracking_trip_id');
        await prefs.remove('tracking_pb_url');
        await prefs.remove('tracking_start_time');

        debugPrint('✅ Foreground service stopped successfully');
        return true;
      } else {
        debugPrint('⚠️ Service may still be running');
        return false;
      }
    } catch (e, st) {
      debugPrint('❌ Error stopping foreground tracking: $e');
      debugPrint('Stack trace: $st');
      return false;
    }
  }

  /// Check if tracking is active
  static Future<bool> isTracking() async {
    return await FlutterForegroundTask.isRunningService;
  }

  /// Get tracking info
  static Future<Map<String, dynamic>?> getTrackingInfo() async {
    try {
      final dynamic isRunning = await FlutterForegroundTask.isRunningService;
      final bool serviceRunning =
          isRunning == true || isRunning.toString() == 'true';
      if (!serviceRunning) return null;

      final prefs = await SharedPreferences.getInstance();
      return {
        'isActive': true,
        'tripId': prefs.getString('tracking_trip_id'),
        'startTime': prefs.getString('tracking_start_time'),
        'apiUrl': prefs.getString('tracking_pb_url'),
      };
    } catch (e) {
      debugPrint('⚠️ Error getting tracking info: $e');
      return null;
    }
  }

  /// Update notification content
  static Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }
}

/// 🎯 FOREGROUND TASK CALLBACK
/// This runs in a separate isolate and handles the background location updates
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

/// 🎯 LOCATION TASK HANDLER
/// Handles location updates in the background isolate
class LocationTaskHandler extends TaskHandler {
  int _updateCount = 0;
  DateTime? _lastUpdate;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint(
      '🚀 LocationTaskHandler started at ${timestamp.toIso8601String()}',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateCount++;
    final now = DateTime.now();

    debugPrint(
      '🔄 Background location update #$_updateCount at ${now.toIso8601String()}',
    );

    // Run the async work
    _performLocationUpdate(now);
  }

  Future<void> _performLocationUpdate(DateTime now) async {
    try {
      // Get tracking parameters
      final prefs = await SharedPreferences.getInstance();
      final tripId = prefs.getString('tracking_trip_id');
      final pbUrl =
          prefs.getString('tracking_pb_url') ??
          'https://delivery-app.winganmarketing.com';

      if (tripId == null || tripId.isEmpty) {
        debugPrint('❌ No trip ID found, stopping service');
        FlutterForegroundTask.stopService();
        return;
      }

      // Check location services
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services disabled');
        _updateNotification(
          'Location Services Off',
          'Please enable location to continue tracking',
        );
        return;
      }

      // Check permissions - require BACKGROUND (ALWAYS) permission for background updates
      final permission = await Geolocator.checkPermission();
      debugPrint('🔐 Background permission check: $permission');

      // On Android 11+ (and especially newer versions) "whileInUse" is insufficient
      // for background/foreground-service location updates. Require LocationPermission.always.
      if (permission != LocationPermission.always) {
        debugPrint('❌ Background location (ALWAYS) not granted: $permission');
        _updateNotification(
          'Background Location Required',
          'Please grant "Allow all the time" location permission for tracking',
        );
        return;
      }

      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 30));
      } catch (e) {
        debugPrint('⚠️ Failed to get current position: $e');
        // Try last known position
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          debugPrint('❌ No location available');
          _updateNotification(
            'Waiting for GPS',
            'Searching for location signal...',
          );
          return;
        }
        debugPrint('📍 Using last known position');
      }

      final lat = position.latitude;
      final lng = position.longitude;
      final accuracy = position.accuracy;
      final nowIso = DateTime.now().toUtc().toIso8601String();

      debugPrint('📍 Location obtained:');
      debugPrint('   Lat: $lat, Lng: $lng');
      debugPrint('   Accuracy: ${accuracy.toStringAsFixed(2)}m');
      debugPrint('   Time: ${position.timestamp}');

      // Update PocketBase
      final pb = PocketBase(pbUrl);

      // Restore auth token
      final token = prefs.getString('pb_auth_token');
      if (token != null && token.isNotEmpty) {
        pb.authStore.save(token, null);
      }

      // Update tripticket
      bool updated = false;
      try {
        await pb
            .collection('tripticket')
            .update(
              tripId,
              body: {
                'latitude': lat,
                'longitude': lng,
                'lastLocationUpdated': nowIso,
              },
            )
            .timeout(const Duration(seconds: 15));

        updated = true;
        debugPrint('✅ Location updated in PocketBase');
      } catch (e) {
        debugPrint('❌ Failed to update PocketBase: $e');
      }

      // Save coordinate record
      try {
        await pb
            .collection('tripCoordinatesUpdates')
            .create(
              body: {
                'trip': tripId,
                'latitude': lat,
                'longitude': lng,
                'recordedAt': nowIso,
                'accuracy': accuracy,
                'speed': position.speed,
                'altitude': position.altitude,
              },
            )
            .timeout(const Duration(seconds: 15));

        debugPrint('📦 Coordinate saved to history');
      } catch (e) {
        debugPrint('⚠️ Failed to save coordinate updates: $e');
      }

      // Update notification with success status
      if (updated) {
        final timeSince =
            _lastUpdate != null ? now.difference(_lastUpdate!).inMinutes : 0;
        _updateNotification(
          'Trip Tracking Active',
          'Last updated: ${_formatTime(now)} (${timeSince}m ago)',
        );
        _lastUpdate = now;
      }
    } catch (e, st) {
      debugPrint('❌ Error in background location update: $e');
      debugPrint('Stack trace: $st');
      _updateNotification('Tracking Error', 'Will retry on next interval');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint(
      '🛑 LocationTaskHandler destroyed at ${timestamp.toIso8601String()}',
    );
  }

  void onButtonPressed(String id) {
    debugPrint('🔘 Button pressed: $id');
    if (id == 'btn_stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    debugPrint('🔔 Notification pressed');
    FlutterForegroundTask.launchApp("/");
  }

  /// Update notification helper
  void _updateNotification(String title, String text) {
    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
