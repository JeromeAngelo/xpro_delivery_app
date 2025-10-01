import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/presentation/bloc/user_performance_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/presentation/bloc/user_performance_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/presentation/bloc/user_performance_state.dart';
import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/user_performance/widgets/delivery_accuracy_chart.dart';
import 'package:x_pro_delivery_app/src/user_performance/widgets/performance_summary.dart';

import '../../../core/common/widgets/default_drawer.dart';
import '../widgets/performance_stat_card.dart';

class UserPerformanceScreen extends StatefulWidget {
  const UserPerformanceScreen({super.key});

  @override
  State<UserPerformanceScreen> createState() => _UserPerformanceScreenState();
}

class _UserPerformanceScreenState extends State<UserPerformanceScreen> {
  late final UserPerformanceBloc _userPerformanceBloc;
  late final AuthBloc _authBloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _currentUserId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _loadUserPerformance();
  }

  void _initializeBlocs() {
    _userPerformanceBloc = sl<UserPerformanceBloc>();
    _authBloc = context.read<AuthBloc>();
  }

  Future<void> _loadUserPerformance() async {
    try {
      debugPrint('🔄 Loading user performance data...');

      // Get user ID from auth state or shared preferences
      final userId = await _getUserId();

      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _currentUserId = userId;
          _isInitialized = true;
        });

        debugPrint('👤 Loading performance for user: $userId');

        // Load local data first for faster UI
        _userPerformanceBloc.add(LoadLocalUserPerformanceByUserIdEvent(userId));

        // Then load remote data
        _userPerformanceBloc.add(LoadUserPerformanceByUserIdEvent(userId));
      } else {
        debugPrint('❌ No user ID found');
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user performance: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<String?> _getUserId() async {
    try {
      // First try to get from auth bloc state
      final authState = _authBloc.state;
      if (authState is UserByIdLoaded && authState.user.id!.isNotEmpty) {
        debugPrint('✅ Got user ID from auth state: ${authState.user.id}');
        return authState.user.id;
      }

      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null && userDataString.isNotEmpty) {
        final userData = jsonDecode(userDataString);
        final userId = userData['id']?.toString();

        if (userId != null && userId.isNotEmpty) {
          debugPrint('✅ Got user ID from shared preferences: $userId');
          return userId;
        }
      }

      debugPrint('⚠️ No user ID found in auth state or shared preferences');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  Future<void> _onRefresh() async {
    if (_currentUserId != null) {
      debugPrint('🔄 Refreshing user performance data...');
      _userPerformanceBloc.add(RefreshUserPerformanceEvent(_currentUserId!));

      // Wait a bit for the refresh to complete
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _calculateAccuracy() {
    if (_currentUserId != null) {
      debugPrint('🧮 Calculating delivery accuracy...');
      _userPerformanceBloc.add(CalculateDeliveryAccuracyEvent(_currentUserId!));
    }
  }

  void _syncPerformance() {
    if (_currentUserId != null) {
      debugPrint('🔄 Syncing user performance...');
      _userPerformanceBloc.add(SyncUserPerformanceEvent(_currentUserId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
       drawer: const DefaultDrawer(), 
      appBar: AppBar(
       
        title: const Text(
          'Performance Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: _calculateAccuracy,
            tooltip: 'Calculate Accuracy',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncPerformance,
            tooltip: 'Sync Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _onRefresh();
                  break;
                case 'calculate':
                  _calculateAccuracy();
                  break;
                case 'sync':
                  _syncPerformance();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'calculate',
                    child: Row(
                      children: [
                        Icon(Icons.calculate),
                        SizedBox(width: 8),
                        Text('Calculate Accuracy'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'sync',
                    child: Row(
                      children: [
                        Icon(Icons.sync),
                        SizedBox(width: 8),
                        Text('Sync Data'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : _currentUserId == null
              ? _buildNoUserError()
              : BlocProvider.value(
                value: _userPerformanceBloc,
                child: BlocConsumer<UserPerformanceBloc, UserPerformanceState>(
                  listener: (context, state) {
                    if (state is UserPerformanceError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                          action: SnackBarAction(
                            label: 'Retry',
                            textColor: Colors.white,
                            onPressed: () => _onRefresh(),
                          ),
                        ),
                      );
                    } else if (state is UserPerformanceSynced) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (state is DeliveryAccuracyCalculated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Accuracy calculated: ${state.accuracy.toStringAsFixed(2)}%',
                          ),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: _buildBody(state),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildBody(UserPerformanceState state) {
    if (state is UserPerformanceLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading performance data...'),
          ],
        ),
      );
    }

    if (state is UserPerformanceLoaded) {
      return _buildPerformanceContent(state.userPerformance, state.isFromCache);
    }

    if (state is UserPerformanceSynced) {
      return _buildPerformanceContent(state.userPerformance, false);
    }

    if (state is UserPerformanceOffline) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          if (state.cachedUserPerformance != null)
            Expanded(
              child: _buildPerformanceContent(
                state.cachedUserPerformance!,
                true,
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('No cached data available')),
            ),
        ],
      );
    }

    if (state is UserPerformanceError) {
      return _buildErrorState(state);
    }

    if (state is UserPerformanceEmpty) {
      return _buildEmptyState();
    }

    // Default state (Initial)
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Welcome to Performance Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Pull down to refresh and load your performance data'),
        ],
      ),
    );
  }

  Widget _buildPerformanceContent(dynamic userPerformance, bool isFromCache) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          if (isFromCache)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.withOpacity(0.1),
              child: const Row(
                children: [
                  Icon(Icons.cached, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Showing cached data',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          PerformanceStatsCard(userPerformance: userPerformance),
          DeliveryAccuracyChart(userPerformance: userPerformance),
          PerformanceSummary(userPerformance: userPerformance),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildErrorState(UserPerformanceError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isNetworkError ? Icons.wifi_off : Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              state.isNetworkError ? 'Connection Error' : 'Error',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Performance Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No performance data found for this user',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUserError() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'User Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unable to identify current user. Please log in again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userPerformanceBloc.close();
    super.dispose();
  }
}
