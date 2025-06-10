import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_state.dart';
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
  late final CollectionsBloc _collectionsBloc;
  bool _isDataInitialized = false;
  bool _isLoading = true;
  String? _currentTripId;
  List<CollectionEntity> _currentCollections = [];
  bool _isOffline = false;
  CollectionsState? _cachedState;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    
    // Force immediate data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocalData();
    });
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _collectionsBloc = context.read<CollectionsBloc>();
  }

  void _initializeLocalData() {
    if (!_isDataInitialized) {
      debugPrint('📱 Initializing collection data...');
      _loadDataImmediately();
      _isDataInitialized = true;
    }
  }

  // Immediately load data from any available source - matching delivery_main_screen pattern
  Future<void> _loadDataImmediately() async {
    debugPrint('🚀 Attempting immediate data load');
    
    // First check if we already have data in the bloc
    final currentState = _collectionsBloc.state;
    if (currentState is CollectionsLoaded && currentState.collections.isNotEmpty) {
      debugPrint('✅ Using existing data from bloc state');
      _cachedState = currentState;
      setState(() {
        _currentCollections = currentState.collections;
        _isOffline = false;
        _isLoading = false;
        _isDataInitialized = true;
      });
      return;
    }
    
    // Check for offline data
    if (currentState is CollectionsOffline && currentState.collections.isNotEmpty) {
      debugPrint('📱 Using offline data from bloc state');
      _cachedState = currentState;
      setState(() {
        _currentCollections = currentState.collections;
        _isOffline = true;
        _isLoading = false;
        _isDataInitialized = true;
      });
      return;
    }
    
    // Get trip ID from auth bloc first
    final authState = _authBloc.state;
    if (authState is UserTripLoaded && authState.trip.id != null) {
      _currentTripId = authState.trip.id;
      debugPrint('🔍 Found trip ID in auth bloc: $_currentTripId');
      
      if (!_isDataInitialized) {
        _isDataInitialized = true;
        // Then fetch remote data
        _collectionsBloc.add(GetCollectionsByTripIdEvent(_currentTripId!));
        // Load local data first for immediate display
        _collectionsBloc.add(GetLocalCollectionsByTripIdEvent(_currentTripId!));
        
      }
      return;
    }
    
    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (tripData != null && tripData['id'] != null) {
        _currentTripId = tripData['id'];
        debugPrint('🔍 Found trip ID in SharedPreferences: $_currentTripId');
        
        if (!_isDataInitialized) {
          _isDataInitialized = true;
          // Load local data first for immediate display
           _collectionsBloc.add(GetCollectionsByTripIdEvent(_currentTripId!));
        // Load local data first for immediate display
        _collectionsBloc.add(GetLocalCollectionsByTripIdEvent(_currentTripId!));
        }
      } else {
        debugPrint('⚠️ No trip ID found in SharedPreferences');
        setState(() => _isLoading = false);
      }
    } else {
      debugPrint('⚠️ No user data found in SharedPreferences');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 Manual refresh triggered');
    setState(() => _isLoading = true);
    
    if (_currentTripId != null) {
      debugPrint('🔄 Refreshing data for trip: $_currentTripId');
      _collectionsBloc.add(RefreshCollectionsEvent(_currentTripId!));
    } else {
      // Try to get trip ID from auth bloc
      final authState = _authBloc.state;
      if (authState is UserTripLoaded && authState.trip.id != null) {
        _currentTripId = authState.trip.id;
        debugPrint('🔍 Found trip ID in auth bloc during refresh: $_currentTripId');
        _collectionsBloc.add(RefreshCollectionsEvent(_currentTripId!));
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
        child: BlocConsumer<CollectionsBloc, CollectionsState>(
          buildWhen: (previous, current) =>
              current is CollectionsLoaded || 
              current is CollectionsOffline || 
              _cachedState == null,
          listener: (context, state) {
            if (state is CollectionsLoaded) {
              debugPrint('✅ Collections loaded: ${state.collections.length} items');
              _cachedState = state;
              setState(() {
                _currentCollections = state.collections;
                _isOffline = false;
                _isLoading = false;
              });
            } else if (state is CollectionsOffline) {
              debugPrint('📱 Collections loaded offline: ${state.collections.length} items');
              _cachedState = state;
              setState(() {
                _currentCollections = state.collections;
                _isOffline = true;
                _isLoading = false;
              });
            } else if (state is CollectionsError) {
              debugPrint('❌ Error loading collections: ${state.message}');
              setState(() => _isLoading = false);
            } else if (state is CollectionsEmpty) {
              debugPrint('📭 No collections found');
              setState(() {
                _currentCollections = [];
                _isOffline = false;
                _isLoading = false;
              });
            }
          },
          builder: (context, state) {
            // Use cached state if available, similar to delivery_main_screen
           // final collectionsState = _cachedState ?? state;
            
            // Show loading indicator while initial data is being fetched
            if (_isLoading && state is CollectionsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // If we have collections data (either loaded or offline)
            if (_currentCollections.isNotEmpty) {
              return _buildCollectionsView();
            }

            // If we have an error
            if (state is CollectionsError) {
              return _buildErrorState(state.message);
            }

            // Default state - show empty state with refresh button
            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildCollectionsView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collection Dashboard with passed data
            CollectionDashboardScreen(
              collections: _currentCollections,
              isOffline: _isOffline,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text(
                    'Completed Customers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_isOffline) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_bolt, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(color: Colors.orange, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Completed Customer List with passed data
            CompletedCustomerList(
              collections: _currentCollections,
              isOffline: _isOffline,
            ),
          ],
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
            'No collections yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Collections will appear here once deliveries are completed',
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
