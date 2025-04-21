import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
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
  AuthState? _cachedState;
  bool _isInitialized = false;

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
    SharedPreferences.getInstance().then((prefs) {
      final storedData = prefs.getString('user_data');
      if (storedData != null) {
        final userData = jsonDecode(storedData);
        final userId = userData['id'];
        final tripData = userData['trip'] as Map<String, dynamic>?;

        if (userId != null) {
          debugPrint('🔄 Loading local user data for ID: $userId');
          _authBloc.add(LoadLocalUserByIdEvent(userId));

          if (tripData != null && tripData['id'] != null) {
            debugPrint('🎫 Loading local trip data: ${tripData['id']}');
            _authBloc.add(LoadLocalUserTripEvent(tripData['id']));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        debugPrint('🎯 Homepage Body State: $state');

        if (state is UserByIdLoaded) {
          final user = state.user;
          if (user.tripNumberId != null && user.tripNumberId!.isNotEmpty) {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DeliveryTimelineTile(),
                SizedBox(height: 8),
                TripSummaryTile(),
              ],
            );
          }
        }

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
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
