import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';

class DeliveryTeamDashboard extends StatefulWidget {
  const DeliveryTeamDashboard({super.key});

  @override
  State<DeliveryTeamDashboard> createState() => _DeliveryTeamDashboardState();
}

class _DeliveryTeamDashboardState extends State<DeliveryTeamDashboard> {
  DeliveryTeamState? _cachedState;
  MapController mapController = MapController();
  LatLng? currentLocation;
  bool isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Add debug print for initialization
    debugPrint('🚀 Initializing DeliveryTeamDashboard');
    _loadInitialData();
    _getCurrentLocation();
  }

  void _loadInitialData() {
    final tripBloc = context.read<TripBloc>();
    final tripState = tripBloc.state;

    if (tripState is TripLoaded) {
      final deliveryTeamId = tripState.trip.deliveryTeam.target?.id;
      if (deliveryTeamId != null) {
        debugPrint('📥 Loading delivery team data for ID: $deliveryTeamId');
        final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
        // Force refresh of delivery team data
        deliveryTeamBloc
          ..add(LoadDeliveryTeamByIdEvent(deliveryTeamId))
          ..add(LoadLocalDeliveryTeamEvent(deliveryTeamId));
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        isMapReady = true;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryTeamBloc, DeliveryTeamState>(
      listenWhen: (previous, current) =>
          current is DeliveryTeamLoaded || current is DeliveryTeamError,
      listener: (context, state) {
        debugPrint('📊 DeliveryTeamBloc State Update: ${state.runtimeType}');
        if (state is DeliveryTeamLoaded) {
          debugPrint(
              '✅ Team Members Loaded: ${state.deliveryTeam.personels.length}');
        }
        setState(() {
          _cachedState = state;
        });
      },
      buildWhen: (previous, current) =>
          current is DeliveryTeamLoaded || current is DeliveryTeamError,
      builder: (context, state) {
        debugPrint('🔄 Building Dashboard with state: ${state.runtimeType}');
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: _buildDashboard(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context, DeliveryTeamState state) {
    debugPrint('🎯 Building dashboard with state: ${state.toString()}');
    final team = (state is DeliveryTeamLoaded)
        ? state.deliveryTeam
        : DeliveryTeamEntity.empty();

    // Add debug print to verify team data
    debugPrint('👥 Team Members Count: ${team.personels.length}');
    for (var personnel in team.personels) {
      debugPrint(
          '🧑‍💼 Displaying Team Member: ${personnel.name} (${personnel.role})');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        _buildTeamMembers(context, team),
        const SizedBox(height: 20),
        _buildFeatureGrid(context),
        const SizedBox(height: 20),
        _buildLocationSection(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.read<UserProvider>().user?.name ??
                      'No Driver Assigned',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Delivery Team Lead',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  context.watch<UserProvider>().user?.tripNumberId ??
                      'No Trip Number',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembers(BuildContext context, DeliveryTeamEntity team) {
    String formatRole(UserRole? role) {
      if (role == null) return 'Unknown';
      return role.toString().split('.').last[0].toUpperCase() +
          role.toString().split('.').last.substring(1).toLowerCase();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Members',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...team.personels.map((personnel) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    personnel.name?[0] ?? 'N/A',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(personnel.name ?? 'Unnamed Personnel'),
                subtitle: Text(formatRole(personnel.role)),
              )),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildFeatureCard(
                context,
                Icons.confirmation_number_outlined,
                'Trip Tickets',
                Theme.of(context).colorScheme.primaryFixed,
              ),
              _buildFeatureCard(
                context,
                Icons.receipt_long_outlined,
                'Transactions',
                Theme.of(context).colorScheme.primaryFixed,
              ),
              _buildFeatureCard(
                context,
                Icons.local_shipping_outlined,
                'Assigned Vehicle',
                Theme.of(context).colorScheme.primaryFixed,
              ),
              _buildFeatureCard(
                context,
                Icons.checklist_outlined,
                'Checklist',
                Theme.of(context).colorScheme.primaryFixed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Current Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: 300,
              child: _buildMap(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (!isMapReady || currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentLocation!,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: currentLocation!,
              width: 40,
              height: 40,
              child: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}