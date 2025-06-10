import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

class CustomerMapScreen extends StatefulWidget {
  final DeliveryDataEntity? selectedCustomer;
  final double height;

  const CustomerMapScreen({
    super.key,
    this.selectedCustomer,
    this.height = 300.0,
  });

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen>
    with SingleTickerProviderStateMixin {
  MapController mapController = MapController();
  bool isMapReady = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  DeliveryDataState? _cachedState;

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
    _initializeAnimation();
    _setupMapReady();
  }

  void _loadDeliveryData() {
    if (widget.selectedCustomer?.id != null) {
      debugPrint('🗺️ Loading delivery data for map: ${widget.selectedCustomer!.id}');
      context.read<DeliveryDataBloc>().add(
        GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id!),
      );
    }
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: widget.height,
      end: widget.height,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _setupMapReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isMapReady = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(CustomerMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height) {
      _heightAnimation = Tween<double>(
        begin: oldWidget.height,
        end: widget.height,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
    }

    // Reload data if customer changed
    if (oldWidget.selectedCustomer?.id != widget.selectedCustomer?.id) {
      _loadDeliveryData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryDataBloc, DeliveryDataState>(
      listenWhen: (previous, current) =>
          current is DeliveryDataLoaded || current is DeliveryDataError,
      listener: (context, state) {
        setState(() {
          _cachedState = state;
        });
      },
      buildWhen: (previous, current) =>
          current is DeliveryDataLoaded ||
          current is DeliveryDataLoading ||
          current is DeliveryDataError ||
          _cachedState == null,
      builder: (context, state) {
        final effectiveState = _cachedState ?? state;

        // Show loading indicator when loading and no cached data
        if ((state is DeliveryDataLoading || state is DeliveryDataInitial) &&
            _cachedState == null) {
          return _buildLoadingMap();
        }

        // Show error state if no data available
        if (effectiveState is DeliveryDataError && _cachedState == null) {
          return _buildErrorMap(effectiveState.message);
        }

        if (!isMapReady) {
          return SizedBox(height: widget.height);
        }

        // Get location from delivery data or use default
        final location = _getCustomerLocation(effectiveState);

        return _buildMap(location);
      },
    );
  }

  Widget _buildLoadingMap() {
    return SizedBox(
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: Colors.grey[100],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading map...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMap(String errorMessage) {
    return SizedBox(
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: Colors.grey[100],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Map unavailable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLng _getCustomerLocation(DeliveryDataState state) {
    // Default location (Philippines)
    const defaultLocation = LatLng(15.058583416335447, 120.77471934782055);

    try {
      // Get customer from delivery data
      dynamic customer;
      
      if (state is DeliveryDataLoaded) {
        customer = state.deliveryData.customer.target;
        debugPrint('🗺️ Using customer from loaded delivery data: ${customer?.storeName ?? customer?.name}');
      } else if (widget.selectedCustomer != null) {
        customer = widget.selectedCustomer!.customer.target;
        debugPrint('🗺️ Using customer from widget: ${customer?.storeName ?? customer?.name}');
      }

      if (customer == null) {
        debugPrint('⚠️ No customer data available, using default location');
        return defaultLocation;
      }

      // Parse latitude and longitude
      final lat = double.tryParse(customer.latitude?.toString() ?? '');
      final lng = double.tryParse(customer.longitude?.toString() ?? '');

      if (lat != null && lng != null) {
        final location = LatLng(lat, lng);
        debugPrint('🗺️ Customer location: ${customer.storeName ?? customer.name} at $lat, $lng');
        return location;
      } else {
        debugPrint('⚠️ Invalid coordinates for customer: ${customer.storeName ?? customer.name}');
        debugPrint('   Latitude: ${customer.latitude}');
        debugPrint('   Longitude: ${customer.longitude}');
        return defaultLocation;
      }
    } catch (e) {
      debugPrint('❌ Error getting customer location: $e');
      return defaultLocation;
    }
  }

  Widget _buildMap(LatLng location) {
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: ClipRRect(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
                initialCenter: location,
                initialZoom: 16,
                minZoom: 5,
                maxZoom: 18,
                keepAlive: true,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _openInMaps(location),
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInMaps(LatLng location) async {
    try {
      final coords = '${location.latitude},${location.longitude}';
      
      if (Platform.isAndroid) {
        final url = 'geo:$coords?q=$coords';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Fallback to Google Maps web
          await _openGoogleMapsWeb(location);
        }
      } else if (Platform.isIOS) {
        final url = 'maps://?q=$coords';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Fallback to Google Maps web
          await _openGoogleMapsWeb(location);
        }
      } else {
        // For other platforms, open Google Maps web
        await _openGoogleMapsWeb(location);
      }
    } catch (e) {
      debugPrint('❌ Error opening maps: $e');
      // Show snackbar with error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMapsWeb(LatLng location) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
