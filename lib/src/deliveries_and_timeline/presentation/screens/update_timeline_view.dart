import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/presentation/bloc/trip_updates_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
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
    debugPrint('🔄 TIMELINE: Loading initial data for trip: $tripId');
    debugPrint(
      '📊 TIMELINE: Current cached states - Delivery: ${_cachedDeliveryState?.runtimeType ?? 'null'}, Trip: ${_cachedTripState?.runtimeType ?? 'null'}',
    );

    // Load remote data first, then local as fallback
    _loadRemoteDataWithLocalFallback(tripId);
    _isDataInitialized = true;
  }

  void _loadRemoteDataWithLocalFallback(String tripId) {
    debugPrint('🌐 Attempting to load remote data for trip: $tripId');

  
    // Load delivery data - remote first, then local
    _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(tripId));

   
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
      if (!mounted) return;

      // 📱 OFFLINE-FIRST: Only cache successful states, ignore loading/error states
      if (state is UserTripLoaded ||
          state is UserByIdLoaded ||
          state is UserDataRefreshed) {
        setState(() => _cachedAuthState = state);
        debugPrint('✅ Auth state cached: ${state.runtimeType}');

        if (state is UserTripLoaded) {
          final tripId = state.trip.id!;
          if (!_isDataInitialized) {
            debugPrint('🎯 Auth loaded, initializing data for trip: $tripId');
            _loadRemoteDataWithLocalFallback(tripId);
            _isDataInitialized = true;
          }
        }
      }

      // Don't process loading or error states - keep using cached data
      if (state is AuthLoading || state is AuthError) {
        debugPrint(
          '⚠️ Ignoring ${state.runtimeType} - keeping cached auth data visible',
        );
      }
    });

    _deliveryDataSubscription = _deliveryDataBloc.stream.listen((state) {
      debugPrint('📦 Delivery data state update: ${state.runtimeType}');
      if (!mounted) return;

      // 📱 OFFLINE-FIRST: Only cache successful states
      if (state is DeliveryDataByTripLoaded || state is AllDeliveryDataLoaded) {
        if (state is DeliveryDataByTripLoaded) {
          setState(() => _cachedDeliveryState = state);
          debugPrint(
            '✅ Delivery data cached: ${state.deliveryData.length} items',
          );
        }
        // Don't cache AllDeliveryDataLoaded directly, wait for local processing
      }

      // Handle errors gracefully - keep cached data visible
      if (state is DeliveryDataError) {
        debugPrint(
          '⚠️ Delivery data network error, using cached data: ${state.message}',
        );
        // Only try fallback if we have no cached data
        if (_cachedDeliveryState == null) {
          debugPrint('🔄 No cached data, trying local fallback...');
          final tripId = widget.tripId;
          _deliveryDataBloc.add(GetLocalDeliveryDataByTripIdEvent(tripId));
        }
      }

      // Don't process loading states - keep showing cached data
      if (state is DeliveryDataLoading) {
        debugPrint(
          '⚠️ Ignoring loading state - keeping cached delivery data visible',
        );
      }
    });

    _tripUpdateSubscription = _tripUpdatesBloc.stream.listen((state) {
      debugPrint('📝 Trip updates state: ${state.runtimeType}');
      if (!mounted) return;

      // 📱 OFFLINE-FIRST: Only cache successful states
      if (state is TripUpdatesLoaded) {
        setState(() => _cachedTripState = state);
        debugPrint('✅ Trip updates cached: ${state.updates.length} items');
      }

      // Handle errors gracefully - keep cached data visible
      if (state is TripUpdatesError) {
        debugPrint(
          '⚠️ Trip updates network error, using cached data: ${state.message}',
        );
        // Only try fallback if we have no cached data
        if (_cachedTripState == null) {
          debugPrint('🔄 No cached data, trying local fallback...');
          final tripId = widget.tripId;
          _tripUpdatesBloc.add(LoadLocalTripUpdatesEvent(tripId));
        }
      }

      // Don't process loading states - keep showing cached data
      if (state is TripUpdatesLoading) {
        debugPrint(
          '⚠️ Ignoring loading state - keeping cached trip updates visible',
        );
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
              // 📱 OFFLINE-FIRST: Handle state changes but prioritize cached data in UI
              if (state is DeliveryDataByTripLoaded) {
                setState(() => _cachedDeliveryState = state);
                debugPrint(
                  '📦 Delivery data listener: ${state.deliveryData.length} items cached',
                );
              } else if (state is DeliveryDataError) {
                debugPrint(
                  '⚠️ Delivery data network error, keeping cached data: ${state.message}',
                );
                // Only fallback if we have no cached data at all
                if (_cachedDeliveryState == null) {
                  final tripId = widget.tripId;
                  debugPrint(
                    '🔄 No cached data, falling back to local delivery data',
                  );
                  _deliveryDataBloc.add(
                    GetLocalDeliveryDataByTripIdEvent(tripId),
                  );
                }
              }
            },
          ),
          BlocListener<TripUpdatesBloc, TripUpdatesState>(
            listener: (context, state) {
              // 📱 OFFLINE-FIRST: Handle state changes but prioritize cached data in UI
              if (state is TripUpdatesLoaded) {
                setState(() => _cachedTripState = state);
                debugPrint(
                  '📝 Trip updates listener: ${state.updates.length} items cached',
                );
              } else if (state is TripUpdatesError) {
                debugPrint(
                  '⚠️ Trip updates network error, keeping cached data: ${state.message}',
                );
                // Only fallback if we have no cached data at all
                if (_cachedTripState == null) {
                  final tripId = widget.tripId;
                  debugPrint(
                    '🔄 No cached data, falling back to local trip updates',
                  );
                  _tripUpdatesBloc.add(LoadLocalTripUpdatesEvent(tripId));
                }
              }
            },
          ),
        ],
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final tripId = widget.tripId;

    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      buildWhen:
          (previous, current) =>
              current is DeliveryDataByTripLoaded ||
              current is DeliveryDataError ||
              _cachedDeliveryState == null,
      builder: (context, deliveryDataState) {
        // 📱 OFFLINE-FIRST: Always prioritize cached data, ignore loading states
        DeliveryDataState? effectiveDeliveryState;
        bool showOfflineIndicator = false;

        // Use cached data if available, regardless of current state
        if (_cachedDeliveryState != null) {
          effectiveDeliveryState = _cachedDeliveryState;
          debugPrint(
            '📱 Timeline using cached delivery state: ${_cachedDeliveryState.runtimeType}',
          );

          // Show offline indicator if current state is error (network issue)
          if (deliveryDataState is DeliveryDataError) {
            showOfflineIndicator = true;
            debugPrint('🔴 Network error detected - showing offline indicator');
          }
        }
        // Only use current state if we have no cache
        else {
          effectiveDeliveryState = deliveryDataState;
          debugPrint(
            '📱 Timeline using current delivery state: ${deliveryDataState.runtimeType}',
          );
        }

        // Only show loading if we have no cached data at all
        if (effectiveDeliveryState is DeliveryDataLoading &&
            _cachedDeliveryState == null) {
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

        // Only show error if we have no cached data to fall back to
        if (effectiveDeliveryState is DeliveryDataError &&
            _cachedDeliveryState == null) {
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

          final arrivedDeliveries =
              deliveries.where((delivery) {
                final deliveryUpdates = delivery.deliveryUpdates.toList();
                return deliveryUpdates.any(
                  (status) => status.title?.toLowerCase().trim() == 'arrived',
                );
              }).toList();
          debugPrint('✅ Found ${arrivedDeliveries.length} arrived deliveries');

          if (arrivedDeliveries.isEmpty) {
            return _buildEmptyState(showOfflineIndicator);
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: [
                // 📱 OFFLINE-FIRST: Show offline indicator when using cached data
                if (showOfflineIndicator) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.orange.shade100,
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: Colors.orange.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Showing cached data - network unavailable',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: BlocBuilder<TripUpdatesBloc, TripUpdatesState>(
                    buildWhen:
                        (previous, current) =>
                            current is TripUpdatesLoaded ||
                            current is TripUpdatesError ||
                            _cachedTripState == null,
                    builder: (context, tripUpdatesState) {
                      // 📱 OFFLINE-FIRST: Prioritize cached trip updates
                      TripUpdatesState? effectiveTripState;

                      // Use cached data if available, regardless of current state
                      if (_cachedTripState != null) {
                        effectiveTripState = _cachedTripState;
                        debugPrint(
                          '📱 Timeline using cached trip state: ${_cachedTripState.runtimeType}',
                        );
                      }
                      // Only use current state if we have no cache
                      else {
                        effectiveTripState = tripUpdatesState;
                        debugPrint(
                          '📱 Timeline using current trip state: ${tripUpdatesState.runtimeType}',
                        );
                      }

                      List<TripUpdateEntity> tripUpdates = [];
                      if (effectiveTripState is TripUpdatesLoaded) {
                        tripUpdates =
                            effectiveTripState.updates.cast<TripUpdateEntity>();
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

  Widget _buildEmptyState(bool showOfflineIndicator) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          // 📱 OFFLINE-FIRST: Show offline indicator when using cached data
          if (showOfflineIndicator) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    showOfflineIndicator
                        ? 'Offline mode - No arrived deliveries'
                        : 'Showing cached data - network unavailable',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
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
                      Text(
                        showOfflineIndicator
                            ? 'No Arrived Deliveries (Offline)'
                            : 'No Arrived Deliveries',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        showOfflineIndicator
                            ? 'Cached data shows no arrived deliveries'
                            : 'Waiting for deliveries to arrive at their destination',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
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
          ),
        ],
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
