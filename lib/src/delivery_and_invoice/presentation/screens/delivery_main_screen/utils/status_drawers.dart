import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/customer_summary_dialog.dart';

import '../../../../../../core/common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';
import '../../../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_bloc.dart';
import '../../../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_event.dart';
import '../../../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_state.dart';

class UpdateStatusDrawer extends StatefulWidget {
  final String deliveryDataId;

  const UpdateStatusDrawer({super.key, required this.deliveryDataId});

  @override
  State<UpdateStatusDrawer> createState() => _UpdateStatusDrawerState();
}

class _UpdateStatusDrawerState extends State<UpdateStatusDrawer> {
  DeliveryStatusChoicesState? _cachedState;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initializeLocalData();
  }

  void _initializeLocalData() {
    final deliveryUpdateBloc = context.read<DeliveryStatusChoicesBloc>();

    _subscription = deliveryUpdateBloc.stream.listen((state) {
      if (state is AssignedDeliveryStatusChoicesLoaded && mounted) {
        setState(() {
          _cachedState = state;
        });
      }
    });

    // Load local delivery status choices
    deliveryUpdateBloc.add(
      GetAllAssignedDeliveryStatusChoicesEvent(widget.deliveryDataId),
    );

     // Load local delivery status choices
    deliveryUpdateBloc.add(
      GetAllAssignedDeliveryStatusChoicesEvent(widget.deliveryDataId),
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
        BlocListener<DeliveryStatusChoicesBloc, DeliveryStatusChoicesState>(
          listener: (context, state) {
            if (state is DeliveryStatusUpdated) {
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
      child: BlocConsumer<
        DeliveryStatusChoicesBloc,
        DeliveryStatusChoicesState
      >(
        listenWhen: (previous, current) => current is DeliveryStatusUpdated,
        listener: (context, state) {
          if (state is AssignedDeliveryStatusChoicesLoaded) {
            _cachedState = state;
          }
        },
        buildWhen:
            (previous, current) =>
                current is AssignedDeliveryStatusChoicesLoaded ||
                _cachedState == null,
        builder: (context, state) {
          final effectiveState = _cachedState ?? state;

          if (state is DeliveryUpdateLoading && _cachedState == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (effectiveState is AssignedDeliveryStatusChoicesLoaded) {
            final availableStatuses = effectiveState.updates;

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
                                            context
                                                .read<
                                                  DeliveryStatusChoicesBloc
                                                >()
                                                .add(
                                                  GetAllAssignedDeliveryStatusChoicesEvent(
                                                    widget.deliveryDataId,
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
                                onTap: () => _updateCustomerStatus(status),
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

  void _updateCustomerStatus(DeliveryStatusChoicesEntity status) {
    final statusTitle = status.title?.toLowerCase() ?? '';
    debugPrint('📝 Updating status: ${status.title}');

    // ---------------- ARRIVED ----------------
    if (statusTitle == 'arrived') {
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final state = deliveryDataBloc.state;

      if (state is DeliveryDataLoaded) {
        _getCurrentLocationAndUpdate(deliveryDataBloc, status);
        return;
      }
    }

    // ---------------- UNLOADING ----------------
    if (statusTitle == 'unloading') {
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final state = deliveryDataBloc.state;

      if (state is DeliveryDataLoaded) {
        context.read<DeliveryDataBloc>().add(
          SetInvoiceIntoUnloadingEvent(state.deliveryData.id ?? ''),
        );

        context.read<DeliveryStatusChoicesBloc>().add(
          UpdateCustomerStatusEvent(
            deliveryDataId: widget.deliveryDataId,
            status: status,
          ),
        );
        context.read<DeliveryDataBloc>().add(
          WatchLocalDeliveryDataByIdEvent(widget.deliveryDataId),
        );
        return;
      }
    }

    // ---------------- UNDELIVERED ----------------
    if (statusTitle == 'mark as undelivered') {
      Navigator.of(context).pop();

      final state = context.read<DeliveryDataBloc>().state;
      if (state is DeliveryDataLoaded ) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.push(
              '/undeliverable/${widget.deliveryDataId}',
              extra: {'customerId': state.deliveryData, 'statusId': status},
            );
          }
        });
      }
      return;
    }

    // ---------------- END DELIVERY ----------------
    if (statusTitle == 'end delivery') {
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final state = deliveryDataBloc.state;

      if (state is DeliveryDataLoaded) {
        Navigator.of(context).pop();

        deliveryDataBloc.add(CalculateDeliveryTimeEvent(widget.deliveryDataId));
        context.read<DeliveryStatusChoicesBloc>().add(
          SetEndDeliveryEvent(deliveryData: state.deliveryData),
        );
        context.read<DeliveryDataBloc>().add(
          WatchLocalDeliveryDataByIdEvent(widget.deliveryDataId),
        );

        deliveryDataBloc.add(
          SetInvoiceIntoCompletedEvent(state.deliveryData.id ?? ''),
        );
        context.read<DeliveryDataBloc>().add(
          WatchLocalDeliveryDataByIdEvent(widget.deliveryDataId),
        );

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (_) =>
                      CustomerSummaryDialog(deliveryData: state.deliveryData),
            );
          }
        });
        // ---------------- DEFAULT STATUS UPDATE ----------------
      }
      return;
    }

    // ---------------- DEFAULT STATUS UPDATE ----------------
    context.read<DeliveryStatusChoicesBloc>().add(
      UpdateCustomerStatusEvent(
        deliveryDataId: widget.deliveryDataId,
        status: status,
      ),
    );
    context.read<DeliveryDataBloc>().add(
      WatchLocalDeliveryDataByIdEvent(widget.deliveryDataId),
    );
  }

  Future<void> _getCurrentLocationAndUpdate(
    DeliveryDataBloc deliveryDataBloc,
    DeliveryStatusChoicesEntity status,
  ) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _proceedWithStatusUpdate(status);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _proceedWithStatusUpdate(status);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _proceedWithStatusUpdate(status);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      deliveryDataBloc.add(
        UpdateDeliveryLocationEvent(
          id: widget.deliveryDataId,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );

      _proceedWithStatusUpdate(status);
    } catch (_) {
      _proceedWithStatusUpdate(status);
    }
  }

  void _proceedWithStatusUpdate(DeliveryStatusChoicesEntity status) {
    if (!mounted) return;

    context.read<DeliveryStatusChoicesBloc>().add(
      UpdateCustomerStatusEvent(
        deliveryDataId: widget.deliveryDataId,
        status: status,
      ),
    );

    debugPrint('✅ Status update dispatched: ${status.title}');
  }
}
