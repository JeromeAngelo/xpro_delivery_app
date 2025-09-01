import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/customer_summary_dialog.dart';

//import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/update_queue_remark_dialog.dart';

class UpdateStatusDrawer extends StatefulWidget {
  final String customerId;
  const UpdateStatusDrawer({super.key, required this.customerId});

  @override
  State<UpdateStatusDrawer> createState() => _UpdateStatusDrawerState();
}

class _UpdateStatusDrawerState extends State<UpdateStatusDrawer> {
  DeliveryUpdateState? _cachedState;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initializeLocalData();
  }

  void _initializeLocalData() {
    final deliveryUpdateBloc = context.read<DeliveryUpdateBloc>();

    _subscription = deliveryUpdateBloc.stream.listen((state) {
      if (state is DeliveryStatusChoicesLoaded && mounted) {
        setState(() {
          _cachedState = state;
        });
      }
    });

    // Load local delivery status choices
    deliveryUpdateBloc.add(
      LoadLocalDeliveryStatusChoicesEvent(widget.customerId),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryUpdateBloc, DeliveryUpdateState>(
          listener: (context, state) {
            if (state is DeliveryStatusUpdateSuccess) {
              debugPrint('✅ Status update success, closing drawer');
              // Close drawer immediately without refreshing data
              // Data will be updated through the existing cache mechanism
              if (mounted) {
                Navigator.of(context).pop();
              }
            }
          },
        ),
      ],
      child: BlocConsumer<DeliveryUpdateBloc, DeliveryUpdateState>(
        listenWhen:
            (previous, current) => current is DeliveryStatusChoicesLoaded,
        listener: (context, state) {
          if (state is DeliveryStatusChoicesLoaded) {
            _cachedState = state;
          }
        },
        buildWhen:
            (previous, current) =>
                current is DeliveryStatusChoicesLoaded || _cachedState == null,
        builder: (context, state) {
          final effectiveState = _cachedState ?? state;

          if (state is DeliveryUpdateLoading && _cachedState == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (effectiveState is DeliveryStatusChoicesLoaded) {
            final availableStatuses = effectiveState.statusChoices;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.2,
              maxChildSize: 0.9,
              expand: false,
              builder:
                  (_, controller) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: CustomScrollView(
                      controller: controller,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      // In status_drawers.dart, update the ElevatedButton.icon onPressed:
                                      onPressed: () async {
                                        Navigator.pop(
                                          context,
                                        ); // Close the modal bottom sheet first

                                        final customerState =
                                            context
                                                .read<DeliveryDataBloc>()
                                                .state;
                                        if (customerState
                                            is DeliveryDataLoaded) {
                                          final result = await context.push(
                                            '/add-delivery-status',
                                            extra: customerState.deliveryData,
                                          );
                                          if (result == true) {
                                            context.read<DeliveryUpdateBloc>().add(
                                              LoadLocalDeliveryStatusChoicesEvent(
                                                widget.customerId,
                                              ),
                                            );
                                          }
                                        }
                                      },

                                      label: const Text("Add Delivery Status"),
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final status = availableStatuses[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                  width: 2.0,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Icon(
                                  StatusIcons.getStatusIcon(status.title ?? ''),
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                                title: Text(
                                  status.title ?? '',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  status.subtitle ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                onTap:
                                    () => _updateCustomerStatus(
                                      status.id ?? '',
                                      status.title ?? '',
                                    ),
                              ),
                            );
                          }, childCount: availableStatuses.length),
                        ),
                      ],
                    ),
                  ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _updateCustomerStatus(String statusId, String statusTitle) {
    final currentTime = DateTime.now();
    debugPrint('📝 Updating status at: ${currentTime.toIso8601String()}');

    if (statusTitle.toLowerCase() == 'arrived') {
      debugPrint('📍 Processing arrived status - updating location and status');
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final customerState = deliveryDataBloc.state;

      if (customerState is DeliveryDataLoaded) {
        // Handle location update and status update - this will return early
        _getCurrentLocationAndUpdate(deliveryDataBloc, statusId);
        return; // Important: return here to prevent double status update
      }
    }

    if (statusTitle.toLowerCase() == 'unloading') {
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final customerState = deliveryDataBloc.state;

      if (customerState is DeliveryDataLoaded) {
        final deliveryData = customerState.deliveryData;
        debugPrint('📦 Setting invoice to unloading for: ${deliveryData.id}');

        context.read<DeliveryDataBloc>().add(
          SetInvoiceIntoUnloadingEvent(deliveryData.id ?? ''),
        );

        // Also update the delivery status
        context.read<DeliveryUpdateBloc>().add(
          UpdateDeliveryStatusEvent(
            customerId: widget.customerId,
            statusId: statusId,
          ),
        );
        return; // Important: return here to prevent double status update
      }
    }

    if (statusTitle.toLowerCase() == 'mark as undelivered') {
      // Close the modal bottom sheet first and navigate
      if (mounted) {
        Navigator.of(context).pop();

        final customerState = context.read<DeliveryDataBloc>().state;
        if (customerState is DeliveryDataLoaded) {
          // Use a small delay to ensure navigation state is clean
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              context.push(
                '/undeliverable/${widget.customerId}',
                extra: {
                  'customer': customerState.deliveryData,
                  'statusId': statusId,
                },
              );
            }
          });
        }
      }
      return;
    }

    // Add this new condition for "end delivery"
    if (statusTitle.toLowerCase() == 'end delivery') {
      if (mounted) {
        final deliveryDataBloc = context.read<DeliveryDataBloc>();
        final customerState = deliveryDataBloc.state;

        if (customerState is DeliveryDataLoaded) {
          final deliveryData = customerState.deliveryData;

          // Close the modal bottom sheet first
          Navigator.of(context).pop();

          // Calculate total time
          deliveryDataBloc.add(CalculateDeliveryTimeEvent(widget.customerId));

          // Complete delivery
          context.read<DeliveryUpdateBloc>().add(
            CompleteDeliveryEvent(deliveryData: deliveryData),
          );

          context.read<DeliveryDataBloc>().add(
            SetInvoiceIntoCompletedEvent(deliveryData.id ?? ''),
          );

          // Use a small delay to ensure navigation state is clean
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Show summary dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        CustomerSummaryDialog(deliveryData: deliveryData),
              );
            }
          });
        }
      }
      return;
    }

    // Update delivery status - this will trigger the BlocListener above to close the drawer
    debugPrint('📝 Firing status update event for: $statusTitle');
    context.read<DeliveryUpdateBloc>().add(
      UpdateDeliveryStatusEvent(
        customerId: widget.customerId,
        statusId: statusId,
      ),
    );
  }

  /// Get current location and update delivery location, then proceed with status update
  Future<void> _getCurrentLocationAndUpdate(
    DeliveryDataBloc deliveryDataBloc,
    String statusId,
  ) async {
    try {
      debugPrint('📍 Getting current location for arrived status...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        _proceedWithStatusUpdate(statusId);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permissions are denied');
          _proceedWithStatusUpdate(statusId);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permissions are permanently denied');
        _proceedWithStatusUpdate(statusId);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint(
        '✅ Current location obtained: ${position.latitude}, ${position.longitude}',
      );

      // Update delivery location with current coordinates
      if (mounted) {
        deliveryDataBloc.add(
          UpdateDeliveryLocationEvent(
            id: widget.customerId,
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }

      // Proceed with status update
      _proceedWithStatusUpdate(statusId);
    } catch (e) {
      debugPrint('❌ Error getting location: ${e.toString()}');
      // Proceed with status update even if location fails
      _proceedWithStatusUpdate(statusId);
    }
  }

  // Proceed with the arrived status update after location is handled
  void _proceedWithStatusUpdate(String statusId) {
    if (!mounted) return;

    // Update the delivery status - this will trigger the BlocListener to close the drawer
    context.read<DeliveryUpdateBloc>().add(
      UpdateDeliveryStatusEvent(
        customerId: widget.customerId,
        statusId: statusId,
      ),
    );

    debugPrint('✅ Status update event fired');
  }
}
