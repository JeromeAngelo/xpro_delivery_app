import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_state.dart';

import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class HomepageDashboard extends StatefulWidget {
  const HomepageDashboard({super.key});

  @override
  State<HomepageDashboard> createState() => _HomepageDashboardState();
}

class _HomepageDashboardState extends State<HomepageDashboard> {
  late final AuthBloc _authBloc;
  late final DeliveryTeamBloc _deliveryTeamBloc;
  bool _isInitialized = false;
  DeliveryTeamState? _cachedState;

  @override
  void initState() {
    super.initState();
    debugPrint('📱 Dashboard initialized');
    _initializeBlocs();
    _loadInitialData();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _deliveryTeamBloc = context.read<DeliveryTeamBloc>();
  }

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final userId = userData['id'];

      if (userId != null) {
        debugPrint('🔄 Loading user data for ID: $userId');
        // Load user data
        _authBloc
          ..add(LoadLocalUserByIdEvent(userId))
          ..add(LoadUserByIdEvent(userId));

        // Load user's trip
        _authBloc
          ..add(LoadLocalUserTripEvent(userId))
          ..add(GetUserTripEvent(userId));
      }
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is UserTripLoaded) {
              debugPrint('🎫 User trip loaded: ${state.trip.id}');
              _deliveryTeamBloc
                ..add(LoadLocalDeliveryTeamEvent(state.trip.id!))
                ..add(LoadDeliveryTeamEvent(state.trip.id!));
            }

            // if (state is UserByIdLoaded && state.user.tripNumberId != null) {
            //   debugPrint(
            //       '👤 User loaded with trip: ${state.user.tripNumberId}');
            //   _deliveryTeamBloc
            //     ..add(LoadLocalDeliveryTeamEvent(state.user.tripNumberId!))
            //     ..add(LoadDeliveryTeamEvent(state.user.tripNumberId!));
            // }
          },
        ),
        BlocListener<DeliveryTeamBloc, DeliveryTeamState>(
          listener: (context, state) {
            if (state is DeliveryTeamLoaded) {
              debugPrint('🚛 Delivery team loaded and cached');
              setState(() => _cachedState = state);
            }
          },
        ),
      ],
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildDashboardContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is UserByIdLoaded) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.user.name ?? 'No User Name',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trip Number: ${state.user.tripNumberId ?? 'No Trip Number'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return const Text('Loading user data...');
      },
    );
  }

  Widget _buildDashboardContent() {
    return BlocBuilder<DeliveryTeamBloc, DeliveryTeamState>(
      builder: (context, state) {
        final effectiveState = _cachedState ?? state;

        if (effectiveState is DeliveryTeamLoaded) {
          final team = effectiveState.deliveryTeam;
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 22,
            children: [
              _buildInfoItem(
                context,
                Icons.numbers,
                team.vehicle.isNotEmpty
                    ? team.vehicle.first.vehiclePlateNumber ?? 'Not Assigned'
                    : 'Not Assigned',
                'Plate Number',
              ),
              _buildInfoItem(
                context,
                Icons.local_shipping,
                team.vehicle.isNotEmpty
                    ? team.vehicle.first.vehicleName ?? 'Not Assigned'
                    : 'Not Assigned',
                'Vehicle',
              ),
              _buildInfoItem(
                context,
                Icons.delivery_dining,
                '${team.activeDeliveries ?? 0}',
                'Active Deliveries',
              ),
              _buildInfoItem(
                context,
                Icons.done_all,
                '${team.totalDelivered ?? 0}',
                'Total Delivered',
              ),
              _buildInfoItem(
                context,
                Icons.route,
                '${team.totalDistanceTravelled ?? 0} km',
                'Distance Travelled',
              ),
              _buildInfoItem(
                context,
                Icons.warning_amber,
                '${team.undeliveredCustomers ?? 0}',
                'Undelivered',
              ),
            ],
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 22,
          children: [
            _buildInfoItem(
                context, Icons.numbers, 'Not Assigned', 'Plate Number'),
            _buildInfoItem(
                context, Icons.local_shipping, 'Not Assigned', 'Vehicle'),
            _buildInfoItem(
                context, Icons.delivery_dining, '0', 'Active Deliveries'),
            _buildInfoItem(context, Icons.done_all, '0', 'Total Delivered'),
            _buildInfoItem(context, Icons.route, '0 km', 'Distance Travelled'),
            _buildInfoItem(context, Icons.warning_amber, '0', 'Undelivered'),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}