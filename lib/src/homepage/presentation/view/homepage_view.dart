import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/widgets/default_drawer.dart';
import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/services/sync_service.dart';
import 'package:x_pro_delivery_app/core/utils/route_utils.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
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

  @override
  void initState() {
    super.initState();
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

  void _setupDataListeners() {
    _authSubscription = _authBloc.stream.listen((state) {
      debugPrint('🔐 Auth State Update: ${state.runtimeType}');
      if (state is UserByIdLoaded && !_isDataInitialized) {
        _loadInitialData(state.user.id!);
        _isDataInitialized = true;
      }
      if (mounted) {
        setState(() => _cachedState = state);
      }
    });

    _deliveryTeamSubscription = _deliveryTeamBloc.stream.listen((state) {
      debugPrint('👥 Delivery Team State Update: ${state.runtimeType}');
      if (mounted) {
        setState(() => _cachedDeliveryTeamState = state);
      }
    });
  }

  Future<void> _loadInitialData(String userId) async {
    debugPrint('📱 Loading initial data for user: $userId');
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (tripData != null && tripData['id'] != null) {
        debugPrint('🎫 Loading delivery team for trip: ${tripData['id']}');
        _deliveryTeamBloc
          ..add(LoadLocalDeliveryTeamEvent(tripData['id']))
          ..add(LoadDeliveryTeamEvent(tripData['id']));
      }
    }

    _authBloc
      ..add(LoadLocalUserByIdEvent(userId))
      ..add(LoadUserByIdEvent(userId));
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

    debugPrint('🔄 Refreshing data for user: $userId');

    // Refresh user data
    _authBloc.add(LoadUserByIdEvent(userId));

    // Check if user has a trip
    final tripId = await _getUserTripId();

    if (tripId != null) {
      debugPrint('🎫 Found trip ID: $tripId - refreshing trip data');

      // Refresh trip data
      _authBloc.add(GetUserTripEvent(userId));

      // Refresh delivery team data
      _deliveryTeamBloc.add(LoadDeliveryTeamEvent(tripId));
    } else {
      debugPrint('ℹ️ No trip found for user - skipping trip data refresh');
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

  Future<void> _refreshLocalData() async {
    debugPrint('🔄 Starting local data refresh process');

    // Get the current user ID from AuthBloc instead of UserProvider
    final authState = _authBloc.state;
    String? userId;

    if (authState is UserByIdLoaded) {
      userId = authState.user.id;
    } else if (authState is SignedIn) {
      userId = authState.users.id;
    } else if (authState is UserDataRefreshed) {
      userId = authState.user.id;
    } else {
      // If we don't have the user ID in the current state, try to get it from SharedPreferences
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
      debugPrint(
        '⚠️ Cannot refresh data: No user ID found in AuthBloc or local storage',
      );

      // Dispatch RefreshUserEvent to try to load user data
      // _authBloc.add(const RefreshUserEvent());
      return;
    }

    debugPrint('🔍 Found user ID: $userId - proceeding with refresh');

    // First, refresh the user data to ensure we have the latest user info
    // _authBloc.add(const RefreshUserEvent());

    // Check if the user has a trip by looking at the AuthBloc state
    bool hasTrip = false;
    String? tripId;

    if (authState is UserTripLoaded) {
      hasTrip = authState.trip.id != null && authState.trip.id!.isNotEmpty;
      tripId = authState.trip.id;
      debugPrint(
        '🔍 Trip status from current state: hasTrip=$hasTrip, tripId=$tripId',
      );
    } else {
      // If we don't have trip info in the current state, check in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('user_data');

      if (storedData != null) {
        try {
          final userData = jsonDecode(storedData);
          final tripData = userData['trip'] as Map<String, dynamic>?;

          if (tripData != null &&
              tripData['id'] != null &&
              tripData['id'].toString().isNotEmpty) {
            hasTrip = true;
            tripId = tripData['id'].toString();
            debugPrint(
              '🔍 Trip status from SharedPreferences: hasTrip=$hasTrip, tripId=$tripId',
            );
          } else {
            debugPrint('🔍 No trip found in SharedPreferences');
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing trip data from SharedPreferences: $e');
        }
      }

      // Double-check by loading trip data from the server
      if (!hasTrip) {
        debugPrint('🔍 No trip found locally, checking with server...');

        // Create a completer to wait for the result
        final completer = Completer<bool>();

        // Subscribe to AuthBloc state changes
        late final StreamSubscription subscription;
        subscription = _authBloc.stream.listen((state) {
          if (state is UserTripLoaded) {
            hasTrip = state.trip.id != null && state.trip.id!.isNotEmpty;
            tripId = state.trip.id;
            debugPrint(
              '🔍 Trip status from server: hasTrip=$hasTrip, tripId=$tripId',
            );

            if (!completer.isCompleted) {
              completer.complete(hasTrip);
            }
            subscription.cancel();
          } else if (state is AuthError) {
            debugPrint('⚠️ Error loading trip data: ${state.message}');
            if (!completer.isCompleted) {
              completer.complete(false);
            }
            subscription.cancel();
          }
        });

        // Dispatch event to load trip data
        _authBloc.add(GetUserTripEvent(userId));

        // Wait for the result with a timeout
        try {
          hasTrip = await completer.future.timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('⚠️ Timeout waiting for trip data: $e');
          hasTrip = false;
        }
      }
    }

    debugPrint('🔍 Final trip status: hasTrip=$hasTrip, tripId=$tripId');

    if (hasTrip && tripId != null && tripId!.isNotEmpty) {
      debugPrint('✅ User has an active trip - performing full data sync');

      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 16),
              Text('Syncing data...'),
            ],
          ),
          duration: Duration(
            seconds: 30,
          ), // Long duration as sync might take time
        ),
      );

      // Perform the full data sync
      //  final success = await _syncService.syncAllData(context);

      // Hide the loading indicator
      // ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // // Show success or error message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       success
      //           ? 'Data synchronized successfully'
      //           : 'Failed to synchronize data',
      //     ),
      //     backgroundColor: success ? Colors.green : Colors.red,
      //     duration: const Duration(seconds: 3),
      //   ),
      // );
    } else {
      debugPrint('ℹ️ User does not have an active trip - skipping full sync');

      // Just refresh the user data since there's no trip to sync
      _authBloc.add(LoadLocalUserByIdEvent(userId));
      _authBloc.add(LoadUserByIdEvent(userId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data refreshed (no active trip found)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final connectivity = Provider.of<ConnectivityProvider>(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _deliveryTeamBloc),
        BlocProvider.value(value: _authBloc),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const DefaultDrawer(),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            if (!connectivity.isOnline)
              Container(
                color: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'You\'re in offline mode',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
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
            ),
          ],
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
          icon: const Icon(Icons.refresh),
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder:
              (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text('Refresh Database'),
                    ],
                  ),
                ),
              ],
          onSelected: (String value) async {
            if (value == 'refresh') {
              _refreshLocalData();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.supervised_user_circle),
          onPressed: () => context.push('/delivery-team'),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        debugPrint('🎯 FAB Auth State: $state');

        if (state is UserByIdLoaded) {
          final tripNumberId = state.user.tripNumberId;
          debugPrint('🎫 Trip Number ID: $tripNumberId');

          if (tripNumberId != null && tripNumberId.isNotEmpty) {
            debugPrint('✅ Trip Found - Hiding FAB');
            return const SizedBox.shrink();
          }
        }

        if (state is UserTripLoaded) {
          debugPrint('✅ User Trip Loaded - Hiding FAB');
          return const SizedBox.shrink();
        }

        debugPrint('➕ No Trip - Showing FAB');
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: GetTripTicketBtn(),
        );
      },
    );
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
