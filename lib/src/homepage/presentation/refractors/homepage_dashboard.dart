import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
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
  DeliveryTeamState? _cachedDeliveryTeamState;
  AuthState? _cachedAuthState;

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
    debugPrint('📱 Dashboard initialized - waiting for data from parent');
    // Data loading is handled by parent homepage_view.dart to avoid duplicates
    _isInitialized = true;
  }

  Future<String> _getUserNameFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('user_data');
      
      if (storedData != null) {
        final userData = jsonDecode(storedData);
        return userData['name'] ?? 'User Name';
      }
    } catch (e) {
      debugPrint('⚠️ Error getting user name from storage: $e');
    }
    return 'User Name';
  }



  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // 📱 OFFLINE-FIRST: Cache successful states only
            if (state is UserByIdLoaded || state is UserTripLoaded) {
              debugPrint('📱 Dashboard caching auth state: ${state.runtimeType}');
              setState(() => _cachedAuthState = state);
            }
            
            // Handle network errors gracefully by preserving cached state
            if (state is AuthError) {
              debugPrint('⚠️ Auth network error, using cached data: ${state.message}');
              // Keep using cached state, no UI changes needed
            }
            
            // NOTE: Delivery team loading is handled by parent homepage_view.dart 
            // to avoid duplicate network calls and rate limiting
          },
        ),
        BlocListener<DeliveryTeamBloc, DeliveryTeamState>(
          listener: (context, state) {
            if (state is DeliveryTeamLoaded) {
              debugPrint('🚛 Delivery team loaded and cached');
              setState(() => _cachedDeliveryTeamState = state);
            }
            
            // Handle delivery team errors gracefully
            if (state is DeliveryTeamError) {
              debugPrint('⚠️ Delivery team network error, using cached data: ${state.message}');
              // Keep using cached state, no UI changes needed
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
        // 📱 OFFLINE-FIRST: Always prioritize cached data, ignore loading states
        AuthState? effectiveState;
        
        // Use cached data if available, regardless of current state
        if (_cachedAuthState is UserByIdLoaded || _cachedAuthState is UserTripLoaded) {
          effectiveState = _cachedAuthState;
          debugPrint('📱 Dashboard using cached auth state: ${_cachedAuthState.runtimeType}');
        }
        // Only use current state if it's a data state and we have no cache
        else if ((state is UserByIdLoaded || state is UserTripLoaded) && _cachedAuthState == null) {
          effectiveState = state;
          debugPrint('📱 Dashboard using current auth state: ${state.runtimeType}');
        }
        
        if (effectiveState is UserByIdLoaded) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effectiveState.user.name ?? 'No User Name',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trip Number: ${effectiveState.user.tripNumberId ?? 'No Trip Number'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    
                  ],
                ),
              ),
            ],
          );
        }
        
        if (effectiveState is UserTripLoaded) {
          return FutureBuilder<String>(
            future: _getUserNameFromStorage(),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Trip Number: ${(effectiveState as UserTripLoaded).trip.tripNumberId ?? 'No Trip Number'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                      'Route: ${(effectiveState).trip.name ?? 'No Trip Route'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }
        
        // Only show loading if we have no cached data at all
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading user data...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    return BlocBuilder<DeliveryTeamBloc, DeliveryTeamState>(
      builder: (context, state) {
        // 📱 OFFLINE-FIRST: Always prioritize cached data, ignore loading states
        DeliveryTeamState? effectiveState;
        
        // Use cached data if available, regardless of current state
        if (_cachedDeliveryTeamState is DeliveryTeamLoaded) {
          effectiveState = _cachedDeliveryTeamState;
          debugPrint('📱 Dashboard using cached delivery team state');
        }
        // Only use current state if it's loaded and we have no cache
        else if (state is DeliveryTeamLoaded && _cachedDeliveryTeamState == null) {
          effectiveState = state;
          debugPrint('📱 Dashboard using current delivery team state');
        }

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
                team.deliveryVehicle.target != null
                    ? team.deliveryVehicle.target!.name ?? 'Not Assigned'
                    : 'Not Assigned',
                'Plate Number',
              ),
              _buildInfoItem(
                context,
                Icons.local_shipping,
                team.deliveryVehicle.target != null
                    ? '${team.deliveryVehicle.target!.make ?? ''} ${team.deliveryVehicle.target!.name ?? ''}'
                            .trim()
                            .isEmpty
                        ? team.deliveryVehicle.target!.name ?? 'Not Assigned'
                        : '${team.deliveryVehicle.target!.make ?? ''} '
                    : 'Not Assigned',
                'Vehicle',
              ),
              _buildInfoItem(
                context,
                Icons.pending_actions,
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
        
        // Show fallback grid (no loading spinner to avoid flickering)
        return _buildFallbackGrid();
      },
    );
  }
  
  Widget _buildFallbackGrid() {
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
          'Not Assigned',
          'Plate Number',
        ),
        _buildInfoItem(
          context,
          Icons.local_shipping,
          'Not Assigned',
          'Vehicle',
        ),
        _buildInfoItem(
          context,
          Icons.pending_actions,
          '0',
          'Active Deliveries',
        ),
        _buildInfoItem(context, Icons.done_all, '0', 'Total Delivered'),
        _buildInfoItem(context, Icons.route, '0 km', 'Distance Travelled'),
        _buildInfoItem(context, Icons.warning_amber, '0', 'Undelivered'),
      ],
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
        border: Border.all(color: Colors.transparent),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
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
