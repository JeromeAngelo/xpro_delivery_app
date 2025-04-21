import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/trip_update_dialog.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/update_timeline.dart';
class UpdateTimelineView extends StatefulWidget {
  const UpdateTimelineView({super.key});

  @override
  State<UpdateTimelineView> createState() => _UpdateTimelineViewState();
}

class _UpdateTimelineViewState extends State<UpdateTimelineView> 
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  late final CustomerBloc _customerBloc;
  late final TripUpdatesBloc _tripUpdatesBloc;
  bool _isDataInitialized = false;
  CustomerState? _cachedState;
  TripUpdatesState? _cachedTripState;
  AuthState? _cachedAuthState;
  StreamSubscription? _authSubscription;
  StreamSubscription? _customerSubscription;
  StreamSubscription? _tripUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
    _loadInitialData();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _customerBloc = context.read<CustomerBloc>();
    _tripUpdatesBloc = context.read<TripUpdatesBloc>();
    _cachedAuthState = _authBloc.state;
  }

  void _loadInitialData() {
    if (_authBloc.state is UserTripLoaded) {
      final tripId = (_authBloc.state as UserTripLoaded).trip.id!;
      debugPrint('🔄 Loading initial data for trip: $tripId');
      _customerBloc.add(GetCustomerEvent(tripId));
      _tripUpdatesBloc.add(GetTripUpdatesEvent(tripId));
    }
  }

  void _setupDataListeners() {
    _authSubscription = _authBloc.stream.listen((state) {
      debugPrint('🔐 Auth state update: ${state.runtimeType}');
      if (mounted) {
        setState(() => _cachedAuthState = state);
        if (state is UserTripLoaded && !_isDataInitialized) {
          _loadInitialData();
          _isDataInitialized = true;
        }
      }
    });

    _customerSubscription = _customerBloc.stream.listen((state) {
      debugPrint('👥 Customer state update: ${state.runtimeType}');
      if (mounted && state is CustomerLoaded) {
        setState(() => _cachedState = state);
      }
    });

    _tripUpdateSubscription = _tripUpdatesBloc.stream.listen((state) {
      debugPrint('📝 Trip updates state: ${state.runtimeType}');
      if (mounted && state is TripUpdatesLoaded) {
        setState(() => _cachedTripState = state);
      }
    });
  }

  Future<void> _refreshData() async {
    if (_authBloc.state is UserTripLoaded) {
      final tripId = (_authBloc.state as UserTripLoaded).trip.id!;
      debugPrint('🔄 Refreshing data for trip: $tripId');
      _customerBloc.add(GetCustomerEvent(tripId));
      _tripUpdatesBloc.add(GetTripUpdatesEvent(tripId));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _customerBloc),
        BlocProvider.value(value: _tripUpdatesBloc),
        BlocProvider.value(value: _authBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is UserTripLoaded && state.trip.id != null) {
                debugPrint('🎫 User trip loaded: ${state.trip.id}');
                _customerBloc.add(GetCustomerEvent(state.trip.id!));
                _tripUpdatesBloc.add(GetTripUpdatesEvent(state.trip.id!));
              }
            },
          ),
          BlocListener<CustomerBloc, CustomerState>(
            listener: (context, state) {
              if (state is CustomerLoaded) {
                setState(() => _cachedState = state);
              }
            },
          ),
          BlocListener<TripUpdatesBloc, TripUpdatesState>(
            listener: (context, state) {
              if (state is TripUpdatesLoaded) {
                setState(() => _cachedTripState = state);
              }
            },
          ),
        ],
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final effectiveAuthState = _cachedAuthState;
    
    if (effectiveAuthState is UserTripLoaded) {
      return BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, customerState) {
          final effectiveCustomerState = _cachedState ?? customerState;

          if (effectiveCustomerState is CustomerLoaded) {
            final customers = effectiveCustomerState.customer;
            debugPrint('📊 Processing ${customers.length} customers');
            
            final arrivedCustomers = customers.where((customer) {
              return customer.deliveryStatus.any((status) =>
                status.title?.toLowerCase().trim() == 'arrived');
            }).toList();
            debugPrint('✅ Found ${arrivedCustomers.length} arrived customers');

            if (arrivedCustomers.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: Column(
                children: [
                  Expanded(
                    child: UpdateTimeline(
                      tripUpdates: _cachedTripState is TripUpdatesLoaded
                          ? (_cachedTripState as TripUpdatesLoaded)
                              .updates
                              .cast<TripUpdateEntity>()
                          : [],
                      customers: arrivedCustomers,
                    ),
                  ),
                  _buildAddUpdateButton(effectiveAuthState.trip.id!),
                ],
              ),
            );
          }

          if (effectiveCustomerState is CustomerError) {
            return Center(child: Text(effectiveCustomerState.message));
          }

          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    
    return const Center(child: Text('Loading trip data...'));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Arrived Deliveries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Waiting for deliveries to arrive at their destination',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAddUpdateButton(String tripId) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => TripUpdateBottomSheet(
              tripId: tripId,
              onSaved: () {
                debugPrint('📝 Trip update saved, refreshing updates');
                _tripUpdatesBloc.add(GetTripUpdatesEvent(tripId));
              },
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Update'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🧹 Cleaning up subscriptions');
    _authSubscription?.cancel();
    _customerSubscription?.cancel();
    _tripUpdateSubscription?.cancel();
    _cachedState = null;
    _cachedTripState = null;
    _cachedAuthState = null;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
