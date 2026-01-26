import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
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

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    debugPrint('📱 Homepage Body initialized - waiting for data from parent');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // ✅ cache user
        if (state is UserByIdLoaded) {
          final userHasTrip = (state.user.tripNumberId ?? '').trim().isNotEmpty;

          setState(() {
            _cachedUserState = state;

            // ✅ IMPORTANT: if user has NO trip -> clear cached trip
            if (!userHasTrip) {
              _cachedTripState = null;
              debugPrint('🧹 Cleared cached trip state (user has no trip)');
            }
          });
        }

        // ✅ cache trip ONLY if current user state says user has trip
        if (state is UserTripLoaded) {
          final effectiveUser =
              (_cachedUserState is UserByIdLoaded)
                  ? (_cachedUserState as UserByIdLoaded).user
                  : null;

          final userHasTrip =
              (effectiveUser?.tripNumberId ?? '').trim().isNotEmpty;

          if (userHasTrip) {
            setState(() => _cachedTripState = state);
          } else {
            // If somehow trip arrives but user says no trip, ignore it.
            debugPrint(
              '⚠️ Ignored UserTripLoaded because user has no tripNumberId',
            );
            setState(() => _cachedTripState = null);
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          debugPrint('🎯 Homepage Body State: $state');

          final effectiveUserState =
              (state is UserByIdLoaded) ? state : _cachedUserState;
          final effectiveTripState =
              (state is UserTripLoaded) ? state : _cachedTripState;

          // ✅ Decide trip presence ONLY based on user.tripNumberId
          // (TripLoaded is not trusted by itself because it can be stale)
          bool hasTrip = false;

          if (effectiveUserState is UserByIdLoaded) {
            final tripNo = (effectiveUserState.user.tripNumberId ?? '').trim();
            hasTrip = tripNo.isNotEmpty;
          }

          // Optional: allow trip state only if user hasTrip already true
          final hasValidTripState =
              hasTrip && (effectiveTripState is UserTripLoaded);

          if (hasValidTripState) {
            debugPrint('✅ Trip found - showing delivery timeline');
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DeliveryTimelineTile(),
                  SizedBox(height: 8),
                  TripSummaryTile(),
                ],
              ),
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
