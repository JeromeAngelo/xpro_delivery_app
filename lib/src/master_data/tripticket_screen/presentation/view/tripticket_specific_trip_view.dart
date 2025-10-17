import 'dart:async';

import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_event.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/domain/entity/trip_coordinates_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/presentation/bloc/trip_coordinates_update_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/presentation/bloc/trip_coordinates_update_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/presentation/bloc/trip_coordinates_update_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/domain/entity/end_trip_otp_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/entity/otp_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/presentation/bloc/otp_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/presentation/bloc/otp_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/specific_tripticket_widgets/trip_customer_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/specific_tripticket_widgets/trip_dashboard_widget.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/specific_tripticket_widgets/trip_end_trip_otp_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/specific_tripticket_widgets/trip_map_widget.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/specific_tripticket_widgets/trip_otp_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/specific_tripticket_widgets/trip_personels_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/specific_tripticket_widgets/trip_vehicle_table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import '../../../../../core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';

class TripTicketSpecificTripView extends StatefulWidget {
  final String tripId;

  const TripTicketSpecificTripView({super.key, required this.tripId});

  @override
  State<TripTicketSpecificTripView> createState() =>
      _TripTicketSpecificTripViewState();
}

class _TripTicketSpecificTripViewState
    extends State<TripTicketSpecificTripView> {
  List<TripCoordinatesEntity> _tripCoordinates = [];
  List<DeliveryDataEntity> _deliveryData = [];
  bool _isCoordinatesLoading = true;
  bool _isDeliveryDataLoading = true;
  String? _coordinatesErrorMessage;
  String? _deliveryDataErrorMessage;
  
  // Add timeout timers
  Timer? _coordinatesLoadingTimer;
  Timer? _deliveryDataLoadingTimer;
  Timer? _mapLoadingTimer;

  // Customer pagination state
  int _customerCurrentPage = 1;
  int _customerTotalPages = 1;
  final int _customerItemsPerPage = 5; // Smaller number for embedded table
  String _customerSearchQuery = '';
  final TextEditingController _customerSearchController =
      TextEditingController();

  // OTP pagination state
  int _otpCurrentPage = 1;
  int _otpTotalPages = 1;
  final int _otpItemsPerPage = 5; // Smaller number for embedded table

  // End Trip OTP pagination state
  int _endTripOtpCurrentPage = 1;
  int _endTripOtpTotalPages = 1;
  final int _endTripOtpItemsPerPage = 5; // Smaller number for embedded table

  Timer? _mapRefreshTimer;
  List<TripUpdateEntity> _tripUpdates = [];
  bool _isMapLoading = true;
  String? _mapErrorMessage;

  void _loadTripCoordinatesForMap() {
    debugPrint('🔄 Loading trip coordinates for map...');
    
    // Cancel any existing timer
    _coordinatesLoadingTimer?.cancel();
    
    if (!mounted) return;
    
    setState(() {
      _isCoordinatesLoading = true;
      _coordinatesErrorMessage = null;
    });

    // Load trip coordinates
    context.read<TripCoordinatesUpdateBloc>().add(
      GetTripCoordinatesByTripIdEvent(widget.tripId),
    );
    
    // Set timeout - if loading doesn't complete in 10 seconds, force stop loading
    _coordinatesLoadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isCoordinatesLoading) {
        debugPrint('⏱️ Coordinates loading timeout - forcing completion');
        setState(() {
          _isCoordinatesLoading = false;
          _coordinatesErrorMessage = 'Loading timeout - using cached data';
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Load trip details
    context.read<TripBloc>().add(GetTripTicketByIdEvent(widget.tripId));
    // Load customers for this trip
    context.read<DeliveryDataBloc>().add(
      GetDeliveryDataByTripIdEvent(widget.tripId),
    );
    // Load personnel for this trip
    context.read<PersonelBloc>().add(LoadPersonelsByTripIdEvent(widget.tripId));
    // Load OTPs for this trip
    context.read<OtpBloc>().add(LoadOtpByTripIdEvent(widget.tripId));
    // Load End Trip OTPs for this trip
    context.read<EndTripOtpBloc>().add(
      LoadEndTripOtpByTripIdEvent(widget.tripId),
    );
   
    // Load trip updates for map
    _loadTripUpdatesForMap();
    // Load trip coordinates for map
    _loadTripCoordinatesForMap();
    // Start auto-refresh timer for map data
    _startMapRefreshTimer();
  }

  // Update the _loadTripUpdatesForMap method
  void _loadTripUpdatesForMap() {
    debugPrint('🔄 Loading trip updates for map...');
    
    // Cancel any existing timer
    _mapLoadingTimer?.cancel();
    
    if (!mounted) return;
    
    setState(() {
      _isMapLoading = true;
      _mapErrorMessage = null;
    });

    // Load trip updates
    context.read<TripUpdatesBloc>().add(GetTripUpdatesEvent(widget.tripId));
    
    // Set timeout - if loading doesn't complete in 10 seconds, force stop loading
    _mapLoadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isMapLoading) {
        debugPrint('⏱️ Trip updates loading timeout - forcing completion');
        setState(() {
          _isMapLoading = false;
          _mapErrorMessage = 'Loading timeout - using cached data';
        });
      }
    });
  }

  // Update the _startMapRefreshTimer method
  void _startMapRefreshTimer() {
    // Cancel any existing timer
    _mapRefreshTimer?.cancel();

    // Create a new timer that refreshes the data every minute
    _mapRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        debugPrint('🔄 Auto-refreshing trip map data');
        // Don't set loading state for auto-refresh to avoid flickering
        context.read<TripUpdatesBloc>().add(GetTripUpdatesEvent(widget.tripId));
        context.read<TripCoordinatesUpdateBloc>().add(
          GetTripCoordinatesByTripIdEvent(widget.tripId),
        );
      }
    });
  }

  @override
  void dispose() {
    _mapRefreshTimer?.cancel();
    _coordinatesLoadingTimer?.cancel();
    _deliveryDataLoadingTimer?.cancel();
    _mapLoadingTimer?.cancel();
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/tripticket',
      onNavigate: (route) {
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
      disableScrolling: true,
      child: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TripBloc>().add(
                        GetTripTicketByIdEvent(widget.tripId),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TripTicketLoaded) {
            final trip = state.trip;

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  floating: true,
                  snap: true,
                  title: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          context.go('/tripticket');
                        },
                      ),
                      Text('Trip Ticket: ${trip.tripNumberId ?? 'N/A'}'),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () {
                        context.read<TripBloc>().add(
                          GetTripTicketByIdEvent(widget.tripId),
                        );
                        context.read<DeliveryDataBloc>().add(
                          GetDeliveryDataByTripIdEvent(widget.tripId),
                        );
                        context.read<PersonelBloc>().add(
                          LoadPersonelsByTripIdEvent(widget.tripId),
                        );
                        context.read<OtpBloc>().add(
                          LoadOtpByTripIdEvent(widget.tripId),
                        );
                      },
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Trip Header
                      // TripHeaderWidget(
                      //   trip: trip,
                      //   onEditPressed: () {
                      //     // Navigate to edit trip screen
                      //   },
                      //   onOptionsPressed: () {
                      //     showTripOptionsDialog(context, trip);
                      //   },
                      // ),
                      const SizedBox(height: 16),

                      // Trip Dashboard
                      TripDashboardWidget(
                        trip: trip,
                        onEditTrip: () {
                          // Navigate to edit trip screen using router
                          if (trip.id != null) {
                            context.go('/tripticket-edit/${trip.id}');
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Map Placeholder
                      // With this:
                      _buildTripMapWidget(trip),

                      const SizedBox(height: 16),

                      _buildCustomerTable(),

                      const SizedBox(height: 16),

                      // Personnel Table
                      TripPersonelsTable(
                        tripId: widget.tripId,
                        onAddPersonel: () {
                          // Navigate to add personnel screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Add personnel feature coming soon',
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Vehicle Table
                      TripVehicleTable(
                        tripId: widget.tripId,
                        onAddVehicle: () {
                          // Navigate to add vehicle screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add vehicle feature coming soon'),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // OTP Table
                      _buildOtpTable(),

                      const SizedBox(height: 16),

                      // End Trip OTP Table
                      _buildEndTripOtpTable(),

                      // Add some bottom padding
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Select a trip to view details'));
        },
      ),
    );
  }

  Widget _buildCustomerTable() {
  return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
    builder: (context, state) {
      if (state is DeliveryDataError) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading customer data: ${state.message}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<DeliveryDataBloc>().add(
                      GetDeliveryDataByTripIdEvent(widget.tripId),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      if (state is DeliveryDataByTripLoaded) {
        // Get customers from the state
        List<DeliveryDataEntity> deliveryData = List<DeliveryDataEntity>.from(
          state.deliveryData,
        );

        // Filter based on search query
        if (_customerSearchQuery.isNotEmpty) {
          final query = _customerSearchQuery.toLowerCase();
          deliveryData = deliveryData
              .where(
                (customer) =>
                    (customer.customer!.name?.toLowerCase().contains(
                          query,
                        ) ??
                        false) ||
                    (customer.customer!.province?.toLowerCase().contains(
                          query,
                        ) ??
                        false) ||
                    (customer.deliveryNumber?.toLowerCase().contains(
                          query,
                        ) ??
                        false),
              )
              .toList();
        }

        // Calculate total pages
        _customerTotalPages =
            (deliveryData.length / _customerItemsPerPage).ceil();
        if (_customerTotalPages == 0) _customerTotalPages = 1;

        return TripCustomersTable(
          tripId: widget.tripId,
          isLoading: false,
          currentPage: _customerCurrentPage,
          totalPages: _customerTotalPages,
          onPageChanged: (page) {
            setState(() {
              _customerCurrentPage = page;
            });
          },
          searchController: _customerSearchController,
          searchQuery: _customerSearchQuery,
          onSearchChanged: (value) {
            setState(() {
              _customerSearchQuery = value;
            });
          },
          onAttachCustomer: () {
            // Navigate to attach customer screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attach customer feature coming soon'),
              ),
            );
          },
        );
      }

      // Default case - show loading or empty state
      return TripCustomersTable(
        tripId: widget.tripId,
        isLoading: state is DeliveryDataLoading,
        currentPage: _customerCurrentPage,
        totalPages: _customerTotalPages,
        onPageChanged: (page) {
          setState(() {
            _customerCurrentPage = page;
          });
        },
        searchController: _customerSearchController,
        searchQuery: _customerSearchQuery,
        onSearchChanged: (value) {
          setState(() {
            _customerSearchQuery = value;
          });
        },
        onAttachCustomer: () {
          // Navigate to attach customer screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attach customer feature coming soon'),
            ),
          );
        },
      );
    },
  );
}


  // Add this method to your class
  Widget _buildTripMapWidget(TripEntity trip) {
    return BlocConsumer<DeliveryDataBloc, DeliveryDataState>(
      listener: (context, deliveryState) {
        // Cancel timeout timer when we get a response
        _deliveryDataLoadingTimer?.cancel();
        
        if (!mounted) return;
        
        if (deliveryState is DeliveryDataByTripLoaded && deliveryState.tripId == widget.tripId) {
          setState(() {
            _deliveryData = deliveryState.deliveryData;
            _isDeliveryDataLoading = false;
            _deliveryDataErrorMessage = null;
          });
          debugPrint('✅ Loaded ${deliveryState.deliveryData.length} delivery data for map');
        } else if (deliveryState is DeliveryDataError) {
          setState(() {
            _deliveryDataErrorMessage = deliveryState.message;
            _isDeliveryDataLoading = false;
          });
          debugPrint('❌ Error loading delivery data: ${deliveryState.message}');
        } else if (deliveryState is DeliveryDataLoading) {
          setState(() {
            _isDeliveryDataLoading = true;
            _deliveryDataErrorMessage = null;
          });
          
          // Set timeout for delivery data loading
          _deliveryDataLoadingTimer = Timer(const Duration(seconds: 10), () {
            if (mounted && _isDeliveryDataLoading) {
              debugPrint('⏱️ Delivery data loading timeout - forcing completion');
              setState(() {
                _isDeliveryDataLoading = false;
                _deliveryDataErrorMessage = 'Loading timeout - using cached data';
              });
            }
          });
        }
      },
      builder: (context, deliveryState) {
        return BlocConsumer<TripUpdatesBloc, TripUpdatesState>(
          listener: (context, state) {
            // Cancel timeout timer when we get a response
            _mapLoadingTimer?.cancel();
            
            if (!mounted) return;
            
            if (state is TripUpdatesError) {
              setState(() {
                _mapErrorMessage = state.message;
                _isMapLoading = false;
              });
              debugPrint('❌ Error loading trip updates: ${state.message}');
            } else if (state is TripUpdatesLoaded) {
              setState(() {
                _tripUpdates = state.updates;
                _isMapLoading = false;
                _mapErrorMessage = null;
              });
              debugPrint('✅ Loaded ${_tripUpdates.length} trip updates');
            } else if (state is TripUpdatesLoading) {
              if (!mounted) return;
              setState(() {
                _isMapLoading = true;
                _mapErrorMessage = null;
              });
            }
          },
          builder: (context, updatesState) {
            return BlocConsumer<
              TripCoordinatesUpdateBloc,
              TripCoordinatesUpdateState
            >(
              listener: (context, state) {
                // Cancel timeout timer when we get a response
                _coordinatesLoadingTimer?.cancel();
                
                if (!mounted) return;
                
                if (state is TripCoordinatesUpdateError) {
                  setState(() {
                    _coordinatesErrorMessage = state.message;
                    _isCoordinatesLoading = false;
                  });
                  debugPrint('❌ Error loading trip coordinates: ${state.message}');
                } else if (state is TripCoordinatesUpdateLoaded) {
                  setState(() {
                    _tripCoordinates = state.coordinates;
                    _isCoordinatesLoading = false;
                    _coordinatesErrorMessage = null;
                  });
                  debugPrint(
                    '✅ Loaded ${_tripCoordinates.length} trip coordinates',
                  );
                } else if (state is TripCoordinatesUpdateEmpty) {
                  setState(() {
                    _tripCoordinates = [];
                    _isCoordinatesLoading = false;
                    _coordinatesErrorMessage = null;
                  });
                  debugPrint('ℹ️ No trip coordinates found');
                } else if (state is TripCoordinatesUpdateLoading) {
                  if (!mounted) return;
                  setState(() {
                    _isCoordinatesLoading = true;
                    _coordinatesErrorMessage = null;
                  });
                }
              },
              builder: (context, coordinatesState) {
                // Always show the map widget, but pass the loading state
                return TripMapWidget(
                  tripId: widget.tripId,
                  trip: trip,
                  tripUpdates: _tripUpdates,
                  tripCoordinates: _tripCoordinates,
                  deliveryData: _deliveryData,
                  isLoading:
                      updatesState is TripUpdatesLoading ||
                      _isMapLoading ||
                      coordinatesState is TripCoordinatesUpdateLoading ||
                      _isCoordinatesLoading ||
                      _isDeliveryDataLoading,
                  errorMessage: _mapErrorMessage ?? _coordinatesErrorMessage ?? _deliveryDataErrorMessage,
                  onRefresh: () {
                    _loadTripUpdatesForMap();
                    _loadTripCoordinatesForMap();
                    context.read<DeliveryDataBloc>().add(
                      GetDeliveryDataByTripIdEvent(widget.tripId),
                    );
                  },
                  height: 400,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOtpTable() {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        if (state is OtpLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is OtpError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading OTP data: ${state.message}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<OtpBloc>().add(
                        LoadOtpByTripIdEvent(widget.tripId),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is OtpDataLoaded) {
          // Single OTP loaded
          return TripOtpTable(
            otps: [state.otp],
            isLoading: false,
            currentPage: _otpCurrentPage,
            totalPages: 1,
            onPageChanged: (page) {
              setState(() {
                _otpCurrentPage = page;
              });
            },
            tripId: widget.tripId,
          );
        }

        if (state is AllOtpsLoaded) {
          // Filter OTPs for this trip
          final tripOtps =
              state.otps.where((otp) => otp.trip?.id == widget.tripId).toList();

          // Calculate total pages
          _otpTotalPages = (tripOtps.length / _otpItemsPerPage).ceil();
          if (_otpTotalPages == 0) _otpTotalPages = 1;

          // Paginate OTPs
          final startIndex = (_otpCurrentPage - 1) * _otpItemsPerPage;
          final endIndex =
              startIndex + _otpItemsPerPage > tripOtps.length
                  ? tripOtps.length
                  : startIndex + _otpItemsPerPage;

          final List<OtpEntity> paginatedOtps =
              startIndex < tripOtps.length
                  ? List<OtpEntity>.from(
                    tripOtps.sublist(startIndex, endIndex),
                  )
                  : <OtpEntity>[];

          return TripOtpTable(
            otps: paginatedOtps,
            isLoading: false,
            currentPage: _otpCurrentPage,
            totalPages: _otpTotalPages,
            onPageChanged: (page) {
              setState(() {
                _otpCurrentPage = page;
              });
            },
            tripId: widget.tripId,
          );
        }

        // Default case - no OTPs yet
        return TripOtpTable(
          otps: [],
          isLoading: false,
          currentPage: _otpCurrentPage,
          totalPages: _otpTotalPages,
          onPageChanged: (page) {
            setState(() {
              _otpCurrentPage = page;
            });
          },
          tripId: widget.tripId,
        );
      },
    );
  }

  Widget _buildEndTripOtpTable() {
    return BlocBuilder<EndTripOtpBloc, EndTripOtpState>(
      builder: (context, state) {
        if (state is EndTripOtpLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is EndTripOtpError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading End Trip OTP data: ${state.message}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<EndTripOtpBloc>().add(
                        LoadEndTripOtpByTripIdEvent(widget.tripId),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is EndTripOtpDataLoaded) {
          // Single End Trip OTP loaded
          return TripEndTripOtpTable(
            endTripOtps: [state.otp],
            isLoading: false,
            currentPage: _endTripOtpCurrentPage,
            totalPages: 1,
            onPageChanged: (page) {
              setState(() {
                _endTripOtpCurrentPage = page;
              });
            },
          );
        }

        if (state is AllEndTripOtpsLoaded) {
          // Filter End Trip OTPs for this trip
          final tripEndTripOtps =
              state.otps.where((otp) => otp.trip?.id == widget.tripId).toList();

          // Calculate total pages
          _endTripOtpTotalPages =
              (tripEndTripOtps.length / _endTripOtpItemsPerPage).ceil();
          if (_endTripOtpTotalPages == 0) _endTripOtpTotalPages = 1;

          // Paginate End Trip OTPs
          final startIndex =
              (_endTripOtpCurrentPage - 1) * _endTripOtpItemsPerPage;
          final endIndex =
              startIndex + _endTripOtpItemsPerPage > tripEndTripOtps.length
                  ? tripEndTripOtps.length
                  : startIndex + _endTripOtpItemsPerPage;

          // Use proper type casting with List.from() to avoid type errors
          final List<EndTripOtpEntity> paginatedEndTripOtps =
              startIndex < tripEndTripOtps.length
                  ? List<EndTripOtpEntity>.from(
                    tripEndTripOtps.sublist(startIndex, endIndex),
                  )
                  : <EndTripOtpEntity>[];

          return TripEndTripOtpTable(
            endTripOtps: paginatedEndTripOtps,
            isLoading: false,
            currentPage: _endTripOtpCurrentPage,
            totalPages: _endTripOtpTotalPages,
            onPageChanged: (page) {
              setState(() {
                _endTripOtpCurrentPage = page;
              });
            },
          );
        }

        // Default case - no End Trip OTPs yet
        return TripEndTripOtpTable(
          endTripOtps: [],
          isLoading: false,
          currentPage: _endTripOtpCurrentPage,
          totalPages: _endTripOtpTotalPages,
          onPageChanged: (page) {
            setState(() {
              _endTripOtpCurrentPage = page;
            });
          },
        );
      },
    );
  }
}
