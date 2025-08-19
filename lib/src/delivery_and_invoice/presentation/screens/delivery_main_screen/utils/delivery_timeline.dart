import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/widgets/custom_timeline.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';

class DeliveryTimeline extends StatefulWidget {
  final String customerId;
  const DeliveryTimeline({super.key, required this.customerId});

  @override
  State<DeliveryTimeline> createState() => _DeliveryTimelineState();
}

class _DeliveryTimelineState extends State<DeliveryTimeline> {
  DeliveryDataState? _cachedState;

  @override
  void initState() {
    super.initState();
    // Data loading is handled by the parent screen/router
    // No need to load data again here to prevent multiple loading states
    debugPrint('📱 DeliveryTimeline: Initialized for customer: ${widget.customerId}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryDataBloc, DeliveryDataState>(
      listenWhen: (previous, current) =>
          current is DeliveryDataLoaded ||
          current is DeliveryDataError ||
          current is InvoiceSetToUnloading ||
          current is InvoiceSetToUnloaded,
      listener: (context, state) {
        if (mounted) {
          setState(() {
            _cachedState = state;
          });
        }
      },
      buildWhen: (previous, current) =>
          current is DeliveryDataLoaded ||
          current is DeliveryDataError ||
          current is InvoiceSetToUnloading ||
          current is InvoiceSetToUnloaded ||
          // Only show loading if we have no cached data at all  
          (current is DeliveryDataLoading && _cachedState == null),
      builder: (context, state) {
        debugPrint('📱 Timeline: Building with state: ${state.runtimeType}');
        
        // Prioritize cached data for offline-first approach
        final effectiveState = _cachedState ?? state;

        if (effectiveState is DeliveryDataLoaded && 
            effectiveState.deliveryData.id != null) {
          debugPrint('📱 Timeline: Using loaded data with ID: ${effectiveState.deliveryData.id}');
          final statusUpdates = effectiveState.deliveryData.deliveryUpdates.toList();

          if (statusUpdates.isEmpty) {
            return const SizedBox();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 1.1,
                    minHeight: 100,
                  ),
                  child: CustomTimelineTileBuilder.connected(
                    physics: const NeverScrollableScrollPhysics(),
                    nodePosition: 0.07,
                  
                    itemCount: statusUpdates.length,
                    contentsBuilder: (_, index) {
                      final status = statusUpdates[index];
                      return Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              StatusIcons.getStatusIcon(status.title ?? ''),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              status.title ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              status.subtitle ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _formatDateTime(status.time ?? DateTime.now()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      );
                    },
                    indicatorBuilder: (_, index) {
                      return CustomDotIndicator(
                        color:
                            index == statusUpdates.length - 1
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                      );
                    },
                    connectorBuilder: (_, index, type) {
                      return CustomSolidLineConnector(
                        color:
                            index == statusUpdates.length - 1
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }
}
