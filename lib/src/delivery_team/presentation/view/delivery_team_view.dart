import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
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
    with AutomaticKeepAliveClientMixin {
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveryTeamData();
  }

  void _loadDeliveryTeamData() {
    if (!_isDataInitialized) {
      final tripState = context.read<TripBloc>().state;
      if (tripState is TripLoaded && tripState.trip.id != null) {
        debugPrint('📱 Loading delivery team data for trip: ${tripState.trip.id}');
        context.read<DeliveryTeamBloc>().add(LoadDeliveryTeamEvent(tripState.trip.id!));
        _isDataInitialized = true;
       } // else {
      //   debugPrint('⚠️ No trip data available, loading all delivery teams');
      //   context.read<DeliveryTeamBloc>().add(const LoadAllDeliveryTeamsEvent());
      //   _isDataInitialized = true;
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: BlocBuilder<DeliveryTeamBloc, DeliveryTeamState>(
        builder: (context, state) {
          debugPrint('🔄 DeliveryTeamView state: ${state.runtimeType}');
          
          return CustomScrollView(
            slivers: [
              const DeliveryTeamProfileHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      
                      // ADDED: Show loading indicator when loading
                      if (state is DeliveryTeamLoading)
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading delivery team data...'),
                            ],
                          ),
                        )
                      
                      // ADDED: Show error message if error
                      else if (state is DeliveryTeamError)
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
                      
                      // ADDED: Show actions when data is loaded or for other states
                      else
                        DeliveryTeamActions(
                          onViewPersonnel: () => _navigateToPersonnel(context, state),
                          onViewTripTicket: () => _navigateToTrips(context, state),
                          onViewVehicle: () => _navigateToVehicle(context, state),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
