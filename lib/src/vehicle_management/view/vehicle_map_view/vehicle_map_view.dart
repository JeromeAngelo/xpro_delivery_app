import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import '../../../../core/common/widgets/reusable_widgets/app_navigation_items.dart';
import '../../widgets/vehicle_map_view_widgets/main_maps.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:go_router/go_router.dart';

class VehicleMapView extends StatefulWidget {
  const VehicleMapView({super.key});

  @override
  State<VehicleMapView> createState() => _VehicleMapViewState();
}

class _VehicleMapViewState extends State<VehicleMapView>
    with SingleTickerProviderStateMixin {
  List<TripEntity> _trips = [];
  List<TripEntity> _visibleTrips = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  Timer? _autoRefreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 120);

  // Notifier passed to the map so the map can react to selections
  final ValueNotifier<TripEntity?> _selectedTripNotifier = ValueNotifier(null);

  // panel state
  bool _panelVisible = true;
  late final AnimationController _panelAnimController;

  @override
  void initState() {
    super.initState();

    _panelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (_panelVisible) _panelAnimController.value = 1.0;

    // First load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTrips();
    });

    // Start auto refresh
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _selectedTripNotifier.dispose();
    _panelAnimController.dispose();
    super.dispose();
  }

  void _onTripsUpdated(List<TripEntity> trips) {
    setState(() {
      _trips = trips;
      _applyFilter();
      _loading = false;
      _error = null;
    });
  }

  void _fetchTrips() {
    context.read<TripBloc>().add(const GetAllActiveTripTicketsEvent());
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel(); // prevent duplicates

    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _fetchTrips();
      }
    });
  }

  void _applyFilter() {
    final q = _search.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _visibleTrips = List.from(_trips);
      } else {
        _visibleTrips =
            _trips.where((t) {
              final vName =
                  (t.vehicle != null)
                      ? ((t.vehicle as dynamic).name?.toString() ?? '')
                      : '';
              final tripId = t.tripNumberId ?? '';
              final user = t.user?.name ?? t.user?.email ?? '';
              return vName.toLowerCase().contains(q) ||
                  tripId.toLowerCase().contains(q) ||
                  user.toLowerCase().contains(q);
            }).toList();
      }
    });
  }

  void _onSelectVehicle(TripEntity trip) {
    // reorder list (optional)
    final reordered =
        <TripEntity>[trip] + _trips.where((t) => t.id != trip.id).toList();
    setState(() {
      _trips = reordered;
      _applyFilter();
    });

    // Tell the map to zoom to this trip
    _selectedTripNotifier.value = trip;
  }

  // Future<void> _openVehicleListDialog() async {
  //   final selected = await VehicleListDialog.show(context, _trips);
  //   if (selected != null) {
  //     _selectedTripNotifier.value = selected;
  //     final reordered =
  //         <TripEntity>[selected] +
  //         _trips.where((t) => t.id != selected.id).toList();
  //     setState(() {
  //       _trips = reordered;
  //       _applyFilter();
  //     });
  //   }
  // }

  // Future<void> _onRefreshTrips() async {
  //   context.read<TripBloc>().add(const GetAllActiveTripTicketsEvent());
  // }

  void _togglePanel() {
    setState(() => _panelVisible = !_panelVisible);
    if (_panelVisible) {
      _panelAnimController.forward();
    } else {
      _panelAnimController.reverse();
    }
  }

  Widget _floatingList(
    BuildContext context,
    double panelWidth,
    double panelHeight,
  ) {
    return FadeTransition(
      opacity: _panelAnimController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.2, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _panelAnimController, curve: Curves.easeOut),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: panelWidth,
            height: panelHeight,
            child: Card(
              elevation: 6,
              color: Colors.white,
              margin: const EdgeInsets.fromLTRB(16, 24, 0, 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Active Vehicles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          onPressed: () {
                            _fetchTrips(); // reload immediately
                            _startAutoRefresh(); // restart timer
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: _togglePanel,
                        ),
                      ],
                    ),
                  ),

                  // search
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search vehicle / trip id / user',
                        prefixIcon: Icon(Icons.search, color: Colors.black54),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        _search = v;
                        _applyFilter();
                      },
                    ),
                  ),

                  // list
                  Expanded(
                    child:
                        _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _visibleTrips.isEmpty
                            ? Center(child: Text(_error ?? 'No vehicles'))
                            : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: _visibleTrips.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 8),
                              itemBuilder: (ctx, idx) {
                                final trip = _visibleTrips[idx];
                                final vehicleName =
                                    (trip.vehicle != null)
                                        ? ((trip.vehicle as dynamic).name
                                                ?.toString() ??
                                            trip.tripNumberId ??
                                            '')
                                        : (trip.tripNumberId ?? 'Unknown');
                                final subtitle =
                                    '${trip.name ?? ''}${(trip.user?.name != null && trip.user!.name!.isNotEmpty) ? ' / ${trip.user!.name}' : ''}';
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.12),
                                    child: const Icon(
                                      Icons.local_shipping,
                                      color: Colors.black,
                                    ),
                                  ),
                                  title: Text(
                                    vehicleName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.center_focus_strong,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => _onSelectVehicle(trip),
                                  ),
                                  onTap: () => _onSelectVehicle(trip),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems =
        AppNavigationItems.vehicleManagementNavigationItems();

    return BlocListener<TripBloc, TripState>(
      listener: (context, state) {
        if (state is AllActiveTripTicketsLoaded) {
          _onTripsUpdated(state.trips);
        } else if (state is TripLoading) {
          setState(() {
            _loading = true;
          });
        } else if (state is TripError) {
          setState(() {
            _error = state.message;
            _loading = false;
          });
        } else if (state is AllActiveTripTicketsLoaded) {
          // optionally update when full list is loaded
          _onTripsUpdated(state.trips);
        }
      },
      child: DesktopLayout(
        navigationItems: navigationItems,
        currentRoute: '/vehicle-map',
        onNavigate: (route) {
          // Handle navigation using GoRouter
          context.go(route);
        },
        onThemeToggle: () {},
        onNotificationTap: () {},
        onProfileTap: () {},
        title: 'Map Overview',

        disableScrolling: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;
            final panelWidth = width < 1100 ? width * 0.65 : 360.0;
            final panelHeight = height * 0.78;

            return Stack(
              children: [
                // full map behind
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: VehicleMapWidget(
                        trips:
                            _visibleTrips.isNotEmpty ? _visibleTrips : _trips,
                        height: double.infinity,
                        width: double.infinity,
                        selectedTripNotifier: _selectedTripNotifier,
                      ),
                    ),
                  ),
                ),

                // floating left panel
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: SizedBox(
                      width: panelWidth + 32, // include margin space
                      child: Stack(
                        children: [
                          // The sliding list
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: _floatingList(
                              context,
                              panelWidth,
                              panelHeight,
                            ),
                          ),
                          // Toggle button (when panel hidden user can show it)
                          Positioned(
                            left: _panelVisible ? panelWidth + 8 : 8,
                            top: 24,
                            child: Material(
                              elevation: 4,
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _togglePanel,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    _panelVisible
                                        ? Icons.chevron_left
                                        : Icons.chevron_right,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
