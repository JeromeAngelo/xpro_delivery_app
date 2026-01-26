import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/src/delivery_team/initial_screens/view_personel_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_team/initial_screens/view_trips_screens.dart';
import 'package:x_pro_delivery_app/src/delivery_team/initial_screens/view_vehicle_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_team/presentation/widget/delivery_team_header.dart';
import 'package:x_pro_delivery_app/src/delivery_team/presentation/widget/delivery_team_members.dart';

class DeliveryTeamView extends StatefulWidget {
  const DeliveryTeamView({super.key});

  @override
  State<DeliveryTeamView> createState() => _DeliveryTeamViewState();
}

class _DeliveryTeamViewState extends State<DeliveryTeamView>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool _isDataInitialized = false;
  DeliveryTeamState? _cachedDeliveryTeamState;
  TripState? _cachedTripState;
  DateTime? _lastRefreshTime;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocalData();
    _hasInitialized = true;
    _lastRefreshTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - refreshing delivery team data');
      _forceRefreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_hasInitialized) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent && route.isActive) {
        debugPrint('🔄 Screen became active, refreshing delivery team data...');
        _refreshData();
      }
    }
  }

  void _loadLocalData() {
    debugPrint('📱 Loading local delivery team data');

    final tripBloc = context.read<TripBloc>();
    final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
    
    // Load local trip data first
    final tripState = tripBloc.state;
    if (tripState is TripLoaded && tripState.trip.id != null) {
      debugPrint('📱 Loading local delivery team data for trip: ${tripState.trip.id}');
      deliveryTeamBloc.add(LoadLocalDeliveryTeamEvent(tripState.trip.id!));
      
      // Then sync remote data if online
      final connectivity = context.read<ConnectivityProvider>();
      if (connectivity.isOnline) {
        debugPrint('🌐 Online: Syncing fresh delivery team data');
        deliveryTeamBloc.add(LoadDeliveryTeamEvent(tripState.trip.id!));
      } else {
        debugPrint('📱 Offline: Using cached delivery team data only');
      }
    } else {
      debugPrint('⚠️ No trip data available yet');
    }
    
    _isDataInitialized = true;
  }

  void _refreshData() {
    debugPrint('🔄 Refreshing delivery team data');

    final tripBloc = context.read<TripBloc>();
    final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
    
    final tripState = tripBloc.state;
    if (tripState is TripLoaded && tripState.trip.id != null) {
      // 📱 OFFLINE-FIRST: Load local data immediately
      deliveryTeamBloc.add(LoadLocalDeliveryTeamEvent(tripState.trip.id!));
      
      // 🌐 Then sync remote data if online
      final connectivity = context.read<ConnectivityProvider>();
      if (connectivity.isOnline) {
        debugPrint('🌐 Online: Syncing fresh delivery team data');
        deliveryTeamBloc.add(LoadDeliveryTeamEvent(tripState.trip.id!));
      } else {
        debugPrint('📱 Offline: Using cached delivery team data only');
      }
    }
  }

  void _forceRefreshData() {
    debugPrint('🔄 Force refreshing delivery team data');

    final tripBloc = context.read<TripBloc>();
    final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
    final connectivity = context.read<ConnectivityProvider>();
    
    final tripState = tripBloc.state;
    if (tripState is TripLoaded && tripState.trip.id != null) {
      if (connectivity.isOnline) {
        debugPrint('🌐 Force refresh: Loading fresh data from remote');
        deliveryTeamBloc.add(LoadDeliveryTeamEvent(tripState.trip.id!));
      } else {
        debugPrint('📱 Force refresh: Offline, loading latest cached data');
        deliveryTeamBloc.add(LoadLocalDeliveryTeamEvent(tripState.trip.id!));
      }
      _lastRefreshTime = DateTime.now();
    }
  }

  void _loadDeliveryTeamData() {
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryTeamBloc, DeliveryTeamState>(
          listener: (context, state) {
            debugPrint('🎯 DeliveryTeamBloc state changed: $state');
            
            if (state is DeliveryTeamLoaded) {
              setState(() => _cachedDeliveryTeamState = state);
              debugPrint('✅ Cached delivery team state updated');
            }
          },
        ),
        BlocListener<TripBloc, TripState>(
          listener: (context, state) {
            debugPrint('🎯 TripBloc state changed: $state');
            
            if (state is TripLoaded) {
              setState(() => _cachedTripState = state);
              debugPrint('✅ Cached trip state updated');
              
              // Reload delivery team data when trip changes
              _refreshData();
            }
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<DeliveryTeamBloc, DeliveryTeamState>(
          builder: (context, state) {
            debugPrint('🔄 DeliveryTeamView state: ${state.runtimeType}');
            
            // Use cached state if available for better UX
            final effectiveState = (state is DeliveryTeamLoaded) 
                ? state 
                : _cachedDeliveryTeamState;
            
            return Column(
              children: [
                // 📶 Network status indicator
                Consumer<ConnectivityProvider>(
                  builder: (context, connectivity, child) {
                    if (!connectivity.isOnline) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.orange,
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Offline - Showing cached data',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      const DeliveryTeamProfileHeader(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              
                              // Show loading indicator when loading and no cached data
                              if (state is DeliveryTeamLoading && effectiveState == null)
                                const Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Loading delivery team data...'),
                                    ],
                                  ),
                                )
                              
                              // Show error message if error and no cached data
                              else if (state is DeliveryTeamError && effectiveState == null)
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 64,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Error Loading Data',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        state.message,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadDeliveryTeamData,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              
                              // Show actions when data is loaded or using cached data
                              else
                                DeliveryTeamActions(
                                  onViewPersonnel: () => _navigateToPersonnel(context, effectiveState ?? state),
                                  onViewTripTicket: () => _navigateToTrips(context, effectiveState ?? state),
                                  onViewVehicle: () => _navigateToVehicle(context, effectiveState ?? state),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ADDED: Navigate to personnel screen with delivery team data
  void _navigateToPersonnel(BuildContext context, DeliveryTeamState state) {
    debugPrint('🧑‍💼 Navigating to personnel screen');
    
    if (state is DeliveryTeamLoaded) {
      debugPrint('✅ Passing delivery team data to personnel screen');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewPersonelScreen(
        deliveryTeam: state.deliveryTeam,
          ),
        ),
      );
    } else {
      debugPrint('⚠️ No delivery team data available for personnel screen');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ViewPersonelScreen(),
        ),
      );
    }
  }

  // ADDED: Navigate to trips screen
  void _navigateToTrips(BuildContext context, DeliveryTeamState state) {
    debugPrint('🎫 Navigating to trips screen');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ViewTripsScreen(),
      ),
    );
  }

  // UPDATED: Navigate to vehicle screen with delivery team data
  void _navigateToVehicle(BuildContext context, DeliveryTeamState state) {
    debugPrint('🚛 Navigating to vehicle screen');
    debugPrint('🔍 Current state: ${state.runtimeType}');
    
    if (state is DeliveryTeamLoaded) {
      debugPrint('✅ Delivery team loaded, checking vehicle data');
      debugPrint('🚛 Delivery vehicle: ${state.deliveryTeam.deliveryVehicle.target}');
      debugPrint('🚛 Vehicle plate: ${state.deliveryTeam.deliveryVehicle.target?.plateNo}');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewVehicleScreen(
            deliveryTeam: state.deliveryTeam,
          ),
        ),
      );
    }else {
      debugPrint('⚠️ No delivery team data available, showing empty vehicle screen');
      
      // Show a snackbar to inform user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading delivery team data, please wait...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Try to reload data
      _isDataInitialized = false;
      _loadDeliveryTeamData();
      
      // Navigate to empty screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ViewVehicleScreen(),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}
