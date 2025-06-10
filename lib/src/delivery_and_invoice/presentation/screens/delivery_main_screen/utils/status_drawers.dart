import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              context.read<DeliveryDataBloc>()
                ..add(GetLocalDeliveryDataByIdEvent(widget.customerId))
                ..add(GetDeliveryDataByIdEvent(widget.customerId));
              Navigator.pop(context);
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

    if (statusTitle.toLowerCase() == 'mark as undelivered') {
      Navigator.pop(context); // Close the modal bottom sheet first

      final customerState = context.read<DeliveryDataBloc>().state;
      if (customerState is DeliveryDataLoaded) {
        context.push(
          '/undeliverable/${widget.customerId}',
          extra: {'customer': customerState.deliveryData, 'statusId': statusId},
        );
      }
      return;
    }

    // Add this new condition for "end delivery"
    if (statusTitle.toLowerCase() == 'end delivery') {
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final customerState = deliveryDataBloc.state;

      if (customerState is DeliveryDataLoaded) {
        final deliveryData = customerState.deliveryData;

        // Calculate total time
        deliveryDataBloc.add(CalculateDeliveryTimeEvent(widget.customerId));

        // Complete delivery
        context.read<DeliveryUpdateBloc>().add(
          CompleteDeliveryEvent(deliveryData: deliveryData),
        );

        Navigator.pop(context); // Close the modal bottom sheet first

        // Show summary dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => CustomerSummaryDialog(deliveryData: deliveryData),
        );
      }
      return;
    }

    if (statusTitle.toLowerCase() == 'unloading') {
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final customerState = deliveryDataBloc.state;

      if (customerState is DeliveryDataLoaded) {
        final deliveryData = customerState.deliveryData;
        context.read<DeliveryDataBloc>().add(
          SetInvoiceIntoUnloadingEvent(deliveryData.id ?? ''),
        );
      }
    }

    context.read<DeliveryUpdateBloc>()
      ..add(
        UpdateDeliveryStatusEvent(
          customerId: widget.customerId,
          statusId: statusId,
        ),
      )
      ..add(LoadLocalDeliveryStatusChoicesEvent(widget.customerId));
  }
}
