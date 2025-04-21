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
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
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

  Future<void> _refreshLocalData() async {
    final userId = context.read<UserProvider>().userId;
    if (userId != null) {
      debugPrint('🔄 Refreshing data for user: $userId');
      _authBloc.add(LoadLocalUserByIdEvent(userId));
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
                onRefresh: _refreshLocalData,
                child: const CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          HomepageDashboard(),
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
              await _syncService.refreshScreen(context);
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
