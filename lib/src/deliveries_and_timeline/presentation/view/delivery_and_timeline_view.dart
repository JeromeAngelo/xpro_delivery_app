import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/screens/delivery_list_screen.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/screens/update_timeline_view.dart';

import '../../../../core/common/app/features/trip_ticket/trip_updates/presentation/bloc/trip_updates_event.dart';

class DeliveryAndTimeline extends StatefulWidget {
  const DeliveryAndTimeline({super.key});

  @override
  State<DeliveryAndTimeline> createState() => _DeliveryAndTimelineState();
}

class _DeliveryAndTimelineState extends State<DeliveryAndTimeline>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AuthBloc _authBloc;
  late final DeliveryDataBloc _deliveryDataBloc;
  late final TripUpdatesBloc _tripUpdatesBloc;

  String _tripTitle = 'Loading...';
  String? _tripId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeBlocs();
    _loadTripIdAndData();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _deliveryDataBloc = context.read<DeliveryDataBloc>();
    _tripUpdatesBloc = context.read<TripUpdatesBloc>();
  }

  Future<void> _loadTripIdAndData() async {
    // Try SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      _tripId = userData['trip']?['id'];
      _tripTitle = userData['trip']?['tripNumberId'] ?? 'No Trip Assigned';
    }

    // Fallback: AuthBloc state
    final authState = _authBloc.state;
    if (_tripId == null) {
      if (authState is UserTripLoaded) {
        _tripId = authState.trip.id;
        _tripTitle = authState.trip.tripNumberId ?? 'No Trip Assigned';
      } else if (authState is UserByIdLoaded) {
        _tripId = authState.user.trip.target?.id;
        _tripTitle = authState.user.trip.target?.tripNumberId ?? 'No Trip Assigned';
      }
    }

    setState(() {});

    // Load delivery & timeline data
    if (_tripId != null) _loadDataForTrip(_tripId!);
  }

  void _loadDataForTrip(String tripId) {
    _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(tripId));
    _tripUpdatesBloc.add(GetTripUpdatesEvent(tripId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/homepage'),
        ),
        title: Text(_tripTitle),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onSurface,
          tabs: const [
            Tab(text: 'Deliveries', icon: Icon(Icons.local_shipping)),
            Tab(text: 'Updates', icon: Icon(Icons.update)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (_tripId != null)
            DeliveryListScreen()
          else
            const Center(
              child: Text('No trip assigned'),
            ),
          if (_tripId != null)
            UpdateTimelineView(tripId: _tripId!)
          else
            const Center(
              child: Text('No trip assigned'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
