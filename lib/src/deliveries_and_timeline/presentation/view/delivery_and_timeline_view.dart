import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_state.dart';
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
  late final CustomerBloc _customerBloc;
  late final TripUpdatesBloc _tripUpdatesBloc;
  bool _isInitialized = false;
  CustomerState? _cachedCustomerState;
  TripUpdatesState? _cachedUpdatesState;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _customerBloc = context.read<CustomerBloc>();
    _tripUpdatesBloc = context.read<TripUpdatesBloc>();
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      _authSubscription = _authBloc.stream.listen((state) {
        if (state is UserTripLoaded && state.trip.id != null) {
          debugPrint('✅ User trip loaded: ${state.trip.id}');
          _loadDataForTrip(state.trip.id!);
        }
      });

      _loadInitialData();
      _isInitialized = true;
    }
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
    _customerBloc.add(LoadLocalCustomersEvent(tripId));
    // ..add(GetCustomerEvent(tripId));

    // Load timeline updates
    _tripUpdatesBloc
      ..add(LoadLocalTripUpdatesEvent(tripId))
      ..add(GetTripUpdatesEvent(tripId));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomerBloc, CustomerState>(
          listener: (context, state) {
            if (state is CustomerLoaded) {
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
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String title = 'Loading...';

          if (state is UserTripLoaded) {
            title = state.trip.tripNumberId ?? 'No Trip Number';
          } else if (state is UserByIdLoaded) {
            title = state.user.tripNumberId ?? 'No Trip Number';
          }

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/homepage'),
              ),
              title: Text(title),
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
