import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
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
  bool _isLoading = true;
  bool _hasTriedLocalLoad = false;
  String? _currentTripId;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    
    // Force immediate data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataImmediately();
    });
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _completedCustomerBloc = context.read<CompletedCustomerBloc>();
  }

  // Immediately load data from any available source
  Future<void> _loadDataImmediately() async {
    debugPrint('🚀 Attempting immediate data load');
    
    // First check if we already have data in the bloc
    final currentState = _completedCustomerBloc.state;
    if (currentState is CompletedCustomerLoaded && currentState.customers.isNotEmpty) {
      debugPrint('✅ Using existing data from bloc state');
      setState(() {
        _isLoading = false;
        _isDataInitialized = true;
      });
      return;
    }
    
    // Then try to get trip ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (tripData != null && tripData['id'] != null) {
        _currentTripId = tripData['id'];
        debugPrint('🔍 Found trip ID in SharedPreferences: $_currentTripId');
        
        // Try to load from local storage first for immediate display
        if (!_hasTriedLocalLoad) {
          _hasTriedLocalLoad = true;
          _completedCustomerBloc.add(LoadLocalCompletedCustomerEvent(_currentTripId!));
          
          // Also trigger a remote fetch to ensure data is up-to-date
          _completedCustomerBloc.add(GetCompletedCustomerEvent(_currentTripId!));
        }
      } else {
        debugPrint('⚠️ No trip ID found in SharedPreferences');
        setState(() => _isLoading = false);
      }
    } else {
      debugPrint('⚠️ No user data found in SharedPreferences');
      setState(() => _isLoading = false);
    }
    
    // Also check if we have trip data in the auth bloc
    final authState = _authBloc.state;
    if (authState is UserTripLoaded && authState.trip.id != null) {
      _currentTripId = authState.trip.id;
      debugPrint('🔍 Found trip ID in auth bloc: $_currentTripId');
      
      if (!_hasTriedLocalLoad) {
        _hasTriedLocalLoad = true;
        _completedCustomerBloc.add(LoadLocalCompletedCustomerEvent(_currentTripId!));
        _completedCustomerBloc.add(GetCompletedCustomerEvent(_currentTripId!));
      }
    }
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 Manual refresh triggered');
    setState(() => _isLoading = true);
    
    if (_currentTripId != null) {
      debugPrint('🔄 Refreshing data for trip: $_currentTripId');
      _completedCustomerBloc.add(GetCompletedCustomerEvent(_currentTripId!));
    } else {
      // Try to get trip ID from auth bloc
      final authState = _authBloc.state;
      if (authState is UserTripLoaded && authState.trip.id != null) {
        _currentTripId = authState.trip.id;
        debugPrint('🔍 Found trip ID in auth bloc during refresh: $_currentTripId');
        _completedCustomerBloc.add(GetCompletedCustomerEvent(_currentTripId!));
      } else {
        // Try to get from SharedPreferences
        await _loadDataImmediately();
      }
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
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: BlocConsumer<CompletedCustomerBloc, CompletedCustomerState>(
          listener: (context, state) {
            if (state is CompletedCustomerLoaded) {
              debugPrint('✅ Completed customers loaded: ${state.customers.length} items');
              setState(() => _isLoading = false);
            } else if (state is CompletedCustomerError) {
              debugPrint('❌ Error loading completed customers: ${state.message}');
              setState(() => _isLoading = false);
            }
          },
          builder: (context, state) {
            // Show loading indicator while initial data is being fetched
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // If we have loaded data with empty customers list
            if (state is CompletedCustomerLoaded && state.customers.isEmpty) {
              return _buildEmptyState();
            }

            // If we have loaded data with customers
            if (state is CompletedCustomerLoaded) {
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
                      const CompletedCustomerList(),
                    ],
                  ),
                ),
              );
            }

            // If we have an error
            if (state is CompletedCustomerError) {
              return _buildErrorState(state.message);
            }

            // Default state - show empty state with refresh button
            return _buildEmptyState();
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
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
  bool get wantKeepAlive => true;
}
