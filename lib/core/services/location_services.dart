import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static double _totalDistance = 0;
  static Position? _lastPosition;
  static Timer? _locationTimer;
  static StreamController<Position>? _locationController;

  // Constants
  static const int _updateIntervalMinutes = 2;
  static const int _distanceFilterMeters = 1000;

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
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Stream<double> trackDistance() {
    _locationController = StreamController<Position>.broadcast();

    // Set up periodic timer for time-based updates
    _locationTimer = Timer.periodic(
      const Duration(minutes: _updateIntervalMinutes),
      (_) => _updateLocation(),
    );

    // Set up distance-based updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
      ),
    ).listen(_handleNewPosition);

    // Return distance stream
    return _locationController!.stream.map((position) {
      if (_lastPosition != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _totalDistance += distanceInMeters / 1000; // Convert to kilometers
        debugPrint(
            '📍 Distance updated: ${_totalDistance.toStringAsFixed(2)} km');
      }
      _lastPosition = position;
      return _totalDistance;
    });
  }

  static Future<void> _updateLocation() async {
    try {
      final position = await getCurrentLocation();
      _locationController?.add(position);
    } catch (e) {
      debugPrint('❌ Location update failed: $e');
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

    bool permissionGranted = await requestPermission();
    if (!permissionGranted) {
      return Future.error('Location permission denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static void stopTracking() {
    _locationTimer?.cancel();
    _locationController?.close();
    _locationTimer = null;
    _locationController = null;
    _lastPosition = null;
    _totalDistance = 0;
    debugPrint('📍 Location tracking stopped');
  }

  static double getTotalDistance() => _totalDistance;
}
