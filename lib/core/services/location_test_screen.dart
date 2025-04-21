import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:x_pro_delivery_app/core/services/location_services.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  List<Position> locationHistory = [];
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    startTracking();
  }

  void startTracking() {
    LocationService.trackDistance().listen((distance) {
      if (mounted) {
        setState(() {
          // Add new position to history
          locationHistory.add(LocationService.getCurrentLocation() as Position);
          debugPrint('📍 New location recorded: ${locationHistory.last}');
          debugPrint('📏 Total distance: $distance km');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Tracking Test')),
      body: Column(
        children: [
          // Map display
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  locationHistory.isEmpty ? 0 : locationHistory.last.latitude,
                  locationHistory.isEmpty ? 0 : locationHistory.last.longitude,
                ),
                zoom: 15,
              ),
              markers: locationHistory.map((position) => 
                Marker(
                  markerId: MarkerId(position.timestamp.toString()),
                  position: LatLng(position.latitude, position.longitude),
                ),
              ).toSet(),
              polylines: {
                Polyline(
                  polylineId: const PolylineId('track'),
                  points: locationHistory.map((p) => 
                    LatLng(p.latitude, p.longitude)
                  ).toList(),
                  color: Colors.blue,
                  width: 3,
                ),
              },
            ),
          ),
          // Location updates list
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: locationHistory.length,
              itemBuilder: (context, index) {
                final position = locationHistory[index];
                return ListTile(
                  title: Text('Location Update ${index + 1}'),
                  subtitle: Text(
                    'Lat: ${position.latitude}, Long: ${position.longitude}\n'
                    'Time: ${position.timestamp}'
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
