import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class TileForTimeline extends StatelessWidget {
  final DeliveryDataEntity deliveryData;
  final bool isLocalTile;
  final DeliveryUpdateEntity? specificUpdate;

  const TileForTimeline({
    super.key,
    required this.deliveryData,
    this.isLocalTile = false,
    this.specificUpdate,
  });

  static DeliveryDataEntity defaultLocalTile(String tripId) => DeliveryDataEntity(
    id: 'start_delivery',
    deliveryNumber: 'START-001',
    customerData: CustomerDataModel(
      name: "Wing An Marketing",
      province: 'Lagundi, Mexico, Pampanga',
      
    ),
    paymentMode: 'Cash',
    created: DateTime.now(),
    updated: DateTime.now(),
    hasTrip: true,
    deliveryUpdatesList: [
      DeliveryUpdateModel(
        title: 'Start Delivery',
        subtitle: 'Trip accepted and delivery started',
        time: DateTime.now(),
        created: DateTime.now(),
        isAssigned: true,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is UserTripLoaded) {
          // Use direct fields from DeliveryDataEntity instead of target
          final storeName = deliveryData.storeName;
          final latestStatus = _getLatestDeliveryStatus();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store,
                            color: Theme.of(context).colorScheme.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            storeName ?? 'No Customer Name',
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _buildAddressString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (latestStatus != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            StatusIcons.getStatusIcon(latestStatus.title ?? ''),
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latestStatus.title ?? 'No Status',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  latestStatus.subtitle ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTime(latestStatus.time ?? DateTime.now()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              Text(
                                _formatDate(latestStatus.time ?? DateTime.now()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  dynamic _getLatestDeliveryStatus() {
    // If we have a specific update, use that
    if (specificUpdate != null) {
      return specificUpdate;
    }
    
    // Otherwise use the latest delivery update
    final deliveryUpdates = deliveryData.deliveryUpdates.toList();
    return deliveryUpdates.isNotEmpty ? deliveryUpdates.last : null;
  }

  String _buildAddressString() {
    final addressParts = <String>[];
    
    if (deliveryData.barangay != null && deliveryData.barangay!.isNotEmpty) {
      addressParts.add(deliveryData.barangay!);
    }
    if (deliveryData.municipality != null && deliveryData.municipality!.isNotEmpty) {
      addressParts.add(deliveryData.municipality!);
    }
    if (deliveryData.province != null && deliveryData.province!.isNotEmpty) {
      addressParts.add(deliveryData.province!);
    }
    
    return addressParts.isNotEmpty 
        ? addressParts.join(', ')
        : 'No address available';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$month/$day/$year';
  }
}
