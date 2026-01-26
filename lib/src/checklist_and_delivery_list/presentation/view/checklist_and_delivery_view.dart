import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/presentation/bloc/checklist_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/presentation/bloc/checklist_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/refractors/checklist_tile.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/refractors/confirm_button.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/refractors/delivery_list.dart';

import '../../../../core/common/app/features/checklists/intransit_checklist/domain/entity/checklist_entity.dart';
import '../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import '../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import '../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import '../../../../core/utils/route_utils.dart';
class ChecklistAndDeliveryView extends StatefulWidget {
  const ChecklistAndDeliveryView({super.key});

  @override
  State<ChecklistAndDeliveryView> createState() =>
      _ChecklistAndDeliveryViewState();
}

class _ChecklistAndDeliveryViewState extends State<ChecklistAndDeliveryView>
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  late final ChecklistBloc _checklistBloc;
  late final DeliveryDataBloc _deliveryDataBloc;

  List<ChecklistEntity> _lastChecklist = <ChecklistEntity>[];
  final Map<String, bool> _optimisticChecked = <String, bool>{};

  bool _isInitialized = false;
  String? _currentTripId;

  bool _restoredOnce = false;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();

    RouteUtils.saveCurrentRoute('/checklist');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupOnce();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndRestoreRoute();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _checklistBloc = context.read<ChecklistBloc>();
    _deliveryDataBloc = context.read<DeliveryDataBloc>();
  }

  Future<void> _checkAndRestoreRoute() async {
    if (_restoredOnce) return;
    _restoredOnce = true;

    final savedRoute = await RouteUtils.getLastActiveRoute();
    if (savedRoute == '/checklist') {
      debugPrint('📍 Restored to important checklist screen');
      await _refreshAllData();
    }
  }

  void _setupOnce() {
    if (_isInitialized) return;
    _isInitialized = true;

    _loadTripAndFetchData();

    _authBloc.stream.listen((state) {
      if (!mounted) return;

      if (state is UserTripLoaded) {
        final tripId = (state.trip.id ?? '').toString().trim();
        if (tripId.isEmpty) return;

        if (_currentTripId != tripId) {
          _currentTripId = tripId;
          debugPrint('✅ Trip loaded from AuthBloc: $tripId');
          _fetchChecklistAndDelivery(tripId);
        }
      }
    });
  }

  Future<void> _loadTripAndFetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('user_data');

      if (storedData == null || storedData.trim().isEmpty) {
        debugPrint('⚠️ No user_data in SharedPreferences');
        setState(() => _currentTripId = null);
        return;
      }

      final userData = jsonDecode(storedData) as Map<String, dynamic>;
      final tripData = userData['trip'] as Map<String, dynamic>?;

      final tripId = (tripData?['id'] ?? '').toString().trim();
      debugPrint('🎫 Trip ID from prefs: $tripId');

      if (tripId.isEmpty) {
        setState(() => _currentTripId = null);
        return;
      }

      setState(() => _currentTripId = tripId);

      _authBloc.add(GetUserTripEvent(tripId));
      _fetchChecklistAndDelivery(tripId);
    } catch (e) {
      debugPrint('❌ _loadTripAndFetchData error: $e');
      setState(() => _currentTripId = null);
    }
  }

  void _fetchChecklistAndDelivery(String tripId) {
    debugPrint('🔄 Fetch checklist + delivery for tripId=$tripId');
    _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(tripId));
    _checklistBloc.add(LoadChecklistByTripIdEvent(tripId));
  }

  Future<void> _refreshAllData() async {
    final tripId = (_currentTripId ?? '').trim();

    if (tripId.isEmpty) {
      await _loadTripAndFetchData();
      return;
    }

    debugPrint('🔄 MANUAL REFRESH — checklist + delivery (no cache)');
    _fetchChecklistAndDelivery(tripId);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checklist and Delivery List'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAllData,
                child: _buildBody(context),
              ),
            ),
            const Padding(padding: EdgeInsets.all(16), child: ConfirmButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if ((_currentTripId ?? '').trim().isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No trip assigned yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Accept a trip to view deliveries and checklist',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader("Checklist Items"),
        _buildChecklistSection(),
        const SizedBox(height: 24),
        _buildSectionHeader("Delivery List"),
        _buildDeliverySection(context),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // ✅ Checklist section with Icon toggle (X -> Check)
  Widget _buildChecklistSection() {
    return BlocBuilder<ChecklistBloc, ChecklistState>(
      buildWhen: (prev, curr) {
        // keep UI stable during loading once we already have list
        if (curr is ChecklistLoading && _lastChecklist.isNotEmpty) return false;
        return true;
      },
      builder: (context, state) {
        if (state is ChecklistLoaded) {
          _lastChecklist = state.checklist;

          // remove optimistic flags that server already confirms as true
          for (final c in state.checklist) {
            final id = (c.id ?? '').toString().trim();
            if (id.isNotEmpty && (c.isChecked ?? false)) {
              _optimisticChecked.remove(id);
            }
          }
        }

        final items =
            (state is ChecklistLoaded) ? state.checklist : _lastChecklist;

        if (items.isEmpty) {
          if (state is ChecklistLoading) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No checklist items found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = items[index];
            final id = (item.id ?? '').toString().trim();

            final serverChecked = item.isChecked ?? false;
            final checked = id.isEmpty
                ? serverChecked
                : (_optimisticChecked[id] ?? serverChecked);

            return ChecklistTile(
              key: ValueKey('checklist_$id'),
              checklist: item,
              isChecked: checked,
              onToggleToTrue: (_) {
                if (id.isEmpty) return;

                // ✅ optimistic: instantly show ✅
                setState(() {
                  _optimisticChecked[id] = true;
                });

                debugPrint('✅ UI Optimistic check (icon): id=$id -> true');

                // trigger server/local update
                _checklistBloc.add(CheckItemEvent(id));
              },
            );
          },
        );
      },
    );
  }

  // Delivery section stays the same
  Widget _buildDeliverySection(BuildContext context) {
    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      builder: (context, state) {
        if (state is DeliveryDataLoading) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DeliveryDataByTripLoaded) {
          final deliveries = state.deliveryData;

          if (deliveries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No deliveries found for this trip',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }

          final Map<String, dynamic> loadedData = {};
          for (final delivery in deliveries) {
            if (delivery.id != null) loadedData[delivery.id!] = delivery;
          }

          return DeliveryList(
            deliveries: deliveries,
            loadedDeliveryData: loadedData,
            isLoading: false,
          );
        }

        if (state is DeliveryDataError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                state.message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Loading deliveries...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _clearRouteIfCompleted();
    super.dispose();
  }

  Future<void> _clearRouteIfCompleted() async {
    final current = _checklistBloc.state;
    if (current is ChecklistLoaded) {
      final allCompleted =
          current.checklist.every((item) => item.isChecked ?? false);

      if (allCompleted) {
        debugPrint('✅ Checklist completed, clearing saved route');
        await RouteUtils.clearSavedRoute();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}
