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
import 'package:x_pro_delivery_app/src/deliveries_routes_and_timeline/presentation/screens/delivery_list_screen.dart';
import 'package:x_pro_delivery_app/src/deliveries_routes_and_timeline/presentation/screens/route_view_screen.dart';
import 'package:x_pro_delivery_app/src/deliveries_routes_and_timeline/presentation/screens/update_timeline_view.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
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
        _tripTitle =
            authState.user.trip.target?.tripNumberId ?? 'No Trip Assigned';
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

  Widget _buildTabItem(String label, int index, IconData icon) {
    final isSelected = _tabController.index == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isSelected
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.go('/homepage'),
        ),
        title: Text(
          _tripTitle,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  _buildTabItem('Deliveries', 0, Icons.local_shipping),
                  _buildTabItem('Updates', 1, Icons.update),
                  _buildTabItem('Routes', 2, Icons.route),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (_tripId != null)
            DeliveryListScreen()
          else
            const Center(child: Text('No trip assigned')),
          if (_tripId != null)
            UpdateTimelineView(tripId: _tripId!)
          else
            const Center(child: Text('No trip assigned')),
          if (_tripId != null)
            RouteViewScreen()
          else
            const Center(child: Text('No trip assigned')),
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
