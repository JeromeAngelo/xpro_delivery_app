import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/vehicle_profile/presentation/bloc/vehicle_profile_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/vehicle_profile/presentation/bloc/vehicle_profile_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/vehicle_profile/presentation/bloc/vehicle_profile_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';

import '../../widgets/specific_vehicle_widgets/assigned_trips_tbl.dart';
import '../../widgets/specific_vehicle_widgets/vehicle_dashboard.dart';



class SpecificVehicleView extends StatefulWidget {
  final String vehicleId;

  const SpecificVehicleView({super.key, required this.vehicleId});

  @override
  State<SpecificVehicleView> createState() => _SpecificVehicleViewState();
}

class _SpecificVehicleViewState extends State<SpecificVehicleView> with SingleTickerProviderStateMixin {
  // Timers
 

  // local data
  bool _isProfileLoading = true;
  bool _isVehicleLoading = true;
  String? _profileErrorMessage;
  String? _vehicleErrorMessage;

  // Pagination / search for assigned trips
  int _assignedCurrentPage = 1;
  int _assignedTotalPages = 1;
  final int _assignedItemsPerPage = 10;
  final TextEditingController _assignedSearchController = TextEditingController();
  String _assignedSearchQuery = '';

  @override
  void initState() {
    super.initState();

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });

    // Start auto-refresh (every 60 seconds)
   // _startAutoRefreshTimer();
  }

  void _loadAll() {
    setState(() {
      _isProfileLoading = true;
      _isVehicleLoading = true;
      _profileErrorMessage = null;
      _vehicleErrorMessage = null;
    });

    // Request vehicle profile by deliveryVehicle id
    // Event name: GetVehicleProfileByIdEvent - assumed to exist
    context.read<VehicleProfileBloc>().add(GetVehicleProfileByIdEvent(widget.vehicleId));

    // Request delivery vehicle info by id
    // Event name: LoadDeliveryVehicleByIdEvent - replace if your event name differs
    context.read<DeliveryVehicleBloc>().add(LoadDeliveryVehicleByIdEvent(widget.vehicleId));

  
  }

 


 

  Future<void> _manualRefresh() async {
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = AppNavigationItems.vehicleManagementNavigationItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute:
          '/vehicle-list', // you said you'll edit route later
      onNavigate: (route) => context.go(route),
      onThemeToggle: () {},
      onNotificationTap: () {},
      onProfileTap: () {},
      title: 'Vehicle Details',
      disableScrolling: true,
      child: BlocListener<VehicleProfileBloc, VehicleProfileState>(
        listener: (context, state) {
          // Handle vehicle profile state updates
          if (state is VehicleProfileByIdLoaded && state.vehicleProfile.deliveryVehicleData?.id == widget.vehicleId) {
            setState(() {
              _isProfileLoading = false;
              _profileErrorMessage = null;
              // compute pagination
              final total = state.vehicleProfile.assignedTrips?.length ?? 0;
              _assignedTotalPages = (total / _assignedItemsPerPage).ceil();
              if (_assignedTotalPages == 0) _assignedTotalPages = 1;
            });
          } else if (state is VehicleProfileLoading) {
            setState(() {
              _isProfileLoading = true;
            });
          } else if (state is VehicleProfileError) {
            setState(() {
              _isProfileLoading = false;
              _profileErrorMessage = state.message;
            });
          }
        },
        child: BlocListener<DeliveryVehicleBloc, DeliveryVehicleState>(
          listener: (context, state) {
            // Handle delivery vehicle state updates
            if (state is DeliveryVehicleLoaded && state.vehicle.id == widget.vehicleId) {
              setState(() {
                _isVehicleLoading = false;
                _vehicleErrorMessage = null;
              });
            } else if (state is DeliveryVehicleLoading) {
              setState(() {
                _isVehicleLoading = true;
              });
            } else if (state is DeliveryVehicleError) {
              setState(() {
                _isVehicleLoading = false;
                _vehicleErrorMessage = state.message;
              });
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
             
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    floating: true,
                    snap: true,
                    title: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go('/vehicle-list'),
                        ),
                        Text('Vehicle: ${widget.vehicleId}'),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        onPressed: _manualRefresh,
                      ),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // DASHBOARD - uses DeliveryVehicleBloc to get vehicle basic data
                        BlocBuilder<DeliveryVehicleBloc, DeliveryVehicleState>(
                          builder: (context, state) {
                            // Try to extract the vehicle entity
                            var vehicleEntity;
                            if (state is DeliveryVehicleLoaded) {
                              vehicleEntity = state.vehicle;
                            }

                            if (_isVehicleLoading) {
                              return VehicleDashboardWidget(
                                vehicle: null,
                                isLoading: true,
                              );
                            }

                            if (_vehicleErrorMessage != null && vehicleEntity == null) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Text('Error loading vehicle: $_vehicleErrorMessage'),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: _manualRefresh,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // vehicleEntity may be null but still show empty placeholder
                            return VehicleDashboardWidget(
                              vehicle: vehicleEntity,
                              isLoading: false,
                              onEditVehicle: () {
                                // navigate to edit screen (adjust route later)
                                if (widget.vehicleId.isNotEmpty) {
                                  context.go('/vehicle-edit/${widget.vehicleId}');
                                }
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Assigned trips table - uses VehicleProfileBloc
                        VehicleAssignedTripsTable(
                          vehicleId: widget.vehicleId,
                          currentPage: _assignedCurrentPage,
                          totalPages: _assignedTotalPages,
                          onPageChanged: (page) {
                            setState(() => _assignedCurrentPage = page);
                            // optionally request fresh data on page change
                            context.read<VehicleProfileBloc>().add(GetVehicleProfileByIdEvent(widget.vehicleId));
                          },
                          searchController: _assignedSearchController,
                          searchQuery: _assignedSearchQuery,
                          onSearchChanged: (q) {
                            setState(() {
                              _assignedSearchQuery = q;
                              _assignedCurrentPage = 1;
                            });
                          },
                        ),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
