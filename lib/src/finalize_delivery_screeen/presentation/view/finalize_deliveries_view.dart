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
    _loadGeneratedChecklist();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _endTripChecklistBloc = context.read<EndTripChecklistBloc>();
  }

  void _loadGeneratedChecklist() {
    SharedPreferences.getInstance().then((prefs) {
      final storedData = prefs.getString('user_data');
      if (storedData != null) {
        final userData = jsonDecode(storedData);
        final tripData = userData['trip'] as Map<String, dynamic>?;
        if (tripData != null && tripData['id'] != null) {
          debugPrint('📝 Loading checklist for trip: ${tripData['id']}');
          _endTripChecklistBloc
            ..add(LoadLocalEndTripChecklistEvent(tripData['id']))
            ..add(LoadEndTripChecklistEvent(tripData['id']));
        }
      }
    });
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      _authSubscription = _authBloc.stream.listen((state) {
        if (!mounted) return;
        if (state is UserTripLoaded && state.trip.id != null) {
          _endTripChecklistBloc
            ..add(LoadLocalEndTripChecklistEvent(state.trip.id!))
            ..add(LoadEndTripChecklistEvent(state.trip.id!));
        }
      });

      _checklistSubscription = _endTripChecklistBloc.stream.listen((state) {
        if (!mounted) return;
        if (state is EndTripChecklistLoaded) {
          setState(() => _cachedState = state);
          debugPrint(
              '✅ Checklist loaded with ${state.checklists.length} items');
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
                        onPressed: () => context.go('/delivery-and-timeline'),
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
                  enabled: (_cachedState as EndTripChecklistLoaded)
                      .checklists
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
  }Widget _buildChecklistSection() {
  return BlocBuilder<EndTripChecklistBloc, EndTripChecklistState>(
    buildWhen: (previous, current) => 
      current is EndTripChecklistLoaded && 
      (previous is! EndTripChecklistLoaded || 
       previous.checklists != current.checklists),
    builder: (context, state) {
      if (state is EndTripChecklistLoaded) {
        final checklists = state.checklists;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = checklists[index];
              return KeepAlive(
                keepAlive: true,
                child: EndTripChecklistTile(
                  key: ValueKey(item.id),
                  checklist: item,
                  isChecked: item.isChecked ?? false,
                  onChanged: (value) {
                    context.read<EndTripChecklistBloc>().add(
                      CheckEndTripItemEvent(item.id),
                    );
                  },
                ),
              );
            },
            childCount: checklists.length,
          ),
        );
      }
      return const SliverToBoxAdapter(child: SizedBox.shrink());
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
