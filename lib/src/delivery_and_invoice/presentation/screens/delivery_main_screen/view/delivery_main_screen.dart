import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_state.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/customer_details_dashboard.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/maps.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/delivery_timeline.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/update_delivery_btn.dart';

class DeliveryMainScreen extends StatefulWidget {
  final DeliveryDataEntity? selectedCustomer;

  const DeliveryMainScreen({super.key, this.selectedCustomer});

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen>
    with AutomaticKeepAliveClientMixin {
  bool isMapMinimized = false;
  bool _isDataInitialized = false;
  DeliveryDataState? _cachedState;
  DeliveryUpdateState? _cachedUpdateState;
  late final DeliveryDataBloc _deliveryDataBloc;
  late final DeliveryUpdateBloc _deliveryUpdateBloc;
  StreamSubscription? _deliveryDataSubscription;
  StreamSubscription? _deliveryUpdateSubscription;

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo('🚚 DeliveryMainScreen initialized');
    
    _initializeBlocs();
    if (widget.selectedCustomer != null) {
      _cachedState = DeliveryDataLoaded(widget.selectedCustomer!);
      AppDebugLogger.instance.logInfo(
        '📦 Customer data loaded: ${widget.selectedCustomer!.storeName ?? 'Unknown'}',
        details: 'Customer ID: ${widget.selectedCustomer!.id}',
      );
    }
    _setupDataListeners();
    _initializeLocalData();
  }

  void _initializeBlocs() {
    _deliveryDataBloc = context.read<DeliveryDataBloc>();
    _deliveryUpdateBloc = context.read<DeliveryUpdateBloc>();
  }

  void _setupDataListeners() {
    _deliveryDataSubscription = _deliveryDataBloc.stream.listen((state) {
      debugPrint('📦 DELIVERY: Data state update: ${state.runtimeType}');
      if (!mounted) return;

      // 📱 OFFLINE-FIRST: Only cache successful states, preserve cached data during loading
      if (state is DeliveryDataLoaded || state is DeliveryDataByTripLoaded) {
        setState(() => _cachedState = state);
        debugPrint('✅ DELIVERY: Data cached: ${state.runtimeType}');
      }

      // Handle errors gracefully - keep cached data visible
      if (state is DeliveryDataError) {
        debugPrint(
          '⚠️ DELIVERY: Data network error, using cached data: ${state.message}',
        );
        // Only try fallback if we have no cached data
        if (_cachedState == null && widget.selectedCustomer?.id != null) {
          debugPrint('🔄 No cached data, trying local fallback...');
          _deliveryDataBloc.add(
            GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id!),
          );
          _deliveryDataBloc.add(
            GetDeliveryDataByIdEvent(widget.selectedCustomer!.id!),
          );
        }
      }

      // Don't process loading states - keep showing cached data
      if (state is DeliveryDataLoading) {
        debugPrint(
          '⚠️ Ignoring loading state - keeping cached delivery data visible',
        );
      }
    });

    _deliveryUpdateSubscription = _deliveryUpdateBloc.stream.listen((state) {
      debugPrint('📝 DELIVERY: Update state change: ${state.runtimeType}');
      if (!mounted) return;

      // 📱 OFFLINE-FIRST: Only cache successful states
      if (state is DeliveryStatusChoicesLoaded ||
          state is DeliveryStatusUpdateSuccess ||
          state is DeliveryCompletionSuccess ||
          state is DeliveryStatusCreated) {
        setState(() => _cachedUpdateState = state);
        debugPrint('✅ DELIVERY: Update state cached: ${state.runtimeType}');

        // 📱 SMART REFRESH: Auto-refresh data when status updates succeed
        if (state is DeliveryStatusUpdateSuccess ||
            state is DeliveryCompletionSuccess ||
            state is DeliveryStatusCreated) {
          AppDebugLogger.instance.logDeliveryStatusUpdate(
            widget.selectedCustomer?.id ?? 'unknown',
            'Previous Status',
            state.runtimeType.toString(),
          );
          
          // Delay refresh slightly to ensure status update is processed
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && widget.selectedCustomer?.id != null) {
              AppDebugLogger.instance.logInfo('🔄 Auto-refreshing delivery data after status update');
              _deliveryDataBloc.add(
                GetDeliveryDataByIdEvent(widget.selectedCustomer!.id!),
              );
            }
          });
        }
      }

      // Handle errors gracefully - keep cached data visible
      if (state is DeliveryUpdateError) {
        debugPrint(
          '⚠️ DELIVERY: Update network error, using cached data: ${state.message}',
        );
        // Only try fallback if we have no cached data
        if (_cachedUpdateState == null && widget.selectedCustomer?.id != null) {
          debugPrint('🔄 No cached update data, trying local fallback...');
          _deliveryUpdateBloc.add(
            LoadLocalDeliveryStatusChoicesEvent(widget.selectedCustomer!.id!),
          );
        }
      }

      // Don't process loading states - keep showing cached data
      if (state is DeliveryUpdateLoading) {
        debugPrint(
          '⚠️ Ignoring loading state - keeping cached update data visible',
        );
      }
    });
  }

  void _initializeLocalData() {
    if (!_isDataInitialized && widget.selectedCustomer != null) {
      debugPrint(
        '📱 DELIVERY: OFFLINE-FIRST - Initializing with provided customer data: ${widget.selectedCustomer!.id}',
      );
      debugPrint(
        '📊 DELIVERY: Current cached states - Data: ${_cachedState?.runtimeType ?? 'null'}, Update: ${_cachedUpdateState?.runtimeType ?? 'null'}',
      );

      // Since we already have customer data from navigation, only load delivery update choices
      // Data loading is handled by the router to prevent multiple loading states
      debugPrint('📱 DELIVERY: Skipping data load since customer provided via navigation');
      
      // Only load delivery update choices which are needed for the status drawers
      _deliveryUpdateBloc.add(
        LoadLocalDeliveryStatusChoicesEvent(widget.selectedCustomer!.id!),
      );

      _isDataInitialized = true;
    }
  }

  Future<void> _refreshData() async {
    if (widget.selectedCustomer?.id != null) {
      debugPrint(
        '🔄 DELIVERY: Manual refreshing data for delivery: ${widget.selectedCustomer!.id}',
      );

      // 📱 OFFLINE-FIRST: Don't clear cache on manual refresh - just trigger data fetch
      // This ensures immediate response with cached data, then updates when new data arrives

      // Trigger fresh data fetch - will update cache when successful
      _deliveryDataBloc.add(
        GetDeliveryDataByIdEvent(widget.selectedCustomer!.id!),
      );

        // Trigger fresh data fetch - will update cache when successful
      _deliveryDataBloc.add(
        GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id!),
      );

      _deliveryUpdateBloc.add(
        LoadLocalDeliveryStatusChoicesEvent(widget.selectedCustomer!.id!),
      );

      debugPrint(
        '🔄 DELIVERY: Manual refresh triggered - cache preserved for instant response',
      );
    }
  }

  double? parseCoordinate(String? value) {
    if (value == null) return null;
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      buildWhen: (previous, current) {
        debugPrint(
          '🏠 MAIN SCREEN: BuildWhen - Previous: ${previous.runtimeType}, Current: ${current.runtimeType}',
        );

        // 📱 OFFLINE-FIRST: Only rebuild for loaded states, not loading states
        if (current is DeliveryDataLoaded ||
            current is DeliveryDataByTripLoaded ||
            current is InvoiceSetToUnloading ||
            current is InvoiceSetToUnloaded) {
          debugPrint(
            '🏠 MAIN SCREEN: Rebuilding for loaded/update state: ${current.runtimeType}',
          );
          return true;
        }

        // If we have cached data, don't rebuild for loading/error states
        if (_cachedState != null &&
            (current is DeliveryDataLoading || current is DeliveryDataError)) {
          debugPrint(
            '🏠 MAIN SCREEN: Skipping rebuild - using cached data while ${current.runtimeType}',
          );
          return false;
        }

        // Initial build or no cached data
        return true;
      },
      builder: (context, state) {
        debugPrint(
          '📱 DELIVERY: Building with current state: ${state.runtimeType}',
        );

        // 📱 OFFLINE-FIRST: Prioritize cached data, then current state, then fallback
        DeliveryDataEntity? deliveryData;
        bool showOfflineIndicator = false;

        if (state is DeliveryDataLoaded && state.deliveryData.id != null) {
          deliveryData = state.deliveryData;
          debugPrint('📱 MAIN SCREEN: Using fresh loaded data with ID: ${state.deliveryData.id}');
        } else if (state is DeliveryDataLoaded && state.deliveryData.id == null && widget.selectedCustomer != null) {
          // If loaded data is empty but we have selectedCustomer, use it
          deliveryData = widget.selectedCustomer!;
          debugPrint('📱 MAIN SCREEN: Loaded data is empty, using selectedCustomer from navigation');
        } else if (state is DeliveryDataByTripLoaded) {
          // Find the current delivery from trip data
          final deliveries =
              state.deliveryData
                  .where((d) => d.id == widget.selectedCustomer?.id)
                  .toList();
          if (deliveries.isNotEmpty) {
            deliveryData = deliveries.first;
          } else if (widget.selectedCustomer != null) {
            deliveryData = widget.selectedCustomer;
          }
          debugPrint('📱 MAIN SCREEN: Using data from trip loaded state');
        } else if (state is InvoiceSetToUnloading ||
            state is InvoiceSetToUnloaded) {
          // Handle invoice state updates - extract delivery data
          if (state is InvoiceSetToUnloading) {
            deliveryData = state.deliveryData;
          } else if (state is InvoiceSetToUnloaded) {
            deliveryData = state.deliveryData;
          }
          debugPrint(
            '📱 MAIN SCREEN: Using data from invoice state update: ${state.runtimeType}',
          );
        } else if (_cachedState is DeliveryDataLoaded) {
          deliveryData = (_cachedState as DeliveryDataLoaded).deliveryData;
          showOfflineIndicator = state is DeliveryDataError;
          debugPrint(
            '📱 MAIN SCREEN: Using cached data while state is ${state.runtimeType}',
          );
        } else if (_cachedState is DeliveryDataByTripLoaded) {
          final cachedTripState = _cachedState as DeliveryDataByTripLoaded;
          final deliveries =
              cachedTripState.deliveryData
                  .where((d) => d.id == widget.selectedCustomer?.id)
                  .toList();
          if (deliveries.isNotEmpty) {
            deliveryData = deliveries.first;
          } else if (widget.selectedCustomer != null) {
            deliveryData = widget.selectedCustomer;
          }
          showOfflineIndicator = state is DeliveryDataError;
          debugPrint(
            '📱 MAIN SCREEN: Using cached trip data while state is ${state.runtimeType}',
          );
        } else if (widget.selectedCustomer != null) {
          deliveryData = widget.selectedCustomer;
          showOfflineIndicator = state is DeliveryDataError;
          debugPrint('📱 MAIN SCREEN: Using fallback widget data');
        }

        // Only show pure loading if we have no data at all
        if (deliveryData == null) {
          if (state is DeliveryDataLoading) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading delivery data...'),
                  ],
                ),
              ),
            );
          }

          if (state is DeliveryDataError && _cachedState == null) {
            return Scaffold(
              body: Center(
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
                      state.message,
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
              ),
            );
          }

          return const Scaffold(
            body: Center(child: Text('No delivery data available')),
          );
        }

        return _buildSelectedCustomerView(deliveryData, showOfflineIndicator);
      },
    );
  }

  Widget _buildSelectedCustomerView(
    DeliveryDataEntity deliveryData,
    bool showOfflineIndicator,
  ) {
    final customer = deliveryData.customer.target;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
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
                      CustomerDetailsDashboard(
                        deliveryData: deliveryData,
                        onTap: () {
                          final lat = parseCoordinate('${customer?.latitude}');
                          final lng = parseCoordinate('${customer?.longitude}');
                          if (lat != null && lng != null) {
                            // Map focus handling if needed
                          }
                        },
                      ),

                      // // Notes section
                      // if (customer?.hasNotes == true) ...[
                      //   Container(
                      //     margin: const EdgeInsets.all(16),
                      //     padding: const EdgeInsets.all(12),
                      //     decoration: BoxDecoration(
                      //       color: Theme.of(context).colorScheme.surfaceVariant,
                      //       borderRadius: BorderRadius.circular(8),
                      //       border: Border.all(
                      //         color: Theme.of(
                      //           context,
                      //         ).colorScheme.outline.withOpacity(0.5),
                      //       ),
                      //     ),
                      //     child: Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Row(
                      //           children: [
                      //             Icon(
                      //               Icons.note_alt_outlined,
                      //               color:
                      //                   Theme.of(context).colorScheme.primary,
                      //             ),
                      //             const SizedBox(width: 8),
                      //             Text(
                      //               'Notes',
                      //               style: Theme.of(context)
                      //                   .textTheme
                      //                   .titleMedium!
                      //                   .copyWith(fontWeight: FontWeight.bold),
                      //             ),
                      //           ],
                      //         ),
                      //         const SizedBox(height: 8),
                      //         Text(
                      //           customer?.notes ?? '',
                      //           style: Theme.of(context).textTheme.bodyMedium,
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ],
                      _buildMapSection(deliveryData),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 16.0,
                            top: 16.0,
                            bottom: 8.0,
                          ),
                          child: Text(
                            'Delivery Timeline',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DeliveryTimeline(customerId: '${deliveryData.id}'),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: UpdateDeliveryBtn(
                currentStatus: _getCurrentDeliveryStatus(deliveryData),
                customerId: deliveryData.id ?? '',
                isDisabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDeliveryStatus(DeliveryDataEntity deliveryData) {
    final deliveryUpdates = deliveryData.deliveryUpdates.toList();
    return deliveryUpdates.isNotEmpty ? deliveryUpdates.last.title ?? '' : '';
  }

  Widget _buildMapSection(DeliveryDataEntity deliveryData) {
    final latestStatus =
        _getCurrentDeliveryStatus(deliveryData).toLowerCase().trim();
    debugPrint('🗺️ Latest delivery status: $latestStatus');

    final hideMapStatuses = [
      'arrived',
      'unloading',
      'mark as received',
      'end delivery',
    ];
    final shouldHideMap = hideMapStatuses.contains(latestStatus);

    if (shouldHideMap) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Container(
          height: isMapMinimized ? 150.0 : 300.0,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: CustomerMapScreen(
            selectedCustomer: deliveryData,
            height: isMapMinimized ? 150.0 : 300.0,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isMapMinimized ? Icons.expand : Icons.minimize,
                color: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  isMapMinimized = !isMapMinimized;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing DeliveryMainScreen');
    _deliveryDataSubscription?.cancel();
    _deliveryUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
