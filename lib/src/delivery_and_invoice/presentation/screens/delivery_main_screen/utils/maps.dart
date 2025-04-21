import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';

class CustomerMapScreen extends StatefulWidget {
  final CustomerEntity? selectedCustomer;
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

  @override
  void initState() {
    super.initState();
    if (widget.selectedCustomer != null) {
      context.read<CustomerBloc>().add(
            GetCustomerLocationEvent(widget.selectedCustomer!.id ?? ''),
          );
    }

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
  void didUpdateWidget(CustomerMapScreen oldWidget) {
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
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLocationLoading) {
          return SizedBox(
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!isMapReady) {
          return SizedBox(height: widget.height);
        }

        LatLng location;
        if (state is CustomerLocationLoaded) {
          final lat = double.tryParse(state.customer.latitude ?? '') ??
              15.058583416335447;
          final lng = double.tryParse(state.customer.longitude ?? '') ??
              120.77471934782055;
          location = LatLng(lat, lng);
        } else {
          location = const LatLng(15.058583416335447, 120.77471934782055);
        }

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
                            onTap: () {
                              final coords =
                                  '${location.latitude},${location.longitude}';
                              if (Platform.isAndroid) {
                                final url = 'geo:$coords?q=$coords';
                                launchUrl(Uri.parse(url));
                              } else if (Platform.isIOS) {
                                final url = 'maps://?q=$coords';
                                launchUrl(Uri.parse(url));
                              }
                            },
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
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
