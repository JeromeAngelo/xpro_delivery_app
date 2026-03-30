import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static double _totalDistance = 0;
  static Position? _lastPosition;
  static Timer? _locationTimer;
  static StreamController<Position>? _locationController;
  static final List<Position> _recentPositions = [];
  static DateTime? _lastUpdateTime;

  // Simple Distance Tracking Constants - All Motion Combined
  static const int _updateIntervalMinutes =
      2; // Time-based updates every 2 minutes (more frequent)
  static const int _distanceFilterMeters =
      5; // Distance-based updates every 2 meters of movement (more frequent)
  static const double _accuracyThreshold =
      50.0; // Accept readings within 50 meters (relaxed for real-world GPS)
  static const double _minMovementThreshold =
      8; // or even 10 // Update for any movement ≥ 8 meters (more sensitive)
  static const double _maxRealisticSpeedKmh =
      200.0; // Higher threshold to allow for all types of movement
  static const int _smoothingBufferSize =
      5; // Smaller buffer for more responsive tracking

  static Future<bool> enableLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }
    return serviceEnabled;
  }

  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('Current permission status: $permission');

    // If not determined, request permission
    if (permission == LocationPermission.denied) {
      debugPrint('Requesting permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('Permission request result: $permission');
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Permission denied forever');
      return false;
    }

    // For background location tracking we require "always" permission.
    // On newer Android versions (Android 11+), "whileInUse" (only when app in foreground)
    // is NOT sufficient for background foreground-service based location updates.
    if (permission != LocationPermission.always) {
      debugPrint(
        'Background (ALWAYS) location permission is not granted: $permission',
      );
      return false;
    }

    return true;
  }

  static Stream<double> trackDistance() {
    _locationController = StreamController<Position>.broadcast();

    // Set up periodic timer for time-based updates
    _locationTimer = Timer.periodic(
      const Duration(minutes: _updateIntervalMinutes),
      (_) => _updateLocation(),
    );

    // Set up distance-based updates with relaxed settings
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy:
            LocationAccuracy
                .high, // Use high instead of best for better compatibility
        distanceFilter: _distanceFilterMeters,
        // Remove timeLimit to prevent timeout exceptions
      ),
    ).listen(
      _handleNewPosition,
      onError: (error) {
        debugPrint('⚠️ LOCATION: Position stream error: $error');
        // Don't stop tracking on errors, just log them
      },
    );

    return _locationController!.stream
        .where((pos) => _isValidPosition(pos))
        .map((pos) => _processPosition(pos));
  }

  // Simple position validation for any movement
  static bool _isValidPosition(Position position) {
    debugPrint('🔍 LOCATION: Validating position for movement tracking...');
    debugPrint('   📍 Lat: ${position.latitude}, Lng: ${position.longitude}');
    debugPrint('   🎯 Accuracy: ${position.accuracy} meters');
    debugPrint('   ⏰ Timestamp: ${position.timestamp}');

  if (position.accuracy > 20) {
  debugPrint('❌ Poor accuracy - REJECTED');
  return false;
}

    // 2. Check if position is realistic (not null island coordinates)
    if (position.latitude == 0.0 && position.longitude == 0.0) {
      debugPrint('❌ LOCATION: Null island coordinates - REJECTED');
      return false;
    }

    // 3. Simple movement validation - accept any movement ≥ 1 meter
    if (_lastPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

        final timeDiff = position.timestamp
      .difference(_lastUpdateTime ?? position.timestamp)
      .inSeconds;

  // If movement is small AND time is short → ignore (GPS drift)
  if (distanceInMeters < 10 && timeDiff < 60) {
    debugPrint('❌ Likely GPS drift - REJECTED');
    return false;
  }

      debugPrint(
        '   📏 Distance from last: ${distanceInMeters.toStringAsFixed(2)}m',
      );

      // Only record movement ≥ 5 meters to avoid GPS noise
      if (distanceInMeters < _minMovementThreshold) {
        debugPrint(
          '❌ LOCATION: Insufficient movement (${distanceInMeters.toStringAsFixed(2)}m < ${_minMovementThreshold}m) - REJECTED',
        );
        return false;
      }

      // 4. Basic speed validation (only reject completely unrealistic speeds)
      if (_lastUpdateTime != null) {
        final timeDiffSeconds =
            position.timestamp.difference(_lastUpdateTime!).inSeconds;
        if (timeDiffSeconds > 0) {
          final speedKmh = (distanceInMeters / 1000) / (timeDiffSeconds / 3600);
          debugPrint(
            '   🚶🚛 Movement speed: ${speedKmh.toStringAsFixed(2)} km/h (all motion types accepted)',
          );

          if (speedKmh > _maxRealisticSpeedKmh) {
            debugPrint(
              '❌ LOCATION: Unrealistic speed (${speedKmh.toStringAsFixed(2)} km/h > ${_maxRealisticSpeedKmh} km/h) - REJECTED',
            );
            return false;
          }
        }
      }
    }

    debugPrint('✅ LOCATION: Position validated - movement ≥5m accepted');
    return true;
  }

  // Simple position processing - track all movement distance
  static double _processPosition(Position position) {
    debugPrint(
      '🔄 LOCATION: Processing position for total distance tracking...',
    );

    // Add to smoothing buffer for accuracy
    _recentPositions.add(position);
    if (_recentPositions.length > _smoothingBufferSize) {
      _recentPositions.removeAt(0);
    }

    // Use smoothed position for more accurate distance calculation
    final smoothedPosition = _getSmoothPosition();

    if (_lastPosition != null && smoothedPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        smoothedPosition.latitude,
        smoothedPosition.longitude,
      );

      final distanceKm = distanceInMeters / 1000;
      _totalDistance += distanceKm;

      debugPrint(
        '📍 LOCATION: Total distance updated (all movement types combined)',
      );
      debugPrint(
        '   📏 Movement segment: ${distanceInMeters.toStringAsFixed(2)}m',
      );
      debugPrint(
        '   📊 Total distance: ${_totalDistance.toStringAsFixed(3)} km',
      );
      debugPrint(
        '   🎯 Smoothed coordinates: ${smoothedPosition.latitude.toStringAsFixed(6)}, ${smoothedPosition.longitude.toStringAsFixed(6)}',
      );
      debugPrint(
        '   ⏰ Update frequency: Every ${_updateIntervalMinutes}min OR ${_distanceFilterMeters}m movement',
      );

      
    }

    _lastPosition = smoothedPosition ?? position;
    _lastUpdateTime = position.timestamp;
    return _totalDistance;
  }

  // Position smoothing for accurate distance calculation
  static Position? _getSmoothPosition() {
    if (_recentPositions.isEmpty) return null;
    if (_recentPositions.length == 1) return _recentPositions.first;

    debugPrint(
      '🎯 LOCATION: Smoothing ${_recentPositions.length} positions for accurate distance tracking...',
    );

    // Calculate weighted average (newer positions have higher weight)
    double totalWeight = 0;
    double weightedLat = 0;
    double weightedLng = 0;
    double weightedAccuracy = 0;

    for (int i = 0; i < _recentPositions.length; i++) {
      final position = _recentPositions[i];
      final weight = (i + 1).toDouble(); // Newer positions get higher weight

      totalWeight += weight;
      weightedLat += position.latitude * weight;
      weightedLng += position.longitude * weight;
      weightedAccuracy += position.accuracy * weight;
    }

    final smoothedLat = weightedLat / totalWeight;
    final smoothedLng = weightedLng / totalWeight;
    final smoothedAccuracy = weightedAccuracy / totalWeight;

    debugPrint(
      '   📍 Raw latest: ${_recentPositions.last.latitude}, ${_recentPositions.last.longitude}',
    );
    debugPrint(
      '   🎯 Smoothed: ${smoothedLat.toStringAsFixed(6)}, ${smoothedLng.toStringAsFixed(6)}',
    );
    debugPrint(
      '   📊 Accuracy improved: ${_recentPositions.last.accuracy.toStringAsFixed(2)}m -> ${smoothedAccuracy.toStringAsFixed(2)}m',
    );

    // Create smoothed position
    return Position(
      latitude: smoothedLat,
      longitude: smoothedLng,
      timestamp: _recentPositions.last.timestamp,
      accuracy: smoothedAccuracy,
      altitude: _recentPositions.last.altitude,
      heading: _recentPositions.last.heading,
      speed: _recentPositions.last.speed,
      speedAccuracy: _recentPositions.last.speedAccuracy,
      altitudeAccuracy: _recentPositions.last.altitudeAccuracy,
      headingAccuracy: _recentPositions.last.headingAccuracy,
    );
  }

  static Future<void> _updateLocation() async {
    try {
      debugPrint('⏰ LOCATION: Timer-based location update triggered');
      final position = await getCurrentLocation();
      _locationController?.add(position);
      debugPrint('✅ LOCATION: Timer-based position added to stream');
    } catch (e) {
      debugPrint('⚠️ LOCATION: Timer-based update failed (non-critical): $e');
      // Don't stop tracking, just continue with distance-based updates
    }
  }

  static void _handleNewPosition(Position position) {
    _locationController?.add(position);
  }

  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await enableLocationService();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('Current permission status: $permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permission denied forever');
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint(
        'Current location: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return Future.error('Error getting current location');
    }
  }

  static void stopTracking() {
    debugPrint('🛑 LOCATION: Stopping location tracking...');

    _locationTimer?.cancel();
    _locationController?.close();
    _locationTimer = null;
    _locationController = null;
    _lastPosition = null;
    _lastUpdateTime = null;
    _totalDistance = 0;
    _recentPositions.clear();

    debugPrint('✅ LOCATION: Location tracking stopped and buffers cleared');
  }

  // Get current location without strict validation (simple approach)
  static Future<Position> getValidatedCurrentLocation() async {
    debugPrint('🔍 LOCATION: Getting current location (relaxed validation)...');

    try {
      final position = await getCurrentLocation();
      debugPrint(
        '✅ LOCATION: Position obtained - will be processed by validation filter',
      );
      debugPrint(
        '   📍 Coordinates: ${position.latitude}, ${position.longitude}',
      );
      debugPrint('   🎯 Accuracy: ${position.accuracy} meters');
      return position;
    } catch (e) {
      debugPrint('❌ LOCATION: Error getting location: $e');
      throw Exception('Failed to get current location: $e');
    }
  }

  static double getTotalDistance() => _totalDistance;

  // Get comprehensive tracking information
  static Map<String, dynamic> getTrackingInfo() {
    return {
      'totalDistance': _totalDistance,
      'lastPosition':
          _lastPosition != null
              ? {
                'latitude': _lastPosition!.latitude,
                'longitude': _lastPosition!.longitude,
                'accuracy': _lastPosition!.accuracy,
                'timestamp': _lastPosition!.timestamp.toIso8601String(),
              }
              : null,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'recentPositionsCount': _recentPositions.length,
      'isTracking':
          _locationController != null && !_locationController!.isClosed,
    };
  }
}
