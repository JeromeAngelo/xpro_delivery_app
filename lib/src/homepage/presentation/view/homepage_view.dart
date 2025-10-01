import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/default_drawer.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/services/sync_service.dart';
import 'package:x_pro_delivery_app/core/utils/route_utils.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/refractors/get_trip_ticket_btn.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/refractors/homepage_body.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/refractors/homepage_dashboard.dart';

class HomepageView extends StatefulWidget {
  const HomepageView({super.key});

  @override
  State<HomepageView> createState() => _HomepageViewState();
}

class _HomepageViewState extends State<HomepageView>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DeliveryTeamBloc _deliveryTeamBloc;
  late final AuthBloc _authBloc;
  late final SyncService _syncService;
  bool _isDataInitialized = false;
  AuthState? _cachedState;
  DeliveryTeamState? _cachedDeliveryTeamState;
  StreamSubscription? _authSubscription;
  StreamSubscription? _deliveryTeamSubscription;
  DateTime? _lastDeliveryTeamLoad;

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo('🏠 Homepage initialized');
    _initializeBlocs();
    _syncService = sl<SyncService>();
    //  _authBloc = context.read<AuthBloc>();
    _setupDataListeners();
    RouteUtils.saveCurrentRoute('/homepage');
  }

  void _initializeBlocs() {
    _deliveryTeamBloc = sl<DeliveryTeamBloc>();
    _authBloc = BlocProvider.of<AuthBloc>(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we're returning to homepage from an important screen
    _checkRouteRestoration();
  }

  Future<void> _checkRouteRestoration() async {
    final savedRoute = await RouteUtils.getLastActiveRoute();
    if (savedRoute == '/homepage') {
      debugPrint('📍 Restored to homepage - refreshing data');
      // Refresh data when restored to homepage
      await _refreshHomeScreenOnly();
    }
  }

  void _setupDataListeners() {
    _authSubscription = _authBloc.stream.listen((state) {
      debugPrint('🔐 Auth State Update: ${state.runtimeType}');
      
      // Only cache successful data states, not loading states
      if (state is UserByIdLoaded || state is UserTripLoaded || state is UserDataRefreshed) {
        if (mounted) {
          setState(() => _cachedState = state);
        }
        
        // Load initial data only once when we first get user data
        if (state is UserByIdLoaded && !_isDataInitialized) {
          _loadInitialData(state.user.id!);
          _isDataInitialized = true;
        }
      }
      
      // Don't cache loading or error states - keep showing cached data
      if (state is AuthLoading || state is AuthError) {
        debugPrint('⚠️ Ignoring ${state.runtimeType} - keeping cached data visible');
      }
    });

    _deliveryTeamSubscription = _deliveryTeamBloc.stream.listen((state) {
      debugPrint('👥 Delivery Team State Update: ${state.runtimeType}');
      
      // Only cache successful states, not loading states
      if (state is DeliveryTeamLoaded && mounted) {
        setState(() => _cachedDeliveryTeamState = state);
      }
      
      // Don't cache loading or error states - keep showing cached data
      if (state is DeliveryTeamLoading || state is DeliveryTeamError) {
        debugPrint('⚠️ Ignoring ${state.runtimeType} - keeping cached delivery team data visible');
      }
    });
  }

  Future<void> _loadInitialData(String userId) async {
    debugPrint('📱 OFFLINE-FIRST: Loading initial data for user: $userId');
    
    // 🔄 Use offline-first AuthBloc methods (they handle local-first, then remote)
    _authBloc.add(LoadUserByIdEvent(userId));
    _authBloc.add(GetUserTripEvent(userId));
    
    // Load delivery team data based on stored trip info
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (tripData != null && tripData['id'] != null) {
        debugPrint('🎫 Loading delivery team for trip: ${tripData['id']}');
        _loadDeliveryTeamWithRateLimit(tripData['id']);
      }
    }
  }

  Future<void> _refreshHomeScreenOnly() async {
    debugPrint('🔄 Refreshing home screen components');

    // Get the current user ID from AuthBloc
    final authState = _authBloc.state;
    String? userId;

    if (authState is UserByIdLoaded) {
      userId = authState.user.id;
    } else if (authState is SignedIn) {
      userId = authState.users.id;
    } else if (authState is UserDataRefreshed) {
      userId = authState.user.id;
    } else {
      // Try to get user ID from SharedPreferences if not in state
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('user_data');

      if (storedData != null) {
        try {
          final userData = jsonDecode(storedData);
          userId = userData['id'];
        } catch (e) {
          debugPrint('⚠️ Error parsing stored user data: $e');
        }
      }
    }

    if (userId == null) {
      debugPrint('⚠️ Cannot refresh: No user ID found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot refresh: User data not available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    debugPrint('🔄 OFFLINE-FIRST: Refreshing data for user: $userId');

    // Use offline-first refresh - this forces remote sync while keeping cached data visible
    _authBloc.add(RefreshUserEvent());
    
    // Check if user has a trip and refresh delivery team data
    final tripId = await _getUserTripId();

    if (tripId != null) {
      debugPrint('🎫 Found trip ID: $tripId - refreshing delivery team data');
      _loadDeliveryTeamWithRateLimit(tripId);
    } else {
      debugPrint('ℹ️ No trip found for user - skipping delivery team refresh');
    }

    // Wait a moment to allow the UI to update
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('✅ Home screen refresh completed');
  }

  // Helper method to get the user's trip ID
  Future<String?> _getUserTripId() async {
    // First check if we have it in the current state
    final authState = _authBloc.state;
    if (authState is UserTripLoaded && authState.trip.id != null) {
      return authState.trip.id;
    }

    if (authState is UserByIdLoaded &&
        authState.user.tripNumberId != null &&
        authState.user.tripNumberId!.isNotEmpty) {
      return authState.user.tripNumberId;
    }

    // If not in state, check SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      try {
        final userData = jsonDecode(storedData);

        // Check for trip data
        if (userData['trip'] != null && userData['trip'] is Map) {
          final tripData = userData['trip'] as Map;
          if (tripData.containsKey('id') && tripData['id'] != null) {
            return tripData['id'].toString();
          }
        }

        // Check for trip number ID
        if (userData['tripNumberId'] != null &&
            userData['tripNumberId'].toString().isNotEmpty) {
          return userData['tripNumberId'].toString();
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing trip data from preferences: $e');
      }
    }

    return null;
  }

  // Rate limiting method to prevent excessive API calls
  void _loadDeliveryTeamWithRateLimit(String tripId) {
    final now = DateTime.now();
    
    // Only load if we haven't loaded in the last 10 seconds
    if (_lastDeliveryTeamLoad == null || 
        now.difference(_lastDeliveryTeamLoad!).inSeconds >= 10) {
      debugPrint('🔄 Loading delivery team with rate limit for trip: $tripId');
      _lastDeliveryTeamLoad = now;
      
      // Load local first, then remote
      _deliveryTeamBloc.add(LoadLocalDeliveryTeamEvent(tripId));
      _deliveryTeamBloc.add(LoadDeliveryTeamEvent(tripId));
    } else {
      final remaining = 10 - now.difference(_lastDeliveryTeamLoad!).inSeconds;
      debugPrint('⏳ Rate limited - skipping delivery team load. Try again in ${remaining}s');
    }
  }

  // Add these methods to the _HomepageViewState class

  Future<void> _handleScreenRefresh() async {
    debugPrint('🔄 Screen refresh initiated from AppBar');

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Refreshing screen...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Use the existing refresh method
      await _refreshHomeScreenOnly();

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Screen refreshed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('❌ Screen refresh failed: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text('Refresh failed: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleFullSync() async {
    debugPrint('🔄 Full sync initiated from AppBar');

    // Check if user has a trip first
    final hasTrip = await _syncService.checkUserHasTrip(context);

    if (!hasTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 16),
              Text('No active trip found to sync'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<double>(
                stream: _syncService.progressStream,
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? 0.0;
                  return Column(
                    children: [
                      CircularProgressIndicator(value: progress),
                      const SizedBox(height: 16),
                      Text('Syncing data... ${(progress * 100).toInt()}%'),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we sync all your data',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    try {
      // Perform full sync
      final success = await _syncService.syncAllData(context);

      // Close progress dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Refresh the screen after successful sync
        await _refreshHomeScreenOnly();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Data synchronized successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 16),
                Text('Sync failed. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close progress dialog if still open
      if (mounted) Navigator.of(context).pop();

      debugPrint('❌ Full sync failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text('Sync error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handlePendingOperations() async {
    debugPrint('🔄 Processing pending operations from AppBar');

    // Check if there are pending operations
    final pendingCount = _syncService.pendingSyncOperations.length;

    if (pendingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 16),
              Text('No pending operations to process'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show processing indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text('Processing $pendingCount pending operations...'),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );

    try {
      // Process pending operations
      await _syncService.processPendingOperations();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Pending operations processed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Refresh screen after processing
      await _refreshHomeScreenOnly();
    } catch (e) {
      debugPrint('❌ Processing pending operations failed: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text('Processing failed: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _deliveryTeamBloc),
        BlocProvider.value(value: _authBloc),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const DefaultDrawer(),
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          onRefresh: _refreshHomeScreenOnly,
          child: const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    HomepageDashboard(),
                    SizedBox(height: 12),
                    HomepageBody(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState!.openDrawer(),
      ),
      title: const Text('XPro Delivery'),
      automaticallyImplyLeading: false,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sync),
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder:
              (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'refresh_screen',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text('Refresh Screen'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'sync_all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sync,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      const Text('Sync All Data'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'process_pending',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Text('Process Pending'),
                    ],
                  ),
                ),
              ],
          onSelected: (String value) async {
            // Save current route before any operation
            await RouteUtils.saveCurrentRoute('/homepage');

            switch (value) {
              case 'refresh_screen':
                AppDebugLogger.instance.logInfo('🔄 User action: Screen refresh requested');
                await _handleScreenRefresh();
                break;
              case 'sync_all':
                AppDebugLogger.instance.logInfo('🔄 User action: Full sync requested');
                await _handleFullSync();
                break;
              case 'process_pending':
                AppDebugLogger.instance.logInfo('🔄 User action: Process pending operations requested');
                await _handlePendingOperations();
                break;
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.supervised_user_circle),
          onPressed: () async {
            await RouteUtils.saveCurrentRoute('/homepage');
            context.push('/delivery-team');
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        debugPrint('🎯 FAB Auth State: ${state.runtimeType}');

        // Check current state first
        bool hasTrip = _checkCurrentStateForTrip(state);
        
        // If current state doesn't show trip, check cached states
        if (!hasTrip) {
          hasTrip = _checkCachedStatesForTrip();
        }

        if (hasTrip) {
          debugPrint('✅ Trip Found - Hiding FAB');
          return const SizedBox.shrink();
        }

        debugPrint('➕ No Trip Found - Showing Get Trip Ticket Button');
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: GetTripTicketBtn(),
        );
      },
    );
  }

  bool _checkCurrentStateForTrip(AuthState state) {
    if (state is UserByIdLoaded) {
      final tripNumberId = state.user.tripNumberId;
      debugPrint('🎫 Current Trip Number ID: $tripNumberId');
      return tripNumberId != null && tripNumberId.isNotEmpty;
    }

    if (state is UserTripLoaded) {
      debugPrint('✅ Current User Trip Loaded - Trip ID: ${state.trip.id}');
      return state.trip.id != null && state.trip.id!.isNotEmpty;
    }

    if (state is UserDataRefreshed) {
      final tripNumberId = state.user.tripNumberId;
      debugPrint('🔄 User Data Refreshed - Trip Number ID: $tripNumberId');
      return tripNumberId != null && tripNumberId.isNotEmpty;
    }

    return false;
  }

  bool _checkCachedStatesForTrip() {
    // Check cached auth state
    if (_cachedState is UserByIdLoaded) {
      final cachedUser = (_cachedState as UserByIdLoaded).user;
      final cachedTripId = cachedUser.tripNumberId;
      debugPrint('🔄 Checking cached Trip Number ID: $cachedTripId');
      if (cachedTripId != null && cachedTripId.isNotEmpty) {
        return true;
      }
    }

    if (_cachedState is UserTripLoaded) {
      final tripId = (_cachedState as UserTripLoaded).trip.id;
      debugPrint('🔄 Checking cached User Trip: $tripId');
      if (tripId != null && tripId.isNotEmpty) {
        return true;
      }
    }

    // Check cached delivery team state
    if (_cachedDeliveryTeamState is DeliveryTeamLoaded) {
      debugPrint('🔄 Cached delivery team state found - indicating active trip');
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    debugPrint('🧹 Cleaning up homepage resources');
    _authSubscription?.cancel();
    _deliveryTeamSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}