import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/widgets/custom_timeline.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
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

          final timelineItems = <TimelineItem>[];
          
          // Add individual delivery updates as separate timeline items
          for (final delivery in deliveries) {
            final deliveryUpdates = delivery.deliveryUpdates.toList();
            for (final deliveryUpdate in deliveryUpdates) {
              // Prioritize time field, then created, then updated, then current time
              final updateDate = deliveryUpdate.time ?? 
                deliveryUpdate.created ?? 
                deliveryUpdate.updated ?? 
                DateTime.now();
              
              debugPrint('📦 DELIVERY UPDATE: ${deliveryUpdate.title} - Date: $updateDate');
              
              timelineItems.add(TimelineItem(
                date: updateDate,
                isCustomer: true,
                delivery: delivery,
                tripUpdate: null,
                deliveryUpdate: deliveryUpdate,
              ));
            }
          }
          
          // Add trip updates as separate timeline items
          for (final update in tripUpdates) {
            final updateDate = update.date ?? DateTime.now();
            
            debugPrint('🚛 TRIP UPDATE: ${update.status?.name ?? 'Unknown'} - Date: $updateDate');
            
            timelineItems.add(TimelineItem(
              date: updateDate,
              isCustomer: false,
              delivery: null,
              tripUpdate: update,
              deliveryUpdate: null,
            ));
          }
          
          // Sort all items by date (latest first) - mix delivery and trip updates chronologically
          timelineItems.sort((a, b) {
            final comparison = b.date.compareTo(a.date);
            debugPrint('🔄 SORTING: ${a.isCustomer ? 'DELIVERY' : 'TRIP'} (${a.date}) vs ${b.isCustomer ? 'DELIVERY' : 'TRIP'} (${b.date}) = $comparison');
            return comparison;
          });

          debugPrint('🔄 Total timeline items: ${timelineItems.length}');
          
          // Debug: Print final sorted order
          debugPrint('📋 FINAL TIMELINE ORDER (latest first):');
          for (int i = 0; i < timelineItems.length; i++) {
            final item = timelineItems[i];
            final type = item.isCustomer ? 'DELIVERY' : 'TRIP';
            final title = item.isCustomer 
                ? (item.deliveryUpdate?.title ?? 'Unknown Delivery')
                : (item.tripUpdate?.status?.name ?? 'Unknown Trip');
            debugPrint('   ${i + 1}. [$type] $title - ${item.date}');
          }

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
                            specificUpdate: item.deliveryUpdate,
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


}

class TimelineItem {
  final DateTime date;
  final bool isCustomer;
  final DeliveryDataEntity? delivery;
  final TripUpdateEntity? tripUpdate;
  final DeliveryUpdateEntity? deliveryUpdate;

  TimelineItem({
    required this.date,
    required this.isCustomer,
    this.delivery,
    this.tripUpdate,
    this.deliveryUpdate,
  });

  @override
  String toString() {
    return 'TimelineItem(date: $date, isCustomer: $isCustomer, '
        'delivery: ${delivery?.id}, tripUpdate: ${tripUpdate?.id}, deliveryUpdate: ${deliveryUpdate?.id})';
  }
}
