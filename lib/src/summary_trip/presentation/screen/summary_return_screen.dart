import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_state.dart';

import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/return_screen/widgets/returns_dashboard.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/widget/summary_return_of_customer_list.dart';
class SummaryReturnScreen extends StatefulWidget {
  const SummaryReturnScreen({super.key});

  @override
  State<SummaryReturnScreen> createState() => _SummaryReturnScreenState();
}

class _SummaryReturnScreenState extends State<SummaryReturnScreen>
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  late final ReturnBloc _returnBloc;
  bool _isDataInitialized = false;
  ReturnState? _cachedState;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _returnBloc = context.read<ReturnBloc>();
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
        debugPrint('🎫 Loading returns for trip: ${tripData['id']}');
        _returnBloc.add(LoadLocalReturnsEvent(tripData['id']));
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

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _returnBloc),
        BlocProvider.value(value: _authBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is UserTripLoaded && state.trip.id != null) {
                debugPrint('🎫 User trip loaded: ${state.trip.id}');
                _returnBloc.add(GetReturnsEvent(state.trip.id!));
              }
            },
          ),
          BlocListener<ReturnBloc, ReturnState>(
            listener: (context, state) {
              if (state is ReturnLoaded) {
                setState(() => _cachedState = state);
              }
            },
          ),
        ],
        child: BlocBuilder<ReturnBloc, ReturnState>(
          buildWhen: (previous, current) =>
              current is ReturnLoaded ||
              current is ReturnError ||
              _cachedState == null,
          builder: (context, state) {
            final effectiveState = _cachedState ?? state;

            if (effectiveState is ReturnLoaded && effectiveState.returns.isEmpty) {
              return _buildEmptyState();
            }

            if (effectiveState is ReturnLoaded) {
              return RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ReturnsDashboard(),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            'Returns List',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SummaryReturnOfCustomerList(),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (effectiveState is ReturnError) {
              return _buildErrorState(effectiveState.message);
            }

            return const Center(child: CircularProgressIndicator());
          },
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
            Icons.assignment_return,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Returns Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Returns will appear here once items are processed',
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
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
