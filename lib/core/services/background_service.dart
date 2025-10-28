import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

const String taskName = 'trackTripCoordinates';

/// Top-level callback dispatcher for WorkManager
/// This function runs in an isolate, so it cannot access LocationService
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final startTime = DateTime.now();
    debugPrint('🚚 WorkManager Task Started: $task at ${startTime.toIso8601String()}');

    if (task != taskName) {
      debugPrint('⚠️ Unknown task: $task');
      return Future.value(false);
    }

    try {
      // Add timeout to prevent WorkManager from killing the task (10 min limit)
      return await Future.any([
        _executeLocationTracking(inputData),
        Future.delayed(const Duration(minutes: 9), () {
          debugPrint('⏱️ Task timeout approaching - completing early');
          return false;
        }),
      ]);
    } catch (e, st) {
      debugPrint('❌ Background task error: $e\n$st');
      return Future.value(false); // Return false to retry
    } finally {
      final duration = DateTime.now().difference(startTime);
      debugPrint('⏱️ Task completed in ${duration.inSeconds}s');
    }
  });
}

/// Execute location tracking and update PocketBase
Future<bool> _executeLocationTracking(Map<String, dynamic>? inputData) async {
  try {
    final tripId = inputData?['tripId'] as String?;
    final pocketBaseUrl = inputData?['pocketBaseUrl'] as String? ??
        'https://delivery-app.winganmarketing.com';

    if (tripId == null || tripId.isEmpty) {
      debugPrint('❌ No tripId provided');
      return false;
    }

    debugPrint('🎯 Tracking trip: $tripId');

    // 🔹 STEP 1: Check location services
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled');
      return false;
    }

    // 🔹 STEP 2: Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permission denied: $permission');
      return false;
    }

    // 🔹 STEP 3: Get location with timeout
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () async {
          debugPrint('⏱️ Location request timed out - using last known position');
          final lastPos = await Geolocator.getLastKnownPosition();
          if (lastPos == null) {
            throw Exception('No location available');
          }
          return lastPos;
        },
      );
    } catch (e) {
      debugPrint('⚠️ Failed to get current position, trying last known: $e');
      position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        debugPrint('❌ No location available');
        return false;
      }
    }

    final lat = position.latitude;
    final lng = position.longitude;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    debugPrint('📍 Location obtained: ($lat, $lng)');
    debugPrint('   🎯 Accuracy: ${position.accuracy.toStringAsFixed(2)}m');
    debugPrint('   ⏰ Timestamp: ${position.timestamp}');

    // 🔹 STEP 4: Connect to PocketBase with timeout
    final pb = PocketBase(pocketBaseUrl);

    // Restore auth token
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('pb_auth_token');
      if (token != null && token.isNotEmpty) {
        pb.authStore.save(token, null);
        debugPrint('🔐 PocketBase token restored');
      } else {
        debugPrint('⚠️ No auth token found - updates may fail');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to restore auth token: $e');
    }

    // 🔹 STEP 5: Update tripticket (primary update)
    bool tripticketUpdated = false;
    try {
      await pb.collection('tripticket').update(
        tripId,
        body: {
          'latitude': lat,
          'longitude': lng,
          'lastLocationUpdated': nowIso,
        },
      ).timeout(const Duration(seconds: 15));

      tripticketUpdated = true;
      debugPrint('✅ tripticket updated successfully');
    } catch (e) {
      debugPrint('❌ Failed to update tripticket: $e');
      // Don't return false yet - try to save coordinate
    }

    // 🔹 STEP 6: Save in tripCoordinates (secondary, optional)
    bool coordinateSaved = false;
    try {
      await pb.collection('tripCoordinates').create(
        body: {
          'trip': tripId,
          'latitude': lat,
          'longitude': lng,
          'recordedAt': nowIso,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'altitude': position.altitude,
        },
      ).timeout(const Duration(seconds: 15));

      coordinateSaved = true;
      debugPrint('📦 tripCoordinates saved successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to save tripCoordinates: $e');
    }

    // Success if either update worked
    final success = tripticketUpdated || coordinateSaved;
    if (success) {
      debugPrint('✅ Background tracking completed successfully');
    } else {
      debugPrint('❌ All updates failed');
    }

    return success;
  } catch (e, st) {
    debugPrint('❌ Error in location tracking: $e\n$st');
    return false;
  }
}

/// Helper class for managing WorkManager tasks
class BackgroundLocationTracker {
  static const String _trackingActiveKey = 'background_tracking_active';
  static const String _trackingTripIdKey = 'background_tracking_trip_id';
  static const String _trackingStartTimeKey = 'background_tracking_start_time';

  /// Register periodic background location tracking
  static Future<void> startTracking({
    required String tripId,
    String pocketBaseUrl = 'https://delivery-app.winganmarketing.com',
  }) async {
    try {
      debugPrint('🔄 Starting background tracking for trip: $tripId');

      // Register WorkManager task with minimum frequency
      // Note: 15 minutes is Android's minimum for periodic tasks
      // For more frequent updates, use foreground location tracking
      await Workmanager().registerPeriodicTask(
        'trip-tracking-$tripId',
        taskName,
        frequency: const Duration(minutes: 15), // Android system minimum
        inputData: {
          'tripId': tripId,
          'pocketBaseUrl': pocketBaseUrl,
        },
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        initialDelay: const Duration(seconds: 5),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Also trigger an immediate update for testing
      await triggerImmediateUpdate(tripId: tripId, pocketBaseUrl: pocketBaseUrl);

      // Save tracking state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_trackingActiveKey, true);
      await prefs.setString(_trackingTripIdKey, tripId);
      await prefs.setString(
        _trackingStartTimeKey,
        DateTime.now().toIso8601String(),
      );

      debugPrint('✅ Background tracking registered successfully');
      debugPrint('   📋 Trip ID: $tripId');
      debugPrint('   ⏰ Start time: ${DateTime.now()}');
      debugPrint('   📡 WorkManager interval: 15 minutes (Android minimum)');
      debugPrint('   ⚡ For frequent updates: Use foreground LocationService (2 min / 2 meters)');
    } catch (e, st) {
      debugPrint('❌ Failed to register background tracking: $e\n$st');
      rethrow;
    }
  }

  /// Stop background location tracking
  static Future<void> stopTracking() async {
    try {
      debugPrint('🔄 Stopping background tracking...');

      // Cancel all WorkManager tasks
      await Workmanager().cancelAll();

      // Clear tracking state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trackingActiveKey);
      await prefs.remove(_trackingTripIdKey);
      await prefs.remove(_trackingStartTimeKey);

      debugPrint('✅ Background tracking stopped successfully');
    } catch (e, st) {
      debugPrint('❌ Failed to stop background tracking: $e\n$st');
    }
  }

  /// Check if tracking is active
  static Future<bool> isTrackingActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool(_trackingActiveKey) ?? false;
      
      if (isActive) {
        final tripId = prefs.getString(_trackingTripIdKey);
        final startTime = prefs.getString(_trackingStartTimeKey);
        debugPrint('📊 Tracking status:');
        debugPrint('   ✅ Active: $isActive');
        debugPrint('   📋 Trip ID: $tripId');
        debugPrint('   ⏰ Started: $startTime');
      }
      
      return isActive;
    } catch (e) {
      debugPrint('⚠️ Failed to check tracking status: $e');
      return false;
    }
  }

  /// Get current tracking information
  static Future<Map<String, dynamic>?> getTrackingInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool(_trackingActiveKey) ?? false;

      if (!isActive) return null;

      return {
        'isActive': isActive,
        'tripId': prefs.getString(_trackingTripIdKey),
        'startTime': prefs.getString(_trackingStartTimeKey),
      };
    } catch (e) {
      debugPrint('⚠️ Failed to get tracking info: $e');
      return null;
    }
  }

  /// Force a one-time location update (useful for testing)
  static Future<void> triggerImmediateUpdate({
    required String tripId,
    String pocketBaseUrl = 'https://delivery-app.winganmarketing.com',
  }) async {
    try {
      debugPrint('🔄 Triggering immediate background update...');
      
      await Workmanager().registerOneOffTask(
        'trip-tracking-immediate-$tripId',
        taskName,
        inputData: {
          'tripId': tripId,
          'pocketBaseUrl': pocketBaseUrl,
        },
        initialDelay: const Duration(seconds: 2),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      debugPrint('✅ Immediate update scheduled');
    } catch (e) {
      debugPrint('❌ Failed to trigger immediate update: $e');
      rethrow;
    }
  }
}
