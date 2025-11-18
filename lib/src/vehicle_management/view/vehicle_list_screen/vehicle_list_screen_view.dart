import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';

import 'package:xpro_delivery_admin_app/src/vehicle_management/widgets/vehicle_screen_widgets/vehicle_data_table.dart';
import 'package:xpro_delivery_admin_app/src/vehicle_management/widgets/vehicle_screen_widgets/vehicle_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class VehicleListScreenView extends StatefulWidget {
  const VehicleListScreenView({super.key});

  @override
  State<VehicleListScreenView> createState() => _VehicleListScreenViewState();
}

class _VehicleListScreenViewState extends State<VehicleListScreenView> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 25; // Same as tripticket_screen_view.dart
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load vehicles when the screen initializes
    context.read<DeliveryVehicleBloc>().add(
      const LoadAllDeliveryVehiclesEvent(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
 final navigationItems =
        AppNavigationItems.vehicleManagementNavigationItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute:
          '/vehicle-list', // Match the route in app_navigation_items.dart
      onNavigate: (route) {
        // Handle navigation using GoRouter
        context.go(route);
      },
      onThemeToggle: () {
        // Handle theme toggle
      },
      onNotificationTap: () {
        // Handle notification tap
      },
      onProfileTap: () {
        // Handle profile tap
      },
      child: BlocBuilder<DeliveryVehicleBloc, DeliveryVehicleState>(
        builder: (context, state) {
          // Handle different states
          if (state is DeliveryVehicleInitial) {
            // Initial state, trigger loading
            context.read<DeliveryVehicleBloc>().add(
              const LoadAllDeliveryVehiclesEvent(),
            );
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeliveryVehicleLoading) {
            return VehicleDataTable(
              vehicles: [],
              isLoading: true,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            );
          }

          if (state is DeliveryVehicleError) {
            return VehicleErrorWidget(errorMessage: state.message);
          }

          if (state is DeliveryVehiclesLoaded) {
            List<DeliveryVehicleEntity> vehicles = state.vehicles;

            // Filter vehicles based on search query
            if (_searchQuery.isNotEmpty) {
              vehicles =
                  vehicles.where((vehicle) {
                    final query = _searchQuery.toLowerCase();
                    return (vehicle.name?.toLowerCase().contains(query) ??
                            false) ||
                        (vehicle.plateNo?.toLowerCase().contains(query) ??
                            false) ||
                        (vehicle.make?.toLowerCase().contains(query) ??
                            false) ||
                        (vehicle.wheels?.toLowerCase().contains(query) ??
                            false) ||
                        (vehicle.type?.toLowerCase().contains(query) ?? false);
                  }).toList();
            }

            // Calculate total pages
            _totalPages = (vehicles.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // Paginate vehicles
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex =
                startIndex + _itemsPerPage > vehicles.length
                    ? vehicles.length
                    : startIndex + _itemsPerPage;

            final List<DeliveryVehicleEntity> paginatedVehicles =
                startIndex < vehicles.length
                    ? vehicles.sublist(startIndex, endIndex)
                    : [];

            return VehicleDataTable(
              vehicles: paginatedVehicles,
              isLoading: false,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // If search query is empty, refresh the vehicles list
                if (value.isEmpty) {
                  context.read<VehicleBloc>().add(const GetVehiclesEvent());
                }
              },
            );
          }

          // Default fallback
          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}
