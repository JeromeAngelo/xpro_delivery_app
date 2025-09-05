import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/delivery_list_tile.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/end_trip_btn.dart';

import '../../../../core/common/widgets/loading_tile.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/quick_update_dialog.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  DeliveryDataState? _cachedState;
  DeliveryUpdateState? _cachedDeliveryState;
  late final AuthBloc _authBloc;
  late final DeliveryDataBloc _deliveryDataBloc;
  late final DeliveryUpdateBloc _deliveryUpdateBloc;
  bool _isInitialized = false;
  bool _isDataInitialized = false; // ADDED
  bool _isLoading = true; // ADDED
  bool _hasTriedLocalLoad = false; // ADDED
  String? _currentTripId;
  List<DeliveryDataEntity> _currentDeliveries = []; // ADDED
  bool _isOffline = false; // ADDED
  StreamSubscription? _authSubscription;
  StreamSubscription? _deliveryDataSubscription;
  StreamSubscription? _deliverySubscription;
 Set<String> selectedDeliveries = {}; // Track selected deliveries
   bool selectionMode = false;

  void _enableSelectionMode() {
    setState(() {
      selectionMode = true;
    });
  }

  void _disableSelectionMode() {
    setState(() {
      selectionMode = false;
    });
  }

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

    // Add app lifecycle observer to detect when screen becomes visible
    WidgetsBinding.instance.addObserver(this);

    // 📱 OFFLINE-FIRST: Load cached data immediately to avoid empty state flash
    _loadCachedDataSynchronously();

    // Then load fresh data asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataImmediately();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // This is called when the route becomes active
    // Refresh end delivery status to ensure button state is current
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('📱 ROUTE: Dependencies changed, refreshing end delivery status');
        _refreshEndDeliveryStatus();
      }
    });
  }

  // 📱 OFFLINE-FIRST: Load cached data synchronously to prevent empty state flash
  void _loadCachedDataSynchronously() {
    debugPrint('⚡ DELIVERY: Loading cached data synchronously');

    // First check if bloc already has data
    final currentState = _deliveryDataBloc.state;
    if (currentState is DeliveryDataByTripLoaded &&
        currentState.deliveryData.isNotEmpty) {
      debugPrint(
        '✅ DELIVERY: Found existing data in bloc state: ${currentState.deliveryData.length} items',
      );
      setState(() {
        _currentDeliveries = currentState.deliveryData;
        _cachedState = currentState;
        _isOffline = false;
        _isLoading = false;
        _isDataInitialized = true;
        _currentTripId = currentState.tripId;
      });
      return;
    }

    // If bloc has cached state, use it immediately
    if (_cachedState is DeliveryDataByTripLoaded) {
      final cachedData =
          (_cachedState as DeliveryDataByTripLoaded).deliveryData;
      debugPrint(
        '✅ DELIVERY: Using existing cached state: ${cachedData.length} items',
      );
      setState(() {
        _currentDeliveries = cachedData;
        _isOffline = false;
        _isLoading = false;
        _isDataInitialized = true;
      });
      return;
    }

    debugPrint('📭 DELIVERY: No immediate cached data available');
  }

  // ADDED: Immediately load data from any available source
  Future<void> _loadDataImmediately() async {
    debugPrint('🚀 DELIVERY: Attempting immediate data load');
    debugPrint('📊 Current state: ${_deliveryDataBloc.state.runtimeType}');
    debugPrint('📊 Cached state: ${_cachedState?.runtimeType ?? 'null'}');
    debugPrint('📊 Current deliveries count: ${_currentDeliveries.length}');

    // First check if we already have data in the bloc
    final currentState = _deliveryDataBloc.state;
    if (currentState is DeliveryDataByTripLoaded &&
        currentState.deliveryData.isNotEmpty) {
      debugPrint('✅ DELIVERY: Using existing data from bloc state');
      setState(() {
        _currentDeliveries = currentState.deliveryData;
        _isOffline = false;
        _isLoading = false;
        _isDataInitialized = true;
        _cachedState = currentState;
      });
      return;
    }

    // Check for offline data
    if (currentState is DeliveryDataError && _cachedState != null) {
      debugPrint('📱 DELIVERY: Using cached data from previous state');
      setState(() {
        _currentDeliveries =
            (_cachedState as DeliveryDataByTripLoaded).deliveryData;
        _isOffline = true;
        _isLoading = false;
        _isDataInitialized = true;
      });
      return;
    }

    // Then try to get trip ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (tripData != null && tripData['id'] != null) {
        _currentTripId = tripData['id'];
        debugPrint(
          '🔍 DELIVERY: Found trip ID in SharedPreferences: $_currentTripId',
        );

        // Try to load from local storage first for immediate display
        if (!_hasTriedLocalLoad) {
          _hasTriedLocalLoad = true;
          // Load local data first for immediate display
          _deliveryDataBloc.add(
            GetLocalDeliveryDataByTripIdEvent(_currentTripId!),
          );
          if (mounted) {
            context.read<DeliveryUpdateBloc>().add(CheckEndDeliveryStatusEvent(_currentTripId!));
          }
          _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(_currentTripId!));
        }
      } else {
        debugPrint('⚠️ DELIVERY: No trip ID found in SharedPreferences');
        setState(() => _isLoading = false);
      }
    } else {
      debugPrint('⚠️ DELIVERY: No user data found in SharedPreferences');
      setState(() => _isLoading = false);
    }

    // Also check if we have trip data in the auth bloc
    final authState = _authBloc.state;
    if (authState is UserTripLoaded && authState.trip.id != null) {
      _currentTripId = authState.trip.id;
      debugPrint('🔍 DELIVERY: Found trip ID in auth bloc: $_currentTripId');

      if (!_hasTriedLocalLoad) {
        _hasTriedLocalLoad = true;
        // Load local data first for immediate display
        _deliveryDataBloc.add(
          GetLocalDeliveryDataByTripIdEvent(_currentTripId!),
        );
        if (mounted) {
          context.read<DeliveryUpdateBloc>().add(CheckEndDeliveryStatusEvent(_currentTripId!));
        }

        //  _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(_currentTripId!));
      }
    }
  }

  // UPDATED: Enhanced refresh data method
  Future<void> _refreshData() async {
    debugPrint('🔄 DELIVERY: Manual refresh triggered');
    setState(() => _isLoading = true);

    if (_currentTripId != null) {
      debugPrint('🔄 DELIVERY: Refreshing data for trip: $_currentTripId');
      _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(_currentTripId!));
      _loadDeliveryDataForTrip(_currentTripId!);
    } else {
      // Try to get trip ID from auth bloc
      final authState = _authBloc.state;
      if (authState is UserTripLoaded && authState.trip.id != null) {
        _currentTripId = authState.trip.id;
        debugPrint(
          '🔍 DELIVERY: Found trip ID in auth bloc during refresh: $_currentTripId',
        );
        _deliveryDataBloc.add(
          GetLocalDeliveryDataByTripIdEvent(_currentTripId!),
        );
        _loadDeliveryDataForTrip(_currentTripId!);
      } else {
        // Try to get from SharedPreferences
        await _loadDataImmediately();
      }
    }
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      _authSubscription = _authBloc.stream.listen((state) {
        if (!mounted) return;

        debugPrint('🔐 Auth State Update in Delivery: ${state.runtimeType}');

        // 📱 OFFLINE-FIRST: Only cache successful states, ignore loading/error states
        if (state is UserTripLoaded && state.trip.id != null) {
          debugPrint('🚚 Trip loaded in delivery screen: ${state.trip.id}');
          setState(() {
            _currentTripId = state.trip.id;
          });

          // Only load if we haven't initialized data yet or trip changed
          if (!_isDataInitialized || _currentTripId != state.trip.id) {
            _loadDeliveryDataForTrip(state.trip.id!);
          }
        }

        // Don't process loading or error states - keep using cached data
        if (state is AuthLoading || state is AuthError) {
          debugPrint(
            '⚠️ Ignoring ${state.runtimeType} - keeping cached data visible',
          );
        }
      });

      _deliveryDataSubscription = _deliveryDataBloc.stream.listen((state) {
        if (!mounted) return;

        debugPrint('📦 DeliveryData state changed: ${state.runtimeType}');

        // 📱 OFFLINE-FIRST: Only cache successful states
        if (state is AllDeliveryDataLoaded) {
          debugPrint(
            '✅ Remote delivery data loaded: ${state.deliveryData.length} items',
          );
          // Don't change UI here, wait for local data to be loaded
          if (_currentTripId != null) {
            _deliveryDataBloc.add(
              GetLocalDeliveryDataByTripIdEvent(_currentTripId!),
            );
          }
        } else if (state is DeliveryDataByTripLoaded) {
          debugPrint(
            '✅ Delivery data loaded: ${state.deliveryData.length} items',
          );
          debugPrint('📊 Trip ID from loaded state: ${state.tripId}');
          debugPrint('📊 Current trip ID: $_currentTripId');

          // Debug first delivery if available
          if (state.deliveryData.isNotEmpty) {
            final firstDelivery = state.deliveryData.first;
            debugPrint('📦 First delivery sample:');
            debugPrint('   ID: ${firstDelivery.id}');
            debugPrint('   Store Name: ${firstDelivery.storeName}');
            debugPrint('   Delivery Number: ${firstDelivery.deliveryNumber}');
            debugPrint(
              '   Has Customer Target: ${firstDelivery.customer.target != null}',
            );
          }

          // Cache successful state
          setState(() {
            _cachedState = state;
            _currentDeliveries = state.deliveryData;
            _isOffline = false;
            _isLoading = false;
            _isDataInitialized = true;
          });
        }

        // Handle errors gracefully - keep cached data visible
        if (state is DeliveryDataError) {
          debugPrint(
            '⚠️ Delivery data network error, using cached data: ${state.message}',
          );
          // Only show loading if we have no cached data
          if (_cachedState == null) {
            setState(() => _isLoading = false);
          }
          // Otherwise, keep showing cached data
        }

        // Don't process loading states - keep showing cached data
        if (state is DeliveryDataLoading) {
          debugPrint('⚠️ Ignoring loading state - keeping cached data visible');
        }
      });

      _deliverySubscription = _deliveryUpdateBloc.stream.listen((state) {
        if (!mounted) return;

        // 📱 OFFLINE-FIRST: Only cache successful states
        if (state is EndDeliveryStatusChecked) {
          setState(() => _cachedDeliveryState = state);
          debugPrint('📊 Delivery status updated: ${state.stats}');
        }

        // Handle errors gracefully
        if (state is DeliveryUpdateError) {
          debugPrint(
            '⚠️ Delivery update error, using cached data: ${state.message}',
          );
        }
      });

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            // 📱 OFFLINE-FIRST: Handle state changes but prioritize cached data in UI
            if (state is AllDeliveryDataLoaded) {
              debugPrint(
                '🔄 DeliveryData listener: Remote data loaded, fetching from local...',
              );
              if (_currentTripId != null) {
                _deliveryDataBloc.add(
                  GetLocalDeliveryDataByTripIdEvent(_currentTripId!),
                );
              }
            } else if (state is DeliveryDataByTripLoaded) {
              debugPrint(
                '🔄 DeliveryData listener: ${state.deliveryData.length} items loaded',
              );
              setState(() {
                _cachedState = state;
                _currentDeliveries = state.deliveryData;
                _isOffline = false;
                _isLoading = false;
                _isDataInitialized = true;
              });
            }
          },
        ),
        BlocListener<DeliveryUpdateBloc, DeliveryUpdateState>(
          listener: (context, state) {
            if (state is EndDeliveryStatusChecked) {
              setState(() => _cachedDeliveryState = state);
            }
          },
        ),
      ],
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshData, // UPDATED: Use enhanced refresh method
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      builder: (context, state) {
        debugPrint('🔍 Building body with state: ${state.runtimeType}');

        // 📱 OFFLINE-FIRST: Always prioritize cached data, ignore loading states
        List<DeliveryDataEntity> deliveriesToShow = [];
        bool showOfflineIndicator = false;

        // 📱 OFFLINE-FIRST: Priority order for data sources
        // 1. _currentDeliveries (from immediate load/cache)
        if (_currentDeliveries.isNotEmpty) {
          deliveriesToShow = _currentDeliveries;
          debugPrint(
            '📱 Delivery using current deliveries (priority 1): ${deliveriesToShow.length} items',
          );

          // Show offline indicator if we're in offline mode
          if (_isOffline || state is DeliveryDataError) {
            showOfflineIndicator = true;
          }
        }
        // 2. Use cached state if available
        else if (_cachedState is DeliveryDataByTripLoaded) {
          deliveriesToShow =
              (_cachedState as DeliveryDataByTripLoaded).deliveryData;
          debugPrint(
            '📱 Delivery using cached state (priority 2): ${deliveriesToShow.length} items',
          );
          debugPrint(
            '📱 Cached state trip ID: ${(_cachedState as DeliveryDataByTripLoaded).tripId}',
          );

          // Debug cached data quality
          if (deliveriesToShow.isNotEmpty) {
            final sampleDelivery = deliveriesToShow.first;
            debugPrint('📦 Cached data sample:');
            debugPrint('   ID: ${sampleDelivery.id}');
            debugPrint('   Store Name: ${sampleDelivery.storeName ?? 'NULL'}');
            debugPrint(
              '   Delivery Number: ${sampleDelivery.deliveryNumber ?? 'NULL'}',
            );
            debugPrint(
              '   Customer Target: ${sampleDelivery.customer.target?.name ?? 'NULL'}',
            );
          }

          // Show offline indicator if current state is error (network issue)
          if (state is DeliveryDataError) {
            showOfflineIndicator = true;
            debugPrint('🔴 Network error detected - showing offline indicator');
          }
        }
        // 3. Only use current state if it's a data state and we have no cache
        else if (state is DeliveryDataByTripLoaded) {
          deliveriesToShow = state.deliveryData;
          debugPrint(
            '📱 Delivery using current state (priority 3): ${deliveriesToShow.length} items',
          );
        }

        // If we have deliveries to show, show them
        if (deliveriesToShow.isNotEmpty) {
          return _buildDeliveryListWithOfflineSupport(
            deliveriesToShow,
            showOfflineIndicator,
          );
        }

        // Show special message if we have cached data but it's empty
        if (_cachedState is DeliveryDataByTripLoaded &&
            deliveriesToShow.isEmpty) {
          debugPrint(
            '📝 Cached data exists but is empty - trip may have no deliveries',
          );
          return _buildEmptyDeliveryStateWithCache(showOfflineIndicator);
        }

        // Handle error states only when we have no cached data
        if (state is DeliveryDataError &&
            _cachedState == null &&
            _currentDeliveries.isEmpty) {
          return _buildErrorState(state.message);
        }

        // 📱 OFFLINE-FIRST: Avoid showing loading state if we're in the process of loading data
        // Instead, show a more optimistic message
        if (_isDataInitialized &&
            (_currentDeliveries.isNotEmpty || _cachedState != null)) {
          // We have some data history, so we shouldn't show empty state
          return _buildLoadingState();
        }

        // Show loading only if we truly have no trip
        if (_currentTripId == null && !_isDataInitialized) {
          return _buildEmptyTripState();
        }

        // Show loading while we wait for the first data load
        if (!_isDataInitialized) {
          return _buildLoadingState();
        }

        // If we have some data but it's empty, show empty state
        return _buildEmptyDeliveryState();
      },
    );
  }

  // 📱 OFFLINE-FIRST: Build delivery list with offline support
  Widget _buildDeliveryListWithOfflineSupport(
    List<DeliveryDataEntity> deliveries,
    bool showOfflineIndicator,
  ) {
    if (deliveries.isEmpty) {
      return _buildEmptyDeliveryState();
    }

    // Debug the delivery data
    _debugDeliveryData(deliveries);

    // Determine if the End Trip button should be enabled
    bool isEndTripButtonEnabled = false;
    String endTripButtonTooltip = 'Complete all deliveries to end trip';

    if (_cachedDeliveryState is EndDeliveryStatusChecked) {
      final stats = (_cachedDeliveryState as EndDeliveryStatusChecked).stats;
      final total = stats['total'] as int? ?? 0;
      final completed = stats['completed'] as int? ?? 0;
      final pending = stats['pending'] as int? ?? 0;

      debugPrint(
        '📊 Delivery Status: Total=$total, Completed=$completed, Pending=$pending',
      );
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
        // 📱 OFFLINE-FIRST: Show offline indicator when using cached data
        if (showOfflineIndicator) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Showing cached data - network unavailable',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final delivery = deliveries[index];
                    debugPrint(
                      '🏪 Rendering delivery ${index + 1}: ${delivery.customer.target?.name ?? 'Unknown Store'}',
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DeliveryListTile(
                        delivery: delivery,
                        isFromLocal: _isOffline,
                         selectionMode: selectionMode,
                          isSelected: selectedDeliveries.contains(delivery.id),
                         onSelectionChanged: (selected) {
    if (delivery.id != null) {
      _toggleSelection(delivery.id!, selected);
    }
  },
            onLongPress: _enableSelectionMode,
                        onTap: () {
                          debugPrint('🔄 Tapped delivery: ${delivery.id}');
                          debugPrint('📊 Delivery index in list: $index');
                          debugPrint('📊 Total deliveries: ${deliveries.length}');
                          debugPrint('📊 Is last customer: ${index == deliveries.length - 1}');
                          
                          if (delivery.id != null) {
                            debugPrint('🚀 Navigating to delivery details for: ${delivery.id}');
                            
                            // Navigate immediately with customer data
                            // Data loading will be handled by the destination screen
                            context.go(
                              '/delivery-and-invoice/${delivery.id}',
                              extra: delivery,
                            );
                          }
                        },
                      ),
                    );
                  }, childCount: deliveries.length),
                ),
              ),
            ],
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
      // ✅ Clear selection & reset to default mode
      _disableSelectionMode();
    }
  },
                  onCancel: _disableSelectionMode,
                )
              :EndTripButton(
                    isEnabled: isEndTripButtonEnabled,
                    tooltip: endTripButtonTooltip,
                  ),
        // Always show EndTripButton but control its enabled state
        
      ],
    );
  }

  void _debugDeliveryData(List<DeliveryDataEntity> deliveries) {
    debugPrint(
      '📋 DEBUGGING DELIVERY DATA - Total deliveries: ${deliveries.length}',
    );
    for (int i = 0; i < deliveries.length; i++) {
      final delivery = deliveries[i];
      debugPrint('🔍 Delivery ${i + 1}:');
      debugPrint('   ID: ${delivery.id}');
      debugPrint('   Delivery Number: ${delivery.deliveryNumber}');
      debugPrint('   Store Name: ${delivery.storeName}');
      debugPrint('   Owner Name: ${delivery.ownerName}');
      debugPrint('   Contact Number: ${delivery.contactNumber}');
      debugPrint(
        '   Address: ${delivery.barangay}, ${delivery.municipality}, ${delivery.province}',
      );
      debugPrint('   Customer Target: ${delivery.customer.target}');
      debugPrint('   Customer Store Name: ${delivery.customer.target?.name}');
      debugPrint('   Customer Address: ${delivery.customer.target?.province}');
      debugPrint('   Invoice Target: ${delivery.invoice.target}');
      debugPrint('   Payment Mode: ${delivery.paymentMode}');
      debugPrint('   Trip: ${delivery.trip.target?.id}');
      debugPrint(
        '   Delivery Updates Count: ${delivery.deliveryUpdates.length}',
      );
      debugPrint('   Invoice Items Count: ${delivery.invoiceItems.length}');
      debugPrint('   ───────────────────────────────────────');
    }
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _deliveryDataBloc = context.read<DeliveryDataBloc>();
    _deliveryUpdateBloc = context.read<DeliveryUpdateBloc>();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final userId = userData['id'];
      final tripData = userData['trip'] as Map<String, dynamic>?;

      debugPrint('👤 Loading initial data for user: $userId');

      if (userId != null) {
        // Load user data first
        _authBloc.add(LoadLocalUserByIdEvent(userId));

        // If we have trip data, load it
        if (tripData != null && tripData['id'] != null) {
          debugPrint('🚚 Loading trip from stored data: ${tripData['id']}');
          setState(() {
            _currentTripId = tripData['id'];
          });

          // Load user trip
          _authBloc.add(LoadLocalUserTripEvent(userId));

          // Load delivery data for this trip
          _loadDeliveryDataForTrip(tripData['id']);
        }
      }
    }
  }

  void _loadDeliveryDataForTrip(String tripId) {
    debugPrint('📦 Loading delivery data for trip: $tripId');

    // First try to load from local storage
    _deliveryDataBloc.add(GetLocalDeliveryDataByTripIdEvent(tripId));

    // // Then load from remote to ensure we have the latest data and cache it
    _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(tripId));

    // Check delivery status
    _deliveryUpdateBloc
      ..add(CheckLocalEndDeliveryStatusEvent(tripId))
      ..add(CheckEndDeliveryStatusEvent(tripId));
  }

  // 📱 OFFLINE-FIRST: Build delivery list with offline support

  // Keep original method for backwards compatibility

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LoadingTileList(
        itemCount: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show 3 loading tiles at the top
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LoadingTileList(
              itemCount: 3,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('Please Wait', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_currentTripId != null) {
                _loadDeliveryDataForTrip(_currentTripId!);
              } else {
                _loadInitialData();
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTripState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text('Please wait', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Loading.....', style: Theme.of(context).textTheme.bodyMedium),
          // const SizedBox(height: 16),
          // CircularProgressIndicator()
        ],
      ),
    );
  }

  Widget _buildEmptyDeliveryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text('Please wait', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Loading.....', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_currentTripId != null) {
                _loadDeliveryDataForTrip(_currentTripId!);
              }
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDeliveryStateWithCache(bool showOfflineIndicator) {
    return Column(
      children: [
        // 📱 OFFLINE-FIRST: Show offline indicator when using cached data
        if (showOfflineIndicator) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Offline mode - Trip has no deliveries',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  showOfflineIndicator
                      ? 'No Deliveries (Offline)'
                      : 'Please Wait',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  showOfflineIndicator
                      ? 'This trip has no deliveries (cached data)'
                      : 'Loading......',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_currentTripId != null) {
                      _loadDeliveryDataForTrip(_currentTripId!);
                    }
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app comes back to foreground, refresh end delivery status
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 LIFECYCLE: App resumed, refreshing end delivery status');
      _refreshEndDeliveryStatus();
    }
  }

  /// Refresh end delivery status when screen becomes visible
  void _refreshEndDeliveryStatus() {
    if (_currentTripId != null && mounted) {
      debugPrint('🔄 REFRESH: Checking end delivery status for trip: $_currentTripId');
      
      // Check local first for immediate update
      _deliveryUpdateBloc.add(CheckLocalEndDeliveryStatusEvent(_currentTripId!));
      
      // Then check remote for latest data
      _deliveryUpdateBloc.add(CheckEndDeliveryStatusEvent(_currentTripId!));
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing DeliveryListScreen');
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _deliveryDataSubscription?.cancel();
    _deliverySubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
