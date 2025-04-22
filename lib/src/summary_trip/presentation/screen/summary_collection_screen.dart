import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/widgets/collection_dashboard_screen.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/widget/summary_completed_customer_list.dart';
import '../../../../core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
class SummaryCollectionScreen extends StatefulWidget {
  const SummaryCollectionScreen({super.key});

  @override
  State<SummaryCollectionScreen> createState() => _SummaryCollectionScreenState();
}

class _SummaryCollectionScreenState extends State<SummaryCollectionScreen>
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
    _setupDataRefresh();
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

  void _setupDataRefresh() {
    final completedCustomerBloc = context.read<CompletedCustomerBloc>();
    final authBloc = context.read<AuthBloc>();

    authBloc.stream.listen((state) {
      if (state is UserTripLoaded && state.trip.id != null) {
        completedCustomerBloc.add(GetCompletedCustomerEvent(state.trip.id!));
      }
    });
  }
void _loadInitialData(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final storedData = prefs.getString('user_data');

  if (storedData != null) {
    final userData = jsonDecode(storedData);
    final tripData = userData['trip'] as Map<String, dynamic>?;

    if (tripData != null && tripData['id'] != null) {
      debugPrint('🎫 Loading completed customers for trip: ${tripData['id']}');
      
      // First try to load from local for immediate display
      _completedCustomerBloc.add(LoadLocalCompletedCustomerEvent(tripData['id']));
      
      // Auth data is loaded separately
      _authBloc
        ..add(LoadLocalUserByIdEvent(userId))
        ..add(LoadUserByIdEvent(userId))
        ..add(LoadLocalUserTripEvent(userId))
        ..add(GetUserTripEvent(userId));
    }
  }
}

Future<void> _refreshData() async {
  final authState = context.read<AuthBloc>().state;
  if (authState is UserTripLoaded && authState.trip.id != null) {
    // Force a fresh load from remote
    _completedCustomerBloc.add(GetCompletedCustomerEvent(authState.trip.id!));
  }
}


  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiBlocProvider(
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
                _completedCustomerBloc.add(GetCompletedCustomerEvent(state.trip.id!));
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
        child: RefreshIndicator(
          onRefresh: _refreshData,
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
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
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
                        const SummaryCompletedCustomerList(),
                      ],
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
            onPressed: _refreshData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
