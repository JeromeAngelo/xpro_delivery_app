import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/widgets/delivery_data_screen_widget/delivery_data_error_widget.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/widgets/delivery_data_screen_widget/delivery_data_table.dart';

class DeliveryDataScreen extends StatefulWidget {
  const DeliveryDataScreen({super.key});

  @override
  State<DeliveryDataScreen> createState() => _DeliveryDataScreenState();
}

class _DeliveryDataScreenState extends State<DeliveryDataScreen> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load delivery data when the screen initializes
    context.read<DeliveryDataBloc>().add(
      const GetAllDeliveryDataWithTripsEvent(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/delivery-list',
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
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, state) {
          // Handle different states - SAME FORMAT AS INVOICE PRESET GROUPS
          if (state is DeliveryDataInitial) {
            // Initial state, trigger loading
            context.read<DeliveryDataBloc>().add(
              const GetAllDeliveryDataWithTripsEvent(),
            );
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeliveryDataLoading) {
            // Return the table directly with loading state - NO WRAPPING
            return DeliveryDataTable(
              deliveryData: const <DeliveryDataEntity>[],
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

          if (state is DeliveryDataError) {
            return DeliveryDataErrorWidget(
              errorMessage: state.message,
              onRetry: () {
                context.read<DeliveryDataBloc>().add(
                  const GetAllDeliveryDataWithTripsEvent(),
                );
              },
            );
          }

          if (state is AllDeliveryDataWithTripsLoaded) {
            List<DeliveryDataEntity> deliveryData = state.deliveryData;

            // Filter delivery data based on search query
            if (_searchQuery.isNotEmpty) {
              deliveryData =
                  deliveryData.where((delivery) {
                    final query = _searchQuery.toLowerCase();
                    return (delivery.deliveryNumber?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        (delivery.customer?.name?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        (delivery.invoice?.name?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                            (delivery.refID?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        (delivery.trip?.tripNumberId?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        (delivery.customer?.municipality
                                ?.toLowerCase()
                                .contains(query) ??
                            false) ||
                        (delivery.customer?.province?.toLowerCase().contains(
                              query,
                            ) ??
                            false);
                  }).toList();
            }

            // Calculate total pages
            _totalPages = (deliveryData.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // Paginate delivery data
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex =
                startIndex + _itemsPerPage > deliveryData.length
                    ? deliveryData.length
                    : startIndex + _itemsPerPage;

            final paginatedDeliveryData =
                startIndex < deliveryData.length
                    ? deliveryData.sublist(startIndex, endIndex)
                    : <DeliveryDataEntity>[];

            // Return the table directly - NO WRAPPING WITH COLUMN/SINGLECHILDSCROLLVIEW
            return DeliveryDataTable(
              deliveryData: paginatedDeliveryData,
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
                  _currentPage = 1; // Reset to first page when searching
                });
              },
            );
          }

          // Handle other states
          if (state is DeliveryDataByTripLoaded) {
            // If we get trip-specific data, show it
            List<DeliveryDataEntity> deliveryData = state.deliveryData;

            // Filter delivery data based on search query
            if (_searchQuery.isNotEmpty) {
              deliveryData =
                  deliveryData.where((delivery) {
                    final query = _searchQuery.toLowerCase();
                    return (delivery.deliveryNumber?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        (delivery.customer?.name?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        (delivery.invoice?.name?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        (delivery.trip?.tripNumberId?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        (delivery.customer?.municipality
                                ?.toLowerCase()
                                .contains(query) ??
                            false) ||
                        (delivery.customer?.province?.toLowerCase().contains(
                              query,
                            ) ??
                            false);
                  }).toList();
            }

            // Calculate total pages
            _totalPages = (deliveryData.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // Paginate delivery data
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex =
                startIndex + _itemsPerPage > deliveryData.length
                    ? deliveryData.length
                    : startIndex + _itemsPerPage;

            final paginatedDeliveryData =
                startIndex < deliveryData.length
                    ? deliveryData.sublist(startIndex, endIndex)
                    : <DeliveryDataEntity>[];

            // Return the table directly - NO WRAPPING
            return DeliveryDataTable(
              deliveryData: paginatedDeliveryData,
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
                  _currentPage = 1; // Reset to first page when searching
                });
              },
            );
          }

          // Default fallback
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No delivery data available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Please check your connection and try again',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
