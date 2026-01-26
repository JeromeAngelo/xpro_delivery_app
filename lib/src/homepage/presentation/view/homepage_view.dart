import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/refractors/homepage_body.dart'
    show HomepageBody;

import '../../../../core/common/app/features/delivery_team/delivery_team/domain/entity/delivery_team_entity.dart';
import '../../../../core/common/app/features/sync_data/cubit/sync_cubit.dart';
import '../../../../core/common/app/features/sync_data/cubit/sync_state.dart';
import '../../../../core/common/app/features/trip_ticket/trip/domain/entity/trip_entity.dart';
import '../../../../core/common/app/features/users/auth/bloc/auth_bloc.dart';
import '../../../../core/common/app/features/users/auth/bloc/auth_event.dart';
import '../../../../core/common/app/features/users/auth/bloc/auth_state.dart';
import '../../../../core/common/app/features/users/auth/domain/entity/users_entity.dart';
import '../../../../core/common/widgets/default_drawer.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/route_utils.dart';
import '../refractors/get_trip_ticket_btn.dart';
import '../refractors/homepage_dashboard.dart';

class HomepageView extends StatefulWidget {
  const HomepageView({super.key});

  @override
  State<HomepageView> createState() => _HomepageViewState();
}

class _HomepageViewState extends State<HomepageView>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //late final DeliveryTeamBloc _deliveryTeamBloc;
  late final AuthBloc _authBloc;
  late final SyncService _syncService;

  LocalUser? _user;
  DeliveryTeamEntity? _deliveryTeam;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _syncService = sl<SyncService>();

    _loadUserData();
    RouteUtils.saveCurrentRoute('/homepage');
  }

  bool get _hasTripAssigned {
    final tripNo = (_user?.tripNumberId ?? '').trim();
    if (tripNo.isNotEmpty) return true;

    // extra safety: if trip relation is actually loaded and has id
    final tripId = (_user?.trip.target?.id ?? '').toString().trim();
    if (tripId.isNotEmpty) return true;

    return false;
  }

  void _initializeBlocs() {
    // _deliveryTeamBloc = sl<DeliveryTeamBloc>();
    _authBloc = BlocProvider.of<AuthBloc>(context);
  }

  // ---------------------------------------------------------------------------
  // LOAD USER DATA FROM SHARED PREFS
  // ---------------------------------------------------------------------------
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      try {
        final data = jsonDecode(storedData);
        final userId = data['id'] as String?;

        if (userId != null && userId.isNotEmpty) {
          _authBloc.add(LoadUserByIdEvent(userId));
          _authBloc.add(GetUserTripEvent(userId));
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing stored user data: $e');
      }
    }

    debugPrint('⚠️ No user ID found in SharedPreferences');
  }

  // ---------------------------------------------------------------------------
  // REFRESH ONLY UI
  // ---------------------------------------------------------------------------
  Future<void> _refreshHomeScreenOnly() async {
    _authBloc.add(RefreshUserEvent());

    if (_user?.id != null) {
      _authBloc.add(GetUserTripEvent(_user!.id ?? ''));
    }

    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _handleFullSync() async {
    final hasTrip = _user?.tripNumberId != null;

    if (!hasTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active trip found to sync'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final syncCubit = context.read<SyncCubit>();

    if (syncCubit.isSyncing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync already in progress...'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // ───────────────────────────────────────────────
    // SHOW SYNC DIALOG WITH PROGRESS TRACKING
    // ───────────────────────────────────────────────
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => BlocBuilder<SyncCubit, SyncState>(
            builder: (_, state) {
              double progress = 0.0;
              String message = 'Starting sync...';

              if (state is SyncLoading) {
                progress = 0.05;
                message = "Preparing sync...";
              } else if (state is SyncingTripData) {
                progress = state.progress;
                message = state.statusMessage;
              } else if (state is SyncingDeliveryData) {
                progress = state.progress;
                message = state.statusMessage;
              } else if (state is SyncingDependentData) {
                progress = state.progress;
                message = state.statusMessage;
              } else if (state is ProcessingPendingOperations) {
                progress = state.completedOperations / state.totalOperations;
                message =
                    "Processing pending data "
                    "${state.completedOperations}/${state.totalOperations}";
              } else if (state is PendingOperationsCompleted) {
                progress = 1.0;
                message = "Finalizing...";
              }

              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Text('$message (${(progress * 100).toInt()}%)'),
                  ],
                ),
              );
            },
          ),
    );

    // ───────────────────────────────────────────────
    // START SYNC
    // ───────────────────────────────────────────────
    syncCubit.startSyncProcess(context).then((_) {
      if (!mounted) return;

      Navigator.pop(context); // close dialog

      final state = syncCubit.state;

      if (state is SyncCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Full sync completed'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshHomeScreenOnly();
      } else if (state is SyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message), backgroundColor: Colors.red),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // PROCESS PENDING OPERATIONS
  // ---------------------------------------------------------------------------
  Future<void> _handlePendingOperations() async {
    final count = _syncService.pendingSyncOperations.length;

    if (count == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No pending operations')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Processing $count pending operations...')),
    );

    try {
      await _syncService.processPendingOperations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pending operations processed'),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshHomeScreenOnly();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiBlocListener(
      listeners: [
        // USER LISTENER
        BlocListener<AuthBloc, AuthState>(
          listener: (_, state) {
            if (state is UserByIdLoaded) {
              setState(() {
                _user = state.user;

                final tripNo = (_user?.tripNumberId ?? '').trim();
                if (tripNo.isEmpty) {
                  // ✅ clear any stale trip relation
                  _user!.trip
                    ..target = null
                    ..targetId = 0;
                }
              });
            }

            if (state is UserTripLoaded) {
              setState(() {
                // ✅ only attach trip if user actually has tripNumberId
                final tripNo = (_user?.tripNumberId ?? '').trim();
                if (tripNo.isNotEmpty) {
                  _user?.trip.target = state.trip as TripModel?;
                }
              });
            }
          },
        ),

        //         // DELIVERY TEAM LISTENER
        //         BlocListener<DeliveryTeamBloc, DeliveryTeamState>(
        //           listener: (_, state) {
        //             if (state is DeliveryTeamLoaded) {
        //               setState(() => _deliveryTeam = state.deliveryTeam);
        //               debugPrint("🏠 BUILD → user = $_user");
        // debugPrint("🏠 BUILD → deliveryTeam = $_deliveryTeam");

        //             }
        //           },
        //         ),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const DefaultDrawer(),
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          onRefresh: _refreshHomeScreenOnly,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    HomepageDashboard(
                      user: _user ?? LocalUser.empty(),
                      trip: _user?.trip.target ?? TripEntity.empty(),
                    ),
                    const SizedBox(height: 12),
                    const HomepageBody(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton:
            !_hasTripAssigned
                ? const Padding(
                  padding: EdgeInsets.only(left: 30.0),
                  child: GetTripTicketBtn(),
                )
                : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------
  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState!.openDrawer(),
      ),
      title: const Text('XPro Delivery'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sync),
          itemBuilder:
              (_) => [
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 12),
                      Text('Refresh Screen'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'sync_all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sync_alt,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 12),
                      Text('Sync All'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'process_pending',
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 12),
                      Text('Process Pending'),
                    ],
                  ),
                ),
              ],
          onSelected: (value) async {
            switch (value) {
              case 'refresh':
                _refreshHomeScreenOnly();
                break;
              case 'sync_all':
                _handleFullSync();
                break;
              case 'process_pending':
                _handlePendingOperations();
                break;
            }
          },
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
