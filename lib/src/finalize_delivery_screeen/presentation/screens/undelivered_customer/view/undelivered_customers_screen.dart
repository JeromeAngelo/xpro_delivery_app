import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/undelivered_customer/widget/undelivered_customer_dashboard.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/undelivered_customer/widget/undelivered_customer_list_tile.dart';

class UndeliveredCustomersScreen extends StatefulWidget {
  const UndeliveredCustomersScreen({super.key});

  @override
  State<UndeliveredCustomersScreen> createState() =>
      _UndeliveredCustomersScreenState();
}

class _UndeliveredCustomersScreenState extends State<UndeliveredCustomersScreen>
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  late final UndeliverableCustomerBloc _undeliverableCustomerBloc;
  bool _isDataInitialized = false;
  UndeliverableCustomerState? _cachedState;
  StreamSubscription? _authSubscription;
  StreamSubscription? _undeliverableSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _undeliverableCustomerBloc = context.read<UndeliverableCustomerBloc>();
  }

  void _setupDataListeners() {
    _authSubscription = _authBloc.stream.listen((state) {
      debugPrint('🔐 Auth State Update: ${state.runtimeType}');
      if (state is UserTripLoaded && !_isDataInitialized) {
        _loadInitialData(state.trip.id!);
        _isDataInitialized = true;
      }
    });

    _undeliverableSubscription =
        _undeliverableCustomerBloc.stream.listen((state) {
      debugPrint('🚫 Undeliverable State Update: ${state.runtimeType}');
      if (state is UndeliverableCustomerLoaded) {
        setState(() => _cachedState = state);
      }
    });
  }

  Future<void> _loadInitialData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (tripData != null && tripData['id'] != null) {
        debugPrint(
            '🎫 Loading undelivered customer data for trip: ${tripData['id']}');
        _undeliverableCustomerBloc
            .add(LoadLocalUndeliverableCustomersEvent(tripData['id']));
      }
    }

    _authBloc
      ..add(LoadLocalUserByIdEvent(userId))
      ..add(LoadUserByIdEvent(userId))
      ..add(LoadLocalUserTripEvent(userId))
      ..add(GetUserTripEvent(userId));
  }

  Future<void> _refreshData() async {
    final userId = context.read<UserProvider>().userId;
    if (userId != null) {
      _loadInitialData(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go('/finalize-deliveries'),
        ),
        centerTitle: true,
        title: BlocBuilder<TripBloc, TripState>(
          builder: (context, state) {
            if (state is TripLoaded) {
              return Text(
                'Trip #${state.trip.tripNumberId}',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                    ),
              );
            }
            return const Text('Loading Trip...');
          },
        ),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _undeliverableCustomerBloc),
          BlocProvider.value(value: _authBloc),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is UserTripLoaded && state.trip.id != null) {
                  debugPrint(
                      '🎫 Loading undeliverable for trip: ${state.trip.id}');
                  _undeliverableCustomerBloc
                      .add(GetUndeliverableCustomersEvent(state.trip.id!));
                }
              },
            ),
            BlocListener<UndeliverableCustomerBloc, UndeliverableCustomerState>(
              listener: (context, state) {
                if (state is UndeliverableCustomerLoaded) {
                  setState(() => _cachedState = state);
                }
              },
            ),
          ],
          child: BlocBuilder<UndeliverableCustomerBloc,
              UndeliverableCustomerState>(
            buildWhen: (previous, current) =>
                current is UndeliverableCustomerLoaded ||
                current is UndeliverableCustomerError ||
                _cachedState == null,
            builder: (context, state) {
              final effectiveState = _cachedState ?? state;

              if (effectiveState is UndeliverableCustomerLoaded) {
                if (effectiveState.customers.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const UndeliveredCustomerDashboard(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Undelivered List',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const UndeliveredCustomerListTile(),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (effectiveState is UndeliverableCustomerError) {
                return _buildErrorState(effectiveState.message);
              }

              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Undelivered Customers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Undelivered customers will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🧹 Cleaning up undelivered screen resources');
    _authSubscription?.cancel();
    _undeliverableSubscription?.cancel();
    _cachedState = null;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
