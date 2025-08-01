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
    _initializeBlocs();
    if (widget.selectedCustomer != null) {
      _cachedState = DeliveryDataLoaded(widget.selectedCustomer!);
      debugPrint('📱 DELIVERY: Initial cached state set with provided customer: ${widget.selectedCustomer!.id}');
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

      // 📱 OFFLINE-FIRST: Only cache successful states
      if (state is DeliveryDataLoaded || state is DeliveryDataByTripLoaded) {
        setState(() => _cachedState = state);
        debugPrint('✅ DELIVERY: Data cached: ${state.runtimeType}');
      }
      
      // Handle errors gracefully - keep cached data visible
      if (state is DeliveryDataError) {
        debugPrint('⚠️ DELIVERY: Data network error, using cached data: ${state.message}');
        // Only try fallback if we have no cached data
        if (_cachedState == null && widget.selectedCustomer?.id != null) {
          debugPrint('🔄 No cached data, trying local fallback...');
          _deliveryDataBloc.add(GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id!));
        }
      }
      
      // Don't process loading states - keep showing cached data
      if (state is DeliveryDataLoading) {
        debugPrint('⚠️ Ignoring loading state - keeping cached delivery data visible');
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
      }
      
      // Handle errors gracefully - keep cached data visible
      if (state is DeliveryUpdateError) {
        debugPrint('⚠️ DELIVERY: Update network error, using cached data: ${state.message}');
        // Only try fallback if we have no cached data
        if (_cachedUpdateState == null && widget.selectedCustomer?.id != null) {
          debugPrint('🔄 No cached update data, trying local fallback...');
          _deliveryUpdateBloc.add(LoadLocalDeliveryStatusChoicesEvent(widget.selectedCustomer!.id!));
        }
      }
      
      // Don't process loading states - keep showing cached data
      if (state is DeliveryUpdateLoading) {
        debugPrint('⚠️ Ignoring loading state - keeping cached update data visible');
      }
    });
  }

  void _initializeLocalData() {
    if (!_isDataInitialized && widget.selectedCustomer != null) {
      debugPrint('📱 DELIVERY: Loading initial data for delivery: ${widget.selectedCustomer!.id}');
      debugPrint('📊 DELIVERY: Current cached states - Data: ${_cachedState?.runtimeType ?? 'null'}, Update: ${_cachedUpdateState?.runtimeType ?? 'null'}');
      
      // Load delivery data - local first, then remote
      _deliveryDataBloc
        ..add(GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id!))
        ..add(GetDeliveryDataByIdEvent(widget.selectedCustomer!.id!));
      
      // Load delivery update choices
      _deliveryUpdateBloc.add(
        LoadLocalDeliveryStatusChoicesEvent(widget.selectedCustomer!.id!),
      );
      
      _isDataInitialized = true;
    }
  }

  Future<void> _refreshData() async {
    if (widget.selectedCustomer?.id != null) {
      debugPrint('🔄 DELIVERY: Refreshing data for delivery: ${widget.selectedCustomer!.id}');
      
      // Always try remote first on manual refresh
      _deliveryDataBloc
        ..add(GetDeliveryDataByIdEvent(widget.selectedCustomer!.id!))
        ..add(GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id!));
      
      _deliveryUpdateBloc.add(
        LoadLocalDeliveryStatusChoicesEvent(widget.selectedCustomer!.id!),
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

    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            // 📱 OFFLINE-FIRST: Handle state changes but prioritize cached data in UI
            if (state is DeliveryDataLoaded || state is DeliveryDataByTripLoaded) {
              setState(() => _cachedState = state);
              debugPrint('📦 DELIVERY: Data listener - cached state updated: ${state.runtimeType}');
            } else if (state is DeliveryDataError) {
              debugPrint('⚠️ DELIVERY: Data network error, keeping cached data: ${state.message}');
              // Only fallback if we have no cached data at all
              if (_cachedState == null && widget.selectedCustomer?.id != null) {
                debugPrint('🔄 No cached data, falling back to local delivery data');
                _deliveryDataBloc.add(GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id!));
              }
            }
          },
        ),
        BlocListener<DeliveryUpdateBloc, DeliveryUpdateState>(
          listener: (context, state) {
            // 📱 OFFLINE-FIRST: Handle state changes but prioritize cached data in UI
            if (state is DeliveryStatusChoicesLoaded || 
                state is DeliveryStatusUpdateSuccess || 
                state is DeliveryCompletionSuccess ||
                state is DeliveryStatusCreated) {
              setState(() => _cachedUpdateState = state);
              debugPrint('📝 DELIVERY: Update listener - cached state updated: ${state.runtimeType}');
            } else if (state is DeliveryUpdateError) {
              debugPrint('⚠️ DELIVERY: Update network error, keeping cached data: ${state.message}');
              // Only fallback if we have no cached data at all
              if (_cachedUpdateState == null && widget.selectedCustomer?.id != null) {
                debugPrint('🔄 No cached update data, falling back to local update data');
                _deliveryUpdateBloc.add(LoadLocalDeliveryStatusChoicesEvent(widget.selectedCustomer!.id!));
              }
            }
          },
        ),
      ],
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        buildWhen: (previous, current) =>
            current is DeliveryDataLoaded ||
            current is DeliveryDataError ||
            _cachedState == null,
        builder: (context, state) {
          // 📱 OFFLINE-FIRST: Always prioritize cached data, ignore loading states
          DeliveryDataState? effectiveState;
          bool showOfflineIndicator = false;
          
          // Use cached data if available, regardless of current state
          if (_cachedState != null) {
            effectiveState = _cachedState;
            debugPrint('📱 DELIVERY: Using cached state: ${_cachedState.runtimeType}');
            
            // Show offline indicator if current state is error (network issue)
            if (state is DeliveryDataError) {
              showOfflineIndicator = true;
              debugPrint('🔴 Network error detected - showing offline indicator');
            }
          }
          // Only use current state if we have no cache
          else {
            effectiveState = state;
            debugPrint('📱 DELIVERY: Using current state: ${state.runtimeType}');
          }

          // Only show loading if we have no cached data at all
          if (effectiveState is DeliveryDataLoading && _cachedState == null) {
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

          // Only show error if we have no cached data to fall back to
          if (effectiveState is DeliveryDataError && _cachedState == null) {
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
                      effectiveState.message,
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

          if (effectiveState is DeliveryDataLoaded) {
            return _buildSelectedCustomerView(effectiveState.deliveryData, showOfflineIndicator);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSelectedCustomerView(DeliveryDataEntity deliveryData, bool showOfflineIndicator) {
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
