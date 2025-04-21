import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';

import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/widgets/collection_dashboard_screen.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/widgets/completed_customer_list.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  late final CompletedCustomerBloc _completedCustomerBloc;
  bool _isDataInitialized = false;
  CompletedCustomerState? _cachedState;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _completedCustomerBloc = context.read<CompletedCustomerBloc>();
  }

  void _setupDataListeners() {
    _authSubscription = _authBloc.stream.listen((state) {
      if (state is UserByIdLoaded && !_isDataInitialized) {
        _loadInitialData(state.user.id!);
        _isDataInitialized = true;
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
            '🎫 Loading completed customers for trip: ${tripData['id']}');
        _completedCustomerBloc
          ..add(LoadLocalCompletedCustomerEvent(tripData['id']))
          ..add(GetCompletedCustomerEvent(tripData['id']));
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
        centerTitle: true,
        leading: BackButton(
          onPressed: () => context.go('/finalize-deliveries'),
        ),
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is UserTripLoaded) {
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
          BlocProvider.value(value: _completedCustomerBloc),
          BlocProvider.value(value: _authBloc),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is UserTripLoaded && state.trip.id != null) {
                  debugPrint('🎫 User trip loaded: ${state.trip.id}');
                  _completedCustomerBloc
                      .add(GetCompletedCustomerEvent(state.trip.id!));
                }
              },
            ),
            BlocListener<CompletedCustomerBloc, CompletedCustomerState>(
              listener: (context, state) {
                if (state is CompletedCustomerLoaded) {
                  setState(() => _cachedState = state);
                }
              },
            ),
          ],
          child: BlocBuilder<CompletedCustomerBloc, CompletedCustomerState>(
            buildWhen: (previous, current) =>
                current is CompletedCustomerLoaded ||
                current is CompletedCustomerError ||
                _cachedState == null,
            builder: (context, state) {
              final effectiveState = _cachedState ?? state;

              if (effectiveState is CompletedCustomerLoaded &&
                  effectiveState.customers.isEmpty) {
                return _buildEmptyState();
              }

              if (effectiveState is CompletedCustomerLoaded) {
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
                          const CollectionDashboardScreen(),
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                              'Completed Customers',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const CompletedCustomerList(),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (effectiveState is CompletedCustomerError) {
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
            Icons.assignment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No completed customers yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customers will appear here once deliveries are completed',
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
            onPressed: () => _refreshData(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cachedState = null;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
