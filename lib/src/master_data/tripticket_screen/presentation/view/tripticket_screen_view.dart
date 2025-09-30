import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/tripticket_screen_widgets/trip_data_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/tripticket_screen_widgets/trip_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:go_router/go_router.dart';

class TripTicketScreenView extends StatefulWidget {
  const TripTicketScreenView({super.key});

  @override
  State<TripTicketScreenView> createState() => _TripTicketScreenViewState();
}

class _TripTicketScreenViewState extends State<TripTicketScreenView> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 25; // Changed from 10 to 25
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load trip tickets when the screen initializes
    context.read<TripBloc>().add(const GetAllTripTicketsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/tripticket', // Match the route in router.dart
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
      child: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          // Handle different states
          if (state is TripInitial) {
            // Initial state, trigger loading
            context.read<TripBloc>().add(const GetAllTripTicketsEvent());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripLoading) {
            return TripDataTable(
              trips: [],
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

          if (state is TripError) {
            return TripErrorWidget(errorMessage: state.message);
          }

          if (state is AllTripTicketsLoaded ||
              state is TripTicketsSearchResults) {
            List<TripEntity> trips = [];

            if (state is AllTripTicketsLoaded) {
              trips = state.trips; // No need to cast now
            } else if (state is TripTicketsSearchResults) {
              trips = state.trips; // No need to cast now
            }

            // Filter trips based on search query
            if (_searchQuery.isNotEmpty) {
              trips =
                  trips.where((trip) {
                    final query = _searchQuery.toLowerCase();
                    return (trip.id?.toLowerCase().contains(query) ?? false) ||
                        (trip.tripNumberId?.toLowerCase().contains(query) ??
                            false) ||
                        (trip.user?.name?.toLowerCase().contains(query) ??
                            false) ||
                        (trip.name?.toLowerCase().contains(query) ?? false);
                  }).toList();
            }

            // Calculate total pages
            _totalPages = (trips.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // Paginate trips
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex =
                startIndex + _itemsPerPage > trips.length
                    ? trips.length
                    : startIndex + _itemsPerPage;

            final List<TripEntity> paginatedTrips =
                startIndex < trips.length
                    ? List<TripEntity>.from(trips.sublist(startIndex, endIndex))
                    : <TripEntity>[];

            return TripDataTable(
              trips: paginatedTrips,
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
