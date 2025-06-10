import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timelines/timelines.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';

class DeliveryTimeline extends StatefulWidget {
  final String customerId;
  const DeliveryTimeline({super.key, required this.customerId});

  @override
  State<DeliveryTimeline> createState() => _DeliveryTimelineState();
}

class _DeliveryTimelineState extends State<DeliveryTimeline> {
  @override
  void initState() {
    super.initState();
    _loadLocalTimeline();
  }

  void _loadLocalTimeline() {
    debugPrint('📱 Loading local timeline for delivery: ${widget.customerId}');
    context.read<DeliveryDataBloc>().add(
      GetLocalDeliveryDataByIdEvent(widget.customerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      builder: (context, state) {
        if (state is DeliveryDataLoaded) {
          final statusUpdates = state.deliveryData.deliveryUpdates.toList();

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
                    maxHeight: MediaQuery.of(context).size.height * .9,
                    minHeight: 100,
                  ),
                  child: Timeline.tileBuilder(
                    physics: const NeverScrollableScrollPhysics(),
                    theme: TimelineThemeData(
                      nodePosition: 0.07,
                      color: Theme.of(context).colorScheme.onSurface,
                      indicatorTheme: const IndicatorThemeData(
                        position: 0.5,
                        size: 15.0,
                      ),
                      connectorTheme: const ConnectorThemeData(thickness: 2.0),
                    ),
                    builder: TimelineTileBuilder.connected(
                      connectionDirection: ConnectionDirection.before,
                      itemCount: statusUpdates.length,
                      contentsBuilder: (_, index) {
                        final status = statusUpdates[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Icon(
                                StatusIcons.getStatusIcon(status.title ?? ''),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(status.title ?? ''),
                              subtitle: Text(status.subtitle ?? ''),
                              trailing: Text(
                                _formatDateTime(
                                  status.created ?? DateTime.now(),
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        );
                      },
                      indicatorBuilder: (_, index) {
                        return DotIndicator(
                          color:
                              index == statusUpdates.length - 1
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                        );
                      },
                      connectorBuilder: (_, index, type) {
                        return SolidLineConnector(
                          color:
                              index == statusUpdates.length - 1
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                        );
                      },
                    ),
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
