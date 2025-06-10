import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/screens/delivery_list_screen.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/screens/update_timeline_view.dart';

class DeliveryAndTimeline extends StatefulWidget {
  const DeliveryAndTimeline({super.key});

  @override
  State<DeliveryAndTimeline> createState() => _DeliveryAndTimelineState();
}

class _DeliveryAndTimelineState extends State<DeliveryAndTimeline>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AuthBloc _authBloc;
  late final DeliveryDataBloc _customerBloc;
  late final TripUpdatesBloc _tripUpdatesBloc;
  bool _isInitialized = false;
  DeliveryDataState? _cachedCustomerState;
  TripUpdatesState? _cachedUpdatesState;
  StreamSubscription? _authSubscription;
  String _tripTitle = 'Loading...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _customerBloc = context.read<DeliveryDataBloc>();
    _tripUpdatesBloc = context.read<TripUpdatesBloc>();
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      _authSubscription = _authBloc.stream.listen((state) {
        if (state is UserTripLoaded && state.trip.id != null) {
          debugPrint('✅ User trip loaded: ${state.trip.id}');
          _updateTripTitle(state.trip.tripNumberId);
          _loadDataForTrip(state.trip.id!);
        } else if (state is UserByIdLoaded) {
          // Check if user has trip relation
          final user = state.user;
          if (user.trip.target != null) {
            final trip = user.trip.target!;
            debugPrint('✅ User with trip loaded: ${trip.id}');
            _updateTripTitle(trip.tripNumberId);
            _loadDataForTrip(trip.id ?? '');
          } else {
            debugPrint('⚠️ User loaded but no trip assigned');
            _updateTripTitle(null);
          }
        }
      });

      _loadInitialData();
      _isInitialized = true;
    }
  }

  void _updateTripTitle(String? tripNumberId) {
    setState(() {
      _tripTitle = tripNumberId ?? 'No Trip Assigned';
    });
    debugPrint('🏷️ Trip title updated: $_tripTitle');
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final userId = userData['id'];

      if (userId != null) {
        debugPrint('🔄 Loading user trip data for ID: $userId');
        _authBloc
          ..add(LoadLocalUserTripEvent(userId))
          ..add(GetUserTripEvent(userId));
      }
    }
  }

  void _loadDataForTrip(String tripId) {
    debugPrint('📱 Loading data for trip: $tripId');

    // Load customer data
    _customerBloc.add(GetLocalDeliveryDataByTripIdEvent(tripId));

    // Load timeline updates
    _tripUpdatesBloc
      ..add(LoadLocalTripUpdatesEvent(tripId))
      ..add(GetTripUpdatesEvent(tripId));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            if (state is AllDeliveryDataLoaded) {
              setState(() => _cachedCustomerState = state);
            }
          },
        ),
        BlocListener<TripUpdatesBloc, TripUpdatesState>(
          listener: (context, state) {
            if (state is TripUpdatesLoaded) {
              setState(() => _cachedUpdatesState = state);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is UserTripLoaded) {
              final trip = state.trip;
              _updateTripTitle(trip.tripNumberId);
            } else if (state is UserByIdLoaded) {
              final user = state.user;
              final tripNumberId = user.trip.target?.tripNumberId;
              _updateTripTitle(tripNumberId);
            }
          },
        ),
      ],
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, state) {
          debugPrint('🎯 Building DeliveryAndTimeline with state: $state');
          debugPrint('🏷️ Current trip title: $_tripTitle');

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/homepage'),
              ),
              title: Text(_tripTitle),
              centerTitle: true,
              bottom: TabBar(
                labelColor: Theme.of(context).colorScheme.surface,
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Deliveries', icon: Icon(Icons.local_shipping)),
                  Tab(text: 'Updates', icon: Icon(Icons.update)),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: const [DeliveryListScreen(), UpdateTimelineView()],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}
