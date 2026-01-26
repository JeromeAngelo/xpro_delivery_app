import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/delivery_list_tile.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/end_trip_btn.dart';

import '../widgets/quick_action_button.dart';
import '../widgets/quick_update_dialog.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final AuthBloc _authBloc;
  late final DeliveryDataBloc _deliveryDataBloc;
  late final DeliveryUpdateBloc _deliveryUpdateBloc;
  bool _isInitialized = false;
  bool _isDataInitialized = false;
  bool _isLoading = true;
  String? _currentTripId;
  List<DeliveryDataEntity> _currentDeliveries = [];
  StreamSubscription? _authSubscription;
  StreamSubscription? _deliveryDataSubscription;
  StreamSubscription? _deliverySubscription;
EndDeliveryStatusChecked? _endDeliveryStatus;

  Set<String> selectedDeliveries = {};
  bool selectionMode = false;

  void _enableSelectionMode() => setState(() => selectionMode = true);
  void _disableSelectionMode() => setState(() => selectionMode = false);

  void _toggleSelection(String id, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedDeliveries.add(id);
      } else {
        selectedDeliveries.remove(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Try to get trip ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (tripData != null && tripData['id'] != null) {
        _currentTripId = tripData['id'];
        _loadDeliveryDataForTrip(_currentTripId!);
        return;
      }
    }

    // Fallback: check auth bloc
    final authState = _authBloc.state;
    if (authState is UserTripLoaded && authState.trip.id != null) {
      _currentTripId = authState.trip.id;
      _loadDeliveryDataForTrip(_currentTripId!);
      return;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _refreshData() async {
    if (_currentTripId != null) {
      _loadDeliveryDataForTrip(_currentTripId!);
    } else {
      await _loadData();
    }
  }

  void _setupDataListeners() {
    if (_isInitialized) return;

    _authSubscription = _authBloc.stream.listen((state) {
      if (!mounted) return;
      if (state is UserTripLoaded && state.trip.id != null) {
        if (!_isDataInitialized || _currentTripId != state.trip.id) {
          _currentTripId = state.trip.id;
          _loadDeliveryDataForTrip(state.trip.id!);
        }
      }
    });

    _deliveryDataSubscription = _deliveryDataBloc.stream.listen((state) {
      if (!mounted) return;

      if (state is DeliveryDataByTripLoaded) {
        setState(() {
          _currentDeliveries = state.deliveryData;
          _isLoading = false;
          _isDataInitialized = true;
        });
      }

      

      if (state is DeliveryDataError) {
        setState(() => _isLoading = false);
      }
    });

    _deliverySubscription = _deliveryUpdateBloc.stream.listen((state) {
      if (!mounted) return;
      // Keep delivery update handling if needed
    });

    _isInitialized = true;
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _deliveryDataBloc = context.read<DeliveryDataBloc>();
    _deliveryUpdateBloc = context.read<DeliveryUpdateBloc>();
  }

  void _loadDeliveryDataForTrip(String tripId) {
    _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(tripId));
    _deliveryUpdateBloc.add(CheckEndDeliveryStatusEvent(tripId));
        _deliveryDataBloc.add(WatchAllDeliveryDataEvent());

  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            if (state is DeliveryDataByTripLoaded) {
              setState(() {
                _currentDeliveries = state.deliveryData;
                _isLoading = false;
                _isDataInitialized = true;
              });
            }
          },
        ),
       BlocListener<DeliveryUpdateBloc, DeliveryUpdateState>(
  listener: (context, state) {
    if (state is EndDeliveryStatusChecked) {
      setState(() {
        _endDeliveryStatus = state; // store latest, not cached
      });
    }
  },
),

      ],
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();

    if (_currentDeliveries.isEmpty) return _buildEmptyDeliveryState();

    return _buildDeliveryList();
  }

 Widget _buildDeliveryList() {
  // Default values
  bool isEndTripButtonEnabled = false;
  String endTripButtonTooltip = 'Complete all deliveries to end trip';

  if (_endDeliveryStatus != null) {
    final stats = _endDeliveryStatus!.stats;

    final total = stats['total'] as int? ?? 0;
    final completed = stats['completed'] as int? ?? 0;
    final pending = stats['pending'] as int? ?? 0;

    debugPrint('📊 Delivery Status: total=$total, completed=$completed, pending=$pending');

    isEndTripButtonEnabled = total > 0 && pending == 0;

    if (total == 0) {
      endTripButtonTooltip = 'No deliveries assigned to this trip';
    } else if (pending > 0) {
      endTripButtonTooltip =
          '$pending deliveries still pending. Complete all to end trip.';
    } else {
      endTripButtonTooltip = 'All deliveries completed. Ready to end trip.';
    }

    debugPrint('🔘 End Trip Button enabled: $isEndTripButtonEnabled');
    debugPrint('💬 Tooltip: $endTripButtonTooltip');
  }

  return Column(
    children: [
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _currentDeliveries.length,
          itemBuilder: (context, index) {
            final delivery = _currentDeliveries[index];
            return DeliveryListTile(
              delivery: delivery,
              selectionMode: selectionMode,
              isSelected: selectedDeliveries.contains(delivery.id),
              onSelectionChanged: (selected) {
                if (delivery.id != null) {
                  _toggleSelection(delivery.id!, selected);
                }
              },
              onLongPress: _enableSelectionMode,
              onTap: () {
                if (delivery.id != null) {
                  context.go(
                    '/delivery-and-invoice/${delivery.id}',
                    extra: delivery,
                  );
                }
              },
            );
          },
        ),
      ),

      // Switch buttons depending on mode
      selectionMode
          ? QuickActionButton(
              bulkEnabled: selectedDeliveries.isNotEmpty,
              onBulkUpdate: () async {
                final result = await showDialog(
                  context: context,
                  builder: (_) => QuickUpdateDialog(
                    selectedDeliveryIds: selectedDeliveries.toList(),
                  ),
                );
                if (result == true) {
                  _disableSelectionMode();
                }
              },
              onCancel: _disableSelectionMode,
            )
          : EndTripButton(
              isEnabled: isEndTripButtonEnabled,
              tooltip: endTripButtonTooltip,
            ),
    ],
  );
}


  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyDeliveryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 16),
          Text('No deliveries available', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _currentTripId != null) {
      _deliveryUpdateBloc.add(CheckEndDeliveryStatusEvent(_currentTripId!));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _deliveryDataSubscription?.cancel();
    _deliverySubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

