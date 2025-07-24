import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/widgets/custom_timeline.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/tile_for_timeline.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/tile_for_trip_timeline.dart';

class UpdateTimeline extends StatelessWidget {
  final List<DeliveryDataEntity> deliveries;
  final List<TripUpdateEntity> tripUpdates;

  const UpdateTimeline({
    super.key,
    required this.deliveries,
    required this.tripUpdates,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is UserTripLoaded) {
          debugPrint('📊 Building timeline with ${deliveries.length} deliveries and ${tripUpdates.length} updates');

          final timelineItems = [
            ...deliveries.map((delivery) => TimelineItem(
                  date: _getLatestDeliveryDate(delivery),
                  isCustomer: true,
                  delivery: delivery,
                  tripUpdate: null,
                )),
            ...tripUpdates.map((update) => TimelineItem(
                  date: update.date ?? DateTime.now(),
                  isCustomer: false,
                  delivery: null,
                  tripUpdate: update,
                )),
          ]..sort((a, b) => b.date.compareTo(a.date));

          debugPrint('🔄 Total timeline items: ${timelineItems.length}');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: CustomTimelineTileBuilder.connected(
                  physics: const AlwaysScrollableScrollPhysics(),
                  nodePosition: 0.04,
                  itemCount: timelineItems.length + 1,
                  contentsBuilder: (_, index) {
                    if (index == timelineItems.length) {
                      return TileForTimeline(
                        deliveryData: TileForTimeline.defaultLocalTile(state.trip.id!),
                        isLocalTile: true,
                      );
                    }

                    final item = timelineItems[index];
                    return item.isCustomer
                        ? TileForTimeline(
                            deliveryData: item.delivery!,
                          )
                        : TileForTripTimeline(
                            update: item.tripUpdate!,
                            isFirst: index == 0,
                            isLast: index == timelineItems.length - 1,
                          );
                  },
                  indicatorBuilder: (_, index) {
                    if (index >= timelineItems.length) {
                      return CustomDotIndicator(
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

                    return CustomDotIndicator(
                      color: Theme.of(context).colorScheme.outline,
                      size: item.isCustomer ? 12 : 10,
                    );
                  },
                  connectorBuilder: (_, index, type) {
                    final isLatestItem = index == 0;
                    return CustomDecoratedLineConnector(
                      decoration: BoxDecoration(
                        color: isLatestItem
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  DateTime _getLatestDeliveryDate(DeliveryDataEntity delivery) {
    final deliveryUpdates = delivery.deliveryUpdates.toList();
    if (deliveryUpdates.isNotEmpty) {
      return deliveryUpdates.last.created ?? DateTime.now();
    }
    return delivery.created ?? DateTime.now();
  }
}

class TimelineItem {
  final DateTime date;
  final bool isCustomer;
  final DeliveryDataEntity? delivery;
  final TripUpdateEntity? tripUpdate;

  TimelineItem({
    required this.date,
    required this.isCustomer,
    this.delivery,
    this.tripUpdate,
  });

  @override
  String toString() {
    return 'TimelineItem(date: $date, isCustomer: $isCustomer, '
        'delivery: ${delivery?.id}, tripUpdate: ${tripUpdate?.id})';
  }
}
