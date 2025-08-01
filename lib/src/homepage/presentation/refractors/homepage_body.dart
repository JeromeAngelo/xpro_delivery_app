import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/refractors/delivery_timline_tile.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/refractors/trip_summary_tile.dart';

class HomepageBody extends StatefulWidget {
  const HomepageBody({super.key});

  @override
  State<HomepageBody> createState() => _HomepageBodyState();
}

class _HomepageBodyState extends State<HomepageBody>
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  AuthState? _cachedUserState;
  AuthState? _cachedTripState;
  final bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
  }

  void _setupListeners() {
    debugPrint('📱 Homepage Body initialized - waiting for data from parent');
    // Data loading is handled by parent homepage_view.dart to avoid duplicates
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // 📱 OFFLINE-FIRST: Cache successful states
        if (state is UserByIdLoaded) {
          setState(() => _cachedUserState = state);
        }
        if (state is UserTripLoaded) {
          setState(() => _cachedTripState = state);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          debugPrint('🎯 Homepage Body State: $state');

          // Determine effective user state (current or cached)
          final effectiveUserState = (state is UserByIdLoaded) ? state : _cachedUserState;
          final effectiveTripState = (state is UserTripLoaded) ? state : _cachedTripState;

          // Check if user has a trip assigned
          bool hasTrip = false;
          
          if (effectiveUserState is UserByIdLoaded) {
            final user = effectiveUserState.user;
            hasTrip = user.tripNumberId != null && user.tripNumberId!.isNotEmpty;
          }
          
          // Also check if we have trip data directly
          if (effectiveTripState is UserTripLoaded) {
            hasTrip = true;
          }

          if (hasTrip) {
            debugPrint('✅ Trip found - showing delivery timeline');
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DeliveryTimelineTile(),
                SizedBox(height: 8),
                TripSummaryTile(),
              ],
            );
          }

          debugPrint('📋 No trip assigned - showing empty state');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Image.asset('assets/images/no_ticket.png'),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Trip Assigned',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (state is AuthLoading) ...[
                  const SizedBox(height: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Checking for trip data...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
