import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_state.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/trip_list_tiles/end_trip_summary_button.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/trip_list_tiles/view_collections.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/trip_list_tiles/view_returns.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/trip_list_tiles/view_undelivered_customers.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/widgets/end_trip_checklist_tiles.dart';

class FinalizeDeliveriesView extends StatefulWidget {
  const FinalizeDeliveriesView({super.key});

  @override
  State<FinalizeDeliveriesView> createState() => _FinalizeDeliveriesViewState();
}

class _FinalizeDeliveriesViewState extends State<FinalizeDeliveriesView> {
  EndTripChecklistState? _cachedState;
  late final AuthBloc _authBloc;
  late final EndTripChecklistBloc _endTripChecklistBloc;
  bool _isInitialized = false;
  StreamSubscription? _authSubscription;
  StreamSubscription? _checklistSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();

    // Delay the initial load to ensure everything is set up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGeneratedChecklist();
    });
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _endTripChecklistBloc = context.read<EndTripChecklistBloc>();
  }

  Future<void> _loadGeneratedChecklist() async {
    debugPrint('🔄 CHECKLIST: Starting checklist load process');

    String? tripId;

    // First, try to get trip ID from AuthBloc state
    final authState = _authBloc.state;
    if (authState is UserTripLoaded && authState.trip.id != null) {
      tripId = authState.trip.id;
      debugPrint('🎫 CHECKLIST: Found trip ID from AuthBloc: $tripId');
    }

    // If not found, try SharedPreferences
    if (tripId == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedData = prefs.getString('user_data');

        if (storedData != null) {
          final userData = jsonDecode(storedData);
          debugPrint(
            '📋 CHECKLIST: User data from SharedPreferences: $userData',
          );

          // Check for trip data in nested structure
          final tripData = userData['trip'] as Map<String, dynamic>?;
          if (tripData != null && tripData['id'] != null) {
            tripId = tripData['id'];
            debugPrint(
              '🎫 CHECKLIST: Found trip ID in nested structure: $tripId',
            );
          } else {
            // Check for tripNumberId in root level
            final tripNumberId = userData['tripNumberId']?.toString();
            if (tripNumberId != null &&
                tripNumberId.isNotEmpty &&
                tripNumberId != 'null') {
              tripId = tripNumberId;
              debugPrint('🎫 CHECKLIST: Found trip number ID: $tripId');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ CHECKLIST: Error reading SharedPreferences: $e');
      }
    }

    if (tripId != null && tripId.isNotEmpty) {
      debugPrint('📝 CHECKLIST: Loading checklist for trip: $tripId');

      // Load local first for immediate display
      _endTripChecklistBloc.add(LoadLocalEndTripChecklistEvent(tripId));

      // Then load from remote to ensure latest data
      _endTripChecklistBloc.add(LoadEndTripChecklistEvent(tripId));
    } else {
      debugPrint('⚠️ CHECKLIST: No trip ID found, cannot load checklist');

      // Try to refresh auth state to get trip data
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('user_data');
      if (storedData != null) {
        final userData = jsonDecode(storedData);
        final userId = userData['id'];
        if (userId != null) {
          debugPrint('🔄 CHECKLIST: Refreshing auth state for user: $userId');
          // This should trigger the auth subscription and load trip data
          // Then we can try again
        }
      }
    }
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      _authSubscription = _authBloc.stream.listen((state) {
        if (!mounted) return;
        debugPrint('🎫 CHECKLIST: Auth state changed: ${state.runtimeType}');

        if (state is UserTripLoaded && state.trip.id != null) {
          debugPrint(
            '🎫 CHECKLIST: Loading checklist for trip from auth: ${state.trip.id}',
          );
          _endTripChecklistBloc
            ..add(LoadLocalEndTripChecklistEvent(state.trip.id!))
            ..add(LoadEndTripChecklistEvent(state.trip.id!));
        }
      });

      _checklistSubscription = _endTripChecklistBloc.stream.listen((state) {
        if (!mounted) return;
        debugPrint('📋 CHECKLIST: State changed: ${state.runtimeType}');

        if (state is EndTripChecklistLoaded) {
          setState(() => _cachedState = state);
          debugPrint(
            '✅ CHECKLIST: Loaded with ${state.checklists.length} items',
          );

          // Log each checklist item for debugging
          for (int i = 0; i < state.checklists.length; i++) {
            final item = state.checklists[i];
            debugPrint(
              '   📝 Item ${i + 1}: ${item.id} (Checked: ${item.isChecked})',
            );
          }
        } else if (state is EndTripChecklistError) {
          debugPrint('❌ CHECKLIST: Error: ${state.message}');
        } else if (state is EndTripChecklistLoading) {
          debugPrint('⏳ CHECKLIST: Loading...');
        }
      });

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EndTripChecklistBloc, EndTripChecklistState>(
          listener: (context, state) {
            if (state is EndTripChecklistLoaded) {
              setState(() => _cachedState = state);
            }
            if (state is EndTripChecklistError) {
              CoreUtils.showSnackBar(context, state.message);
            }
          },
        ),
      ],
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadGeneratedChecklist(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      title: const Text('Trip Summary'),
                      centerTitle: true,
                      floating: true,
                      snap: true,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          context.go('/delivery-and-timeline');
                        },
                      ),
                    ),
                    _buildSectionHeader("Checklist Items"),
                    _buildChecklistSection(),
                    _buildSectionHeader("Summary Details"),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            ViewCollections(),
                            ViewReturns(),
                            ViewUndeliveredCustomers(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_cachedState is EndTripChecklistLoaded)
              Padding(
                padding: const EdgeInsets.all(16),
                child: EndTripSummaryButton(
                  checklists:
                      (_cachedState as EndTripChecklistLoaded).checklists,
                  enabled: (_cachedState as EndTripChecklistLoaded).checklists
                      .every((item) => item.isChecked ?? false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistSection() {
    return BlocBuilder<EndTripChecklistBloc, EndTripChecklistState>(
      buildWhen:
          (previous, current) =>
              current is EndTripChecklistLoaded &&
              (previous is! EndTripChecklistLoaded ||
                  previous.checklists != current.checklists),
      builder: (context, state) {
        debugPrint('🔍 CHECKLIST: Current state: ${state.runtimeType}');

        if (state is EndTripChecklistLoading) {
          debugPrint('⏳ CHECKLIST: Loading state');
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (state is EndTripChecklistLoaded) {
          final checklists = state.checklists;
          debugPrint('✅ CHECKLIST: Loaded ${checklists.length} items');

          if (checklists.isEmpty) {
            debugPrint('⚠️ CHECKLIST: No checklist items found');
            return SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Checklist Please Wait',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadGeneratedChecklist,
                        child: const Text('Reload Checklist'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = checklists[index];
              debugPrint(
                '📋 CHECKLIST: Building item ${index + 1}: ${item.id}',
              );
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: EndTripChecklistTile(
                  key: ValueKey(item.id),
                  checklist: item,
                  isChecked: item.isChecked ?? false,
                  onChanged: (value) {
                    debugPrint(
                      '✅ CHECKLIST: Item ${item.id} toggled to $value',
                    );
                    context.read<EndTripChecklistBloc>().add(
                      CheckEndTripItemEvent(item.id),
                    );
                  },
                ),
              );
            }, childCount: checklists.length),
          );
        }

        if (state is EndTripChecklistError) {
          debugPrint('❌ CHECKLIST: Error state: ${state.message}');
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load checklist',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadGeneratedChecklist,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        debugPrint('⚠️ CHECKLIST: Unknown state, showing loading');
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _checklistSubscription?.cancel();
    _cachedState = null;
    super.dispose();
  }
}
