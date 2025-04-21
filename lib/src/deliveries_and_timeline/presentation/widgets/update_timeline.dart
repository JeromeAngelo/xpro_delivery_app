import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timelines/timelines.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/tile_for_timeline.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/tile_for_trip_timeline.dart';

class UpdateTimeline extends StatelessWidget {
  final List<CustomerEntity> customers;
  final List<TripUpdateEntity> tripUpdates;

  const UpdateTimeline({
    super.key,
    required this.customers,
    required this.tripUpdates,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is UserTripLoaded) {
          debugPrint('📊 Building timeline with ${customers.length} customers and ${tripUpdates.length} updates');

          final timelineItems = [
            ...customers.map((customer) => TimelineItem(
                  date: customer.deliveryStatus.lastOrNull?.time ?? DateTime.now(),
                  isCustomer: true,
                  customer: customer,
                  tripUpdate: null,
                )),
            ...tripUpdates.map((update) => TimelineItem(
                  date: update.date ?? DateTime.now(),
                  isCustomer: false,
                  customer: null,
                  tripUpdate: update,
                )),
          ]..sort((a, b) => b.date.compareTo(a.date));

          debugPrint('🔄 Total timeline items: ${timelineItems.length}');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: Timeline.tileBuilder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  theme: TimelineThemeData(
                    nodePosition: 0.04,
                    color: Theme.of(context).colorScheme.onSurface,
                    indicatorTheme: const IndicatorThemeData(
                      position: 0.5,
                      size: 15.0,
                    ),
                    connectorTheme: const ConnectorThemeData(
                      thickness: 2.0,
                    ),
                  ),
                  builder: TimelineTileBuilder.connected(
                    connectionDirection: ConnectionDirection.before,
                    itemCount: timelineItems.length + 1,
                    contentsBuilder: (_, index) {
                      if (index == timelineItems.length) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: TileForTimeline(
                            customer: TileForTimeline.defaultLocalTile(state.trip.id!),
                            isLocalTile: true,
                          ),
                        );
                      }

                      final item = timelineItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: item.isCustomer
                            ? TileForTimeline(
                                customer: item.customer!,
                              )
                            : TileForTripTimeline(
                                update: item.tripUpdate!,
                                isFirst: index == 0,
                                isLast: index == timelineItems.length - 1,
                              ),
                      );
                    },
                    indicatorBuilder: (_, index) {
                      if (index >= timelineItems.length) {
                        return DotIndicator(
                          color: Theme.of(context).colorScheme.outline,
                        );
                      }

                      final isLatestItem = index == 0;
                      final item = timelineItems[index];

                      if (isLatestItem) {
                        return Icon(
                          item.isCustomer
                              ? Icons.local_shipping_rounded
                              : Icons.update,
                          color: Theme.of(context).colorScheme.primary,
                          size: 15,
                        );
                      }

                      return DotIndicator(
                        color: Theme.of(context).colorScheme.outline,
                        size: item.isCustomer ? 12 : 10,
                      );
                    },
                    connectorBuilder: (_, index, type) {
                      final isLatestItem = index == 0;
                      return DecoratedLineConnector(
                        decoration: BoxDecoration(
                          color: isLatestItem
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class TimelineItem {
  final DateTime date;
  final bool isCustomer;
  final CustomerEntity? customer;
  final TripUpdateEntity? tripUpdate;

  TimelineItem({
    required this.date,
    required this.isCustomer,
    this.customer,
    this.tripUpdate,
  });

  @override
  String toString() {
    return 'TimelineItem(date: $date, isCustomer: $isCustomer, '
        'customer: ${customer?.id}, tripUpdate: ${tripUpdate?.id})';
  }
}
