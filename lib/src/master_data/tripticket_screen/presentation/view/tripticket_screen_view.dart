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
  final int _itemsPerPage = 25;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String? _statusFilter; // null = All

  @override
  void initState() {
    super.initState();
    context.read<TripBloc>().add(const GetAllTripTicketsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Map TripEntity to UI status labels used in your filter dialog
  String _mapTripStatus(TripEntity trip) {
    // Adjust if you already have trip.status or trip.statusTitle etc.
    if (trip.isEndTrip == true) return 'Completed';
    if (trip.isAccepted == true) return 'In progress';
    return 'Pending';
  }

  // ✅ Apply search + status filters
  List<TripEntity> _applyFilters(List<TripEntity> trips) {
    var filtered = trips;

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((trip) {
        return (trip.id?.toLowerCase().contains(query) ?? false) ||
            (trip.tripNumberId?.toLowerCase().contains(query) ?? false) ||
            (trip.user?.name?.toLowerCase().contains(query) ?? false) ||
            (trip.name?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Status filter
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((trip) {
        return _mapTripStatus(trip) == _statusFilter;
      }).toList();
    }

    return filtered;
  }

  // ✅ Paginate list based on _currentPage/_itemsPerPage
  List<TripEntity> _paginateTrips(List<TripEntity> trips) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= trips.length) return const <TripEntity>[];

    final endIndex = (startIndex + _itemsPerPage > trips.length)
        ? trips.length
        : startIndex + _itemsPerPage;

    return List<TripEntity>.from(trips.sublist(startIndex, endIndex));
  }

  void _handleFiltered(String? status) {
    setState(() {
      // If your DataTableLayout sends "All" string, normalize it to null:
      if (status == null || status.isEmpty || status.toLowerCase() == 'all') {
        _statusFilter = null;
      } else {
        _statusFilter = status;
      }
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/tripticket',
      onNavigate: (route) => context.go(route),
      onThemeToggle: () {},
      onNotificationTap: () {},
      onProfileTap: () {},
      child: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripInitial) {
            context.read<TripBloc>().add(const GetAllTripTicketsEvent());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripLoading) {
            return TripDataTable(
              trips: const [],
              isLoading: true,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onFiltered: _handleFiltered,
              onPageChanged: (page) => setState(() => _currentPage = page),
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },
            );
          }

          if (state is TripError) {
            return TripErrorWidget(errorMessage: state.message);
          }

          if (state is AllTripTicketsLoaded || state is TripTicketsSearchResults) {
            final List<TripEntity> baseTrips =
                (state is AllTripTicketsLoaded) ? state.trips : (state as TripTicketsSearchResults).trips;

            // ✅ Apply search + status filters
            final filteredTrips = _applyFilters(baseTrips);

            // ✅ Calculate total pages (after filtering)
            _totalPages = (filteredTrips.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // ✅ Ensure current page stays valid after filtering
            if (_currentPage > _totalPages) _currentPage = 1;

            // ✅ Paginate after filtering
            final paginatedTrips = _paginateTrips(filteredTrips);

            return TripDataTable(
              trips: paginatedTrips,
              isLoading: false,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onFiltered: _handleFiltered,
              onPageChanged: (page) => setState(() => _currentPage = page),
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}