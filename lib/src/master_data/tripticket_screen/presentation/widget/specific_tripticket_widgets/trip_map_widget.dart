import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/domain/entity/trip_coordinates_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/enums/trip_update_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// Helper class to track points with timestamps for chronological ordering
class _TimestampedPoint {
  final LatLng point;
  final DateTime timestamp;
  final String type; // 'coordinate' or 'delivery'

  _TimestampedPoint({
    required this.point,
    required this.timestamp,
    required this.type,
  });
}

class TripMapWidget extends StatefulWidget {
  final String tripId;
  final TripEntity? trip;
  final List<TripUpdateEntity> tripUpdates;
  final List<TripCoordinatesEntity> tripCoordinates;
  final List<DeliveryDataEntity> deliveryData;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final double height;

  const TripMapWidget({
    super.key,
    required this.tripId,
    this.trip,
    required this.tripUpdates,
    required this.tripCoordinates,
    required this.deliveryData,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    this.height = 300.0,
  });

  @override
  State<TripMapWidget> createState() => _TripMapWidgetState();
}

class _TripMapWidgetState extends State<TripMapWidget>
    with SingleTickerProviderStateMixin {
  final MapController mapController = MapController();
  bool isMapReady = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  bool isActivityLogExpanded = false;
  final ScrollController _horizontalScrollController = ScrollController();
  bool _isSatelliteView = false; // Add this line
  
  // Street View functionality
  bool _isStreetViewMode = false;
  LatLng? _streetViewPosition;
  bool _isDraggingStreetViewIcon = false;

  List<Marker> _createCoordinateMarkers() {
    final orderedCoordinates = _getOrderedCoordinates();
    List<Marker> markers = [];

    // Only show start and end markers, not intermediate points
    if (orderedCoordinates.isNotEmpty) {
      // Start marker
      markers.add(Marker(
        point: LatLng(orderedCoordinates.first.latitude!, orderedCoordinates.first.longitude!),
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.play_arrow,
            size: 16,
            color: Colors.white,
          ),
        ),
      ));

      // End marker (only if different from start)
      if (orderedCoordinates.length > 1) {
        markers.add(Marker(
          point: LatLng(orderedCoordinates.last.latitude!, orderedCoordinates.last.longitude!),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.flag,
              size: 16,
              color: Colors.white,
            ),
          ),
        ));
      }
    }

    return markers;
  }

  List<Marker> _createDeliveryMarkers() {
    List<Marker> markers = [];

    for (int i = 0; i < widget.deliveryData.length; i++) {
      final delivery = widget.deliveryData[i];
      
      // Check if delivery has valid coordinates
      if (delivery.pinLang != null && delivery.pinLong != null &&
          delivery.pinLang! != 0.0 && delivery.pinLong! != 0.0) {
        
        markers.add(Marker(
          point: LatLng(delivery.pinLang!, delivery.pinLong!),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showDeliveryInfo(delivery),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.white,
                  ),
                  Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }

    return markers;
  }

  void _showDeliveryInfo(DeliveryDataEntity delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delivery: ${delivery.customer?.name ?? "Unknown"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Number: ${delivery.deliveryNumber ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Customer: ${delivery.customer?.name ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Invoices: ${delivery.invoices?.length ?? (delivery.invoice != null ? 1 : 0)}'),
            const SizedBox(height: 8),
            Text('Location: ${delivery.pinLang}, ${delivery.pinLong}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<TripCoordinatesEntity> _getOrderedCoordinates() {
    // Filter out coordinates with null latitude or longitude
    final validCoordinates =
        widget.tripCoordinates
            .where((coord) => coord.latitude != null && coord.longitude != null)
            .toList();

    // Sort coordinates chronologically by their creation time
    // If there's no timestamp, maintain the order they were added
    validCoordinates.sort((a, b) {
      // If both have creation timestamps, sort by creation time
      if (a.created != null && b.created != null) {
        return a.created!.compareTo(b.created!);
      }
      // If only one has creation timestamp, prioritize the one with timestamp
      if (a.created != null) return -1;
      if (b.created != null) return 1;
      // If neither has creation timestamp, maintain original order
      return 0;
    });

    return validCoordinates;
  }

  List<LatLng> _createOrderedRoutePoints() {
    // Create a list to hold all chronological points with their timestamps
    List<_TimestampedPoint> timestampedPoints = [];

    // 1. Add trip coordinates with their timestamps
    final validCoordinates = widget.tripCoordinates.where((coord) => 
      coord.latitude != null && coord.longitude != null &&
      coord.latitude! != 0.0 && coord.longitude! != 0.0
    ).toList();

    for (final coord in validCoordinates) {
      timestampedPoints.add(_TimestampedPoint(
        point: LatLng(coord.latitude!, coord.longitude!),
        timestamp: coord.created ?? DateTime.now(),
        type: 'coordinate',
      ));
    }

    // 2. Add delivery locations with their timestamps
    final validDeliveries = widget.deliveryData.where((delivery) => 
      delivery.pinLang != null && delivery.pinLong != null &&
      delivery.pinLang! != 0.0 && delivery.pinLong! != 0.0
    ).toList();

    for (final delivery in validDeliveries) {
      timestampedPoints.add(_TimestampedPoint(
        point: LatLng(delivery.pinLang!, delivery.pinLong!),
        timestamp: delivery.created ?? DateTime.now(),
        type: 'delivery',
      ));
    }

    // 3. Sort all points chronologically by creation time
    timestampedPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 4. Extract the ordered LatLng points
    List<LatLng> orderedPoints = timestampedPoints.map((tp) => tp.point).toList();

    // 5. Add current truck location as the final point if available
    if (widget.trip != null &&
        widget.trip!.latitude != null &&
        widget.trip!.longitude != null &&
        widget.trip!.latitude! != 0.0 &&
        widget.trip!.longitude! != 0.0) {
      final truckLocation = LatLng(
        widget.trip!.latitude!,
        widget.trip!.longitude!,
      );

      // Only add if it's different from the last point
      if (orderedPoints.isEmpty ||
          orderedPoints.last.latitude != truckLocation.latitude ||
          orderedPoints.last.longitude != truckLocation.longitude) {
        orderedPoints.add(truckLocation);
      }
    }

    debugPrint('🗺️ Created route with ${orderedPoints.length} chronologically ordered points');
    return orderedPoints;
  }

  // Street View functionality methods
  /// Toggles the street view mode on/off
  /// When enabled, users can tap anywhere on the map to open Google Street View
  void _toggleStreetViewMode() {
    setState(() {
      _isStreetViewMode = !_isStreetViewMode;
      if (!_isStreetViewMode) {
        _streetViewPosition = null;
        _isDraggingStreetViewIcon = false;
      }
    });
  }

  void _launchStreetView(LatLng position) async {
    final url = 'https://www.google.com/maps/@?api=1&map_action=pano'
        '&viewpoint=${position.latitude},${position.longitude}';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch Street View'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching Street View: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isStreetViewMode) {
      setState(() {
        _streetViewPosition = point;
      });
      _launchStreetView(point);
    }
  }

  Widget _buildStreetViewOverlay() {
    if (!_isStreetViewMode) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Street View',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const Text(
              'Tap map',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: widget.height,
      end: widget.height,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isMapReady = true;
      });
    });
  }

  @override
  void didUpdateWidget(TripMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height) {
      _heightAnimation = Tween<double>(
        begin: oldWidget.height,
        end: widget.height,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingCard();
    }

    if (widget.errorMessage != null) {
      return _buildErrorCard(widget.errorMessage!);
    }

    if (widget.trip != null) {
      return _buildMapWithActivityLog(widget.trip!);
    }

    // Default placeholder if no trip data is available yet
    return _buildPlaceholderCard();
  }

  Widget _buildMapWithActivityLog(TripEntity trip) {
    return Column(
      children: [
        _buildMapCard(trip),
        const SizedBox(height: 16),
        _buildActivityLogCard(trip),
      ],
    );
  }

  Widget _buildMapCard(TripEntity trip) {
    // Extract coordinates from trip entity
    final lat = trip.latitude ?? 0.0;
    final lng = trip.longitude ?? 0.0;

    // Check if we have valid coordinates
    final hasValidCoordinates = lat != 0.0 && lng != 0.0;

    // Prepare markers for trip updates with valid coordinates
    final updateMarkers =
        widget.tripUpdates
            .where(
              (update) =>
                  update.latitude != null &&
                  update.longitude != null &&
                  update.latitude!.isNotEmpty &&
                  update.longitude!.isNotEmpty,
            )
            .map((update) {
              final updateLat = double.tryParse(update.latitude!) ?? 0.0;
              final updateLng = double.tryParse(update.longitude!) ?? 0.0;
              if (updateLat == 0.0 || updateLng == 0.0) return null;

              return Marker(
                point: LatLng(updateLat, updateLng),
                width: 30,
                height: 30,
                child: _buildUpdateMarker(update),
              );
            })
            .whereType<Marker>() // Filter out null markers
            .toList();

    // Add markers for trip coordinates
    final coordinateMarkers = _createCoordinateMarkers();

    // Add current trip location marker if valid
    final allMarkers = [...updateMarkers, ...coordinateMarkers];
    if (hasValidCoordinates) {
      allMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: Icon(
            Icons.local_shipping,
            color: Theme.of(context).primaryColor,
            size: 40,
          ),
        ),
      );
    }

    // Determine map center - use trip location or first update location
    LatLng mapCenter;
    if (hasValidCoordinates) {
      mapCenter = LatLng(lat, lng);
    } else if (updateMarkers.isNotEmpty) {
      mapCenter = updateMarkers.first.point;
    } else {
      // Default to a fallback location if no valid coordinates
      mapCenter = const LatLng(0, 0);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Route Map',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isStreetViewMode ? Icons.visibility_off : Icons.visibility,
                        color: _isStreetViewMode ? Colors.orange : null,
                      ),
                      tooltip: _isStreetViewMode ? 'Exit Street View Mode' : 'Street View Mode',
                      onPressed: _toggleStreetViewMode,
                    ),
                    IconButton(
                      icon: Icon(
                        _isSatelliteView ? Icons.map : Icons.satellite,
                      ),
                      tooltip: _isSatelliteView ? 'Map View' : 'Satellite View',
                      onPressed: () {
                        setState(() {
                          _isSatelliteView = !_isSatelliteView;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Map',
                      onPressed: widget.onRefresh,
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      tooltip: 'Expand Map',
                      onPressed:
                          allMarkers.isNotEmpty
                              ? () => _showFullScreenMap(
                                context,
                                mapCenter,
                                allMarkers,
                              )
                              : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Street View mode indicator
            if (_isStreetViewMode)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Street View Mode: Tap anywhere on the map to view street view at that location',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!hasValidCoordinates && updateMarkers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No location data available for this trip yet.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            if (hasValidCoordinates)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Trip Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Last Updated: ${trip.updated?.toString() ?? 'N/A'}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            if (updateMarkers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Map shows ${updateMarkers.length} location updates',
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),

            if (coordinateMarkers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.timeline, size: 16, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Map shows ${coordinateMarkers.length} location history points',
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),

            AnimatedBuilder(
              animation: _heightAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Container(
                      height: _heightAnimation.value,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            allMarkers.isNotEmpty && isMapReady
                                ? _buildMap(mapCenter, allMarkers)
                                : _buildMapPlaceholder(),
                      ),
                    ),
                    // Street View overlay
                    _buildStreetViewOverlay(),
                  ],
                );
              },
            ),

            if (allMarkers.isNotEmpty && isMapReady)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Map legend
                    // Map legend
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              color: Theme.of(context).primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Current Location',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.red[400],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Location Updates',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Start Point',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Delivery Points',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.flag,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'End Point',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Map controls
                    // Inside the _buildMapCard method, update the map controls section
                    // Find the existing map controls row and modify it:

                    // Map controls
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_in, size: 20),
                          tooltip: 'Zoom In',
                          onPressed: () {
                            final currentZoom = mapController.camera.zoom;
                            mapController.move(
                              mapController.camera.center,
                              currentZoom + 1,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_out, size: 20),
                          tooltip: 'Zoom Out',
                          onPressed: () {
                            final currentZoom = mapController.camera.zoom;
                            mapController.move(
                              mapController.camera.center,
                              currentZoom - 1,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location, size: 20),
                          tooltip: 'Center Map',
                          onPressed: () {
                            mapController.move(mapCenter, 14);
                          },
                        ),
                        // Add the new map type toggle button
                        IconButton(
                          icon: Icon(
                            _isSatelliteView ? Icons.map : Icons.satellite,
                            size: 20,
                          ),
                          tooltip:
                              _isSatelliteView
                                  ? 'Switch to Default View'
                                  : 'Switch to Satellite View',
                          onPressed: () {
                            setState(() {
                              _isSatelliteView = !_isSatelliteView;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateMarker(TripUpdateEntity update) {
    // Different colors based on status
    Color markerColor;
    switch (update.status) {
      case TripUpdateStatus.generalUpdate:
        markerColor = Colors.green;
        break;
      case TripUpdateStatus.refuelling:
        markerColor = Colors.blue;
        break;
      case TripUpdateStatus.roadClosure:
        markerColor = Colors.orange;
        break;
      case TripUpdateStatus.others:
        markerColor = Colors.purple;
        break;
      default:
        markerColor = Colors.red;
    }

    return Stack(
      children: [
        Icon(Icons.location_on, color: markerColor, size: 30),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: markerColor, width: 1),
            ),
            child: Text(
              (widget.tripUpdates.indexOf(update) + 1).toString(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: markerColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(LatLng center, List<Marker> markers) {
    try {
      // Combine all markers (coordinates, deliveries, street view)
      final allMarkers = List<Marker>.from(markers);
      allMarkers.addAll(_createDeliveryMarkers());
      
      if (_streetViewPosition != null) {
        allMarkers.add(
          Marker(
            point: _streetViewPosition!,
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      }

      return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 14,
          minZoom: 5,
          maxZoom: 50,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
            pinchMoveWinGestures: 10,
          ),
          onTap: _onMapTap,
        ),
        children: [
          TileLayer(
            urlTemplate:
                _isSatelliteView
                    ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
                    : 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
            userAgentPackageName: 'com.example.desktop_app',
          ),
          // UPDATED: Single polyline for trip coordinates history (chronological order)
          if (widget.tripCoordinates.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _createOrderedRoutePoints(),
                  color: Colors.blue.withOpacity(0.8),
                  strokeWidth: 4.0,
                ),
              ],
            ),
          MarkerLayer(markers: allMarkers),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('Drag to move map', onTap: () {}),
            ],
            alignment: AttributionAlignment.bottomRight,
          ),
        ],
      );
    } catch (e) {
      debugPrint('❌ Error building map: $e');
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error rendering map: ${e.toString().substring(0, min(100, e.toString().length))}...',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildActivityLogCard(TripEntity trip) {
    // Get the available width (same as the map width)
    final availableWidth =
        MediaQuery.of(context).size.width - 64; // Account for padding

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity Log',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    isActivityLogExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      isActivityLogExpanded = !isActivityLogExpanded;
                    });
                  },
                ),
              ],
            ),

            if (widget.tripUpdates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No activity logs available yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              AnimatedCrossFade(
                firstChild: _buildActivityLogTablePreview(availableWidth),
                secondChild: _buildActivityLogTableFull(availableWidth),
                crossFadeState:
                    isActivityLogExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogTablePreview(double tableWidth) {
    // Show only the latest 3 updates
    final previewUpdates = widget.tripUpdates.take(3).toList();

    return Column(
      children: [
        _buildActivityLogTable(previewUpdates, tableWidth),
        if (widget.tripUpdates.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  isActivityLogExpanded = true;
                });
              },
              child: Text(
                'Show all ${widget.tripUpdates.length} activities',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityLogTableFull(double tableWidth) {
    // Sort updates by timestamp (newest first)
    final sortedUpdates = List<TripUpdateEntity>.from(widget.tripUpdates)..sort(
      (a, b) => (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()),
    );

    return _buildActivityLogTable(sortedUpdates, tableWidth);
  }

  Widget _buildActivityLogTable(
    List<TripUpdateEntity> updates,
    double tableWidth,
  ) {
    // Calculate column widths to fill the available space
    // Status: 15%, Description: 30%, Date: 20%, Coordinates: 20%, Actions: 15%
    final statusWidth = tableWidth * 0.15;
    final descriptionWidth = tableWidth * 0.20;
    final dateWidth = tableWidth * 0.20;
    final coordinatesWidth = tableWidth * 0.20;
    final actionsWidth = tableWidth * 0.15;

    // Create explicit ScrollController for horizontal scrolling
    final ScrollController horizontalScrollController = ScrollController();

    return Container(
      width: tableWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal scroll hint
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.swipe, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Scroll horizontally to see more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Table with horizontal scrolling
          Scrollbar(
            controller: horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: horizontalScrollController,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.grey.shade100,
                  ),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 64,
                  headingTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  columnSpacing: 16,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width:
                            statusWidth - 32, // Account for padding and spacing
                        child: const Text('Status'),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: descriptionWidth - 32,
                        child: const Text('Description'),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: dateWidth - 32,
                        child: const Text('Date & Time'),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: coordinatesWidth - 32,
                        child: const Text('Coordinates'),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: actionsWidth - 32,
                        child: const Text('Actions'),
                      ),
                    ),
                  ],
                  rows:
                      updates.map((update) {
                        // Format timestamp
                        final formattedTime =
                            update.date != null
                                ? DateFormat(
                                  'MMM dd, yyyy hh:mm a',
                                ).format(update.date!)
                                : 'N/A';

                        // Determine status color
                        switch (update.status) {
                          case TripUpdateStatus.generalUpdate:
                            break;
                          case TripUpdateStatus.refuelling:
                            break;
                          case TripUpdateStatus.roadClosure:
                            break;
                          case TripUpdateStatus.others:
                            break;
                          default:
                        }

                        // Check if we have valid coordinates
                        final hasCoordinates =
                            update.latitude != null &&
                            update.longitude != null &&
                            update.latitude!.isNotEmpty &&
                            update.longitude!.isNotEmpty;

                        // Check if we have an image
                        final hasImage =
                            update.image != null && update.image!.isNotEmpty;

                        return DataRow(
                          cells: [
                            // Status Cell
                            DataCell(
                              SizedBox(
                                child: _buildTripUpdateStatusChip(
                                  update.status,
                                ),
                              ),
                            ),

                            // Description Cell
                            DataCell(
                              SizedBox(
                                width: descriptionWidth - 32,
                                child: Text(
                                  update.description ?? 'No description',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),

                            // Date & Time Cell
                            DataCell(
                              SizedBox(
                                width: dateWidth - 32,
                                child: Text(
                                  formattedTime,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // Coordinates Cell
                            DataCell(
                              SizedBox(
                                width: coordinatesWidth - 32,
                                child:
                                    hasCoordinates
                                        ? Text(
                                          '${update.latitude}, ${update.longitude}',
                                          overflow: TextOverflow.ellipsis,
                                        )
                                        : const Text(
                                          'No coordinates',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                              ),
                            ),

                            // Actions Cell
                            DataCell(
                              SizedBox(
                                width: actionsWidth - 32,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // View on Map Button
                                    if (hasCoordinates)
                                      Tooltip(
                                        message: 'View on Map',
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.map,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            final lat =
                                                double.tryParse(
                                                  update.latitude!,
                                                ) ??
                                                0.0;
                                            final lng =
                                                double.tryParse(
                                                  update.longitude!,
                                                ) ??
                                                0.0;
                                            if (lat != 0.0 && lng != 0.0) {
                                              mapController.move(
                                                LatLng(lat, lng),
                                                16,
                                              );

                                              // Scroll to the map section
                                              Scrollable.ensureVisible(
                                                context,
                                                duration: const Duration(
                                                  milliseconds: 500,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 20),

                                    const SizedBox(width: 8),

                                    // View Image Button
                                    if (hasImage)
                                      Tooltip(
                                        message: 'View Image',
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.image,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _showImageDialog(
                                              context,
                                              update.image!,
                                            );
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 20),

                                    const SizedBox(width: 8),

                                    // View Details Button
                                    Tooltip(
                                      message: 'View Details',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _showUpdateDetailsDialog(
                                            context,
                                            update,
                                          );
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method to format status names

  // TripStatusChip
  Widget _buildTripUpdateStatusChip(TripUpdateStatus? status) {
    Color color;
    String statusText;

    switch (status) {
      case TripUpdateStatus.generalUpdate:
        color = Colors.green;
        statusText = 'General Update';
        break;
      case TripUpdateStatus.refuelling:
        color = Colors.blue;
        statusText = 'Refuelling';
        break;
      case TripUpdateStatus.roadClosure:
        color = Colors.orange;
        statusText = 'Road Closure';
        break;
      case TripUpdateStatus.others:
        color = Colors.purple;
        statusText = 'Others';
        break;
      default:
        color = Colors.red;
        statusText = 'Unknown';
    }

    return Chip(
      label: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Update Image'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Image.network(
                      imageUrl,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text('Failed to load image: $error'),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          onPressed: () {
                            // Implement download functionality
                            // This would typically use a plugin like url_launcher
                            // to open the image in a browser for download
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdateDetailsDialog(BuildContext context, TripUpdateEntity update) {
    final formattedTime =
        update.date != null
            ? DateFormat('MMM dd, yyyy hh:mm a').format(update.date!)
            : 'N/A';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Update Details'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Status:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(update.status?.name ?? 'Unknown'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Description:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(update.description ?? 'No description'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Date & Time:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(formattedTime),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Coordinates
                    if (update.latitude != null && update.longitude != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Coordinates:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text('${update.latitude}, ${update.longitude}'),
                        ],
                      ),

                    // Image preview if available
                    if (update.image != null && update.image!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Image:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              update.image!,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: Colors.red[300],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('Failed to load image'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (update.latitude != null &&
                            update.longitude != null &&
                            update.latitude!.isNotEmpty &&
                            update.longitude!.isNotEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text('Show on Map'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              final lat =
                                  double.tryParse(update.latitude!) ?? 0.0;
                              final lng =
                                  double.tryParse(update.longitude!) ?? 0.0;
                              if (lat != 0.0 && lng != 0.0) {
                                mapController.move(LatLng(lat, lng), 16);
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Map will be displayed when location data is available',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Route Map',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Route Map',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading map data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Route Map',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Map',
                  onPressed: widget.onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Loading trip location data...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Load Data'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenMap(
    BuildContext context,
    LatLng center,
    List<Marker> markers,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trip Location Map',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 14,
                          minZoom: 5,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            // Update the URL template here too
                            urlTemplate:
                                _isSatelliteView
                                    ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}' // Satellite view
                                    : 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', // Default view
                            userAgentPackageName: 'com.example.desktop_app',
                          ),
                          // Add polyline to connect markers in chronological order
                          if (markers.length > 1)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points:
                                      markers
                                          .map((marker) => marker.point)
                                          .toList(),
                                  color: Colors.blue.withOpacity(0.7),
                                  strokeWidth: 3.0,
                                ),
                              ],
                            ),
                          MarkerLayer(markers: markers),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'Map data © Google Maps',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Map legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: Theme.of(context).primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text('Current Location'),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red[400],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text('Location Updates'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// Extension to add latitude and longitude properties to TripEntity
extension TripEntityLocationExtension on TripEntity {
  double? get latitude {
    try {
      // First try to parse from totalTripDistance field which might contain "lat,lng"
      if (totalTripDistance != null && totalTripDistance!.contains(',')) {
        final parts = totalTripDistance!.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          if (lat != null) return lat;
        }
      }

      // If that fails, try to get from tripUpdates if available
      if (tripUpdates.isNotEmpty) {
        for (final update in tripUpdates) {
          if (update.latitude != null && update.latitude!.isNotEmpty) {
            final lat = double.tryParse(update.latitude!);
            if (lat != null) return lat;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing latitude: $e');
      return null;
    }
  }

  double? get longitude {
    try {
      // First try to parse from totalTripDistance field which might contain "lat,lng"
      if (totalTripDistance != null && totalTripDistance!.contains(',')) {
        final parts = totalTripDistance!.split(',');
        if (parts.length >= 2) {
          final lng = double.tryParse(parts[1].trim());
          if (lng != null) return lng;
        }
      }

      // If that fails, try to get from tripUpdates if available
      if (tripUpdates.isNotEmpty) {
        for (final update in tripUpdates) {
          if (update.longitude != null && update.longitude!.isNotEmpty) {
            final lng = double.tryParse(update.longitude!);
            if (lng != null) return lng;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing longitude: $e');
      return null;
    }
  }
}

// Helper function to get min of two integers
int min(int a, int b) => a < b ? a : b;
