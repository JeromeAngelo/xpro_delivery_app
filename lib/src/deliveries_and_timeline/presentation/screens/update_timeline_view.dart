import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/update_timeline.dart';

class UpdateTimelineView extends StatefulWidget {

  final String tripId; // Add this parameter

  const UpdateTimelineView({
    super.key,
    required this.tripId, // Make it required
  });

  @override
  State<UpdateTimelineView> createState() => _UpdateTimelineViewState();
}

class _UpdateTimelineViewState extends State<UpdateTimelineView>
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  late final DeliveryDataBloc _deliveryDataBloc;
  late final TripUpdatesBloc _tripUpdatesBloc;
  bool _isDataInitialized = false;
  DeliveryDataState? _cachedDeliveryState;
  TripUpdatesState? _cachedTripState;
  AuthState? _cachedAuthState;
  StreamSubscription? _authSubscription;
  StreamSubscription? _deliveryDataSubscription;
  StreamSubscription? _tripUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
    _loadInitialData();

    
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _deliveryDataBloc = context.read<DeliveryDataBloc>();
    _tripUpdatesBloc = context.read<TripUpdatesBloc>();
    _cachedAuthState = _authBloc.state;
  }

   void _loadInitialData() {
    // Use the passed tripId instead of getting it from auth state
    final tripId = widget.tripId;
    debugPrint('🔄 Loading initial data for trip: $tripId');

    // Load remote data first, then local as fallback
    _loadRemoteDataWithLocalFallback(tripId);
    _isDataInitialized = true;
  }

  void _loadRemoteDataWithLocalFallback(String tripId) {
    debugPrint('🌐 Attempting to load remote data for trip: $tripId');

    _deliveryDataBloc.add(GetLocalDeliveryDataByTripIdEvent(tripId));
    // Load delivery data - remote first, then local
    _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(tripId));

    _tripUpdatesBloc.add(LoadLocalTripUpdatesEvent(tripId));
    // Load trip updates - remote first, then local
    _tripUpdatesBloc.add(GetTripUpdatesEvent(tripId));
  }

   Future<void> _refreshData() async {
    final tripId = widget.tripId;
    debugPrint('🔄 Refreshing data for trip: $tripId');

    // Always try remote first on manual refresh
    _loadRemoteDataWithLocalFallback(tripId);
  }

  void _setupDataListeners() {
    _authSubscription = _authBloc.stream.listen((state) {
      debugPrint('🔐 Auth state update: ${state.runtimeType}');
      if (mounted) {
        setState(() => _cachedAuthState = state);

        if (state is UserTripLoaded) {
          final tripId = state.trip.id!;
          if (!_isDataInitialized) {
            debugPrint('🎯 Auth loaded, initializing data for trip: $tripId');
            _loadRemoteDataWithLocalFallback(tripId);
            _isDataInitialized = true;
          }
        }
      }
    });

    _deliveryDataSubscription = _deliveryDataBloc.stream.listen((state) {
      debugPrint('📦 Delivery data state update: ${state.runtimeType}');
      if (mounted) {
        if (state is DeliveryDataByTripLoaded) {
          setState(() => _cachedDeliveryState = state);
          debugPrint(
            '✅ Delivery data cached: ${state.deliveryData.length} items',
          );
        } else if (state is DeliveryDataError) {
          debugPrint('❌ Remote delivery data failed, trying local...');
          // Try local data as fallback
          if (_authBloc.state is UserTripLoaded) {
            final tripId = (_authBloc.state as UserTripLoaded).trip.id!;
            _deliveryDataBloc.add(GetLocalDeliveryDataByTripIdEvent(tripId));
          }
        }
      }
    });

    _tripUpdateSubscription = _tripUpdatesBloc.stream.listen((state) {
      debugPrint('📝 Trip updates state: ${state.runtimeType}');
      if (mounted) {
        if (state is TripUpdatesLoaded) {
          setState(() => _cachedTripState = state);
          debugPrint('✅ Trip updates cached: ${state.updates.length} items');
        } else if (state is TripUpdatesError) {
          debugPrint('❌ Remote trip updates failed, trying local...');
          // Try local data as fallback
          if (_authBloc.state is UserTripLoaded) {
            final tripId = (_authBloc.state as UserTripLoaded).trip.id!;
            _tripUpdatesBloc.add(LoadLocalTripUpdatesEvent(tripId));
          }
        }
      }
    });
  }



 @override
Widget build(BuildContext context) {
  super.build(context);

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _deliveryDataBloc),
      BlocProvider.value(value: _tripUpdatesBloc),
      BlocProvider.value(value: _authBloc),
    ],
    child: MultiBlocListener(
      listeners: [
        BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            if (state is DeliveryDataByTripLoaded) {
              setState(() => _cachedDeliveryState = state);
            } else if (state is DeliveryDataError) {
              debugPrint('⚠️ Delivery data error: ${state.message}');
              // Auto-fallback to local data
              final tripId = widget.tripId;
              debugPrint('🔄 Falling back to local delivery data');
              _deliveryDataBloc.add(GetLocalDeliveryDataByTripIdEvent(tripId));
            }
          },
        ),
        BlocListener<TripUpdatesBloc, TripUpdatesState>(
          listener: (context, state) {
            if (state is TripUpdatesLoaded) {
              setState(() => _cachedTripState = state);
            } else if (state is TripUpdatesError) {
              debugPrint('⚠️ Trip updates error: ${state.message}');
              // Auto-fallback to local data
              final tripId = widget.tripId;
              debugPrint('🔄 Falling back to local trip updates');
              _tripUpdatesBloc.add(LoadLocalTripUpdatesEvent(tripId));
            }
          },
        ),
      ],
      child: _buildContent(),
    ),
  );
}


  Widget _buildContent() {
  // Remove the auth state dependency since we have tripId directly
  final tripId = widget.tripId;

  return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
    buildWhen: (previous, current) =>
        current is DeliveryDataByTripLoaded ||
        current is DeliveryDataError ||
        _cachedDeliveryState == null,
    builder: (context, deliveryDataState) {
      final effectiveDeliveryState = _cachedDeliveryState ?? deliveryDataState;

      if (effectiveDeliveryState is DeliveryDataLoading) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading delivery data...'),
            ],
          ),
        );
      }

      if (effectiveDeliveryState is DeliveryDataError) {
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
                'Error loading delivery data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                effectiveDeliveryState.message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (effectiveDeliveryState is DeliveryDataByTripLoaded) {
        final deliveries = effectiveDeliveryState.deliveryData;
        debugPrint('📊 Processing ${deliveries.length} deliveries');

        final arrivedDeliveries = deliveries.where((delivery) {
          final deliveryUpdates = delivery.deliveryUpdates.toList();
          return deliveryUpdates.any(
            (status) => status.title?.toLowerCase().trim() == 'arrived',
          );
        }).toList();
        debugPrint('✅ Found ${arrivedDeliveries.length} arrived deliveries');

        if (arrivedDeliveries.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<TripUpdatesBloc, TripUpdatesState>(
                  buildWhen: (previous, current) =>
                      current is TripUpdatesLoaded ||
                      current is TripUpdatesError ||
                      _cachedTripState == null,
                  builder: (context, tripUpdatesState) {
                    final effectiveTripState = _cachedTripState ?? tripUpdatesState;

                    List<TripUpdateEntity> tripUpdates = [];
                    if (effectiveTripState is TripUpdatesLoaded) {
                      tripUpdates = effectiveTripState.updates.cast<TripUpdateEntity>();
                    }

                    return UpdateTimeline(
                      tripUpdates: tripUpdates,
                      deliveries: arrivedDeliveries,
                    );
                  },
                ),
              ),
              _buildAddUpdateButton(tripId), // Pass the tripId here
            ],
          ),
        );
      }

      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    },
  );
}


  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Arrived Deliveries',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for deliveries to arrive at their destination',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
// Replace the _buildAddUpdateButton method with this:
Widget _buildAddUpdateButton(String tripId) {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: ElevatedButton.icon(
      onPressed: () {
        debugPrint('🚀 Navigating to add trip update screen');
        context.pushNamed(
          'add-trip-update',
          pathParameters: {'tripId': tripId},
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Update'),
       style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
  );
}
  @override
  void dispose() {
    debugPrint('🧹 Disposing UpdateTimelineView');
    _authSubscription?.cancel();
    _deliveryDataSubscription?.cancel();
    _tripUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
