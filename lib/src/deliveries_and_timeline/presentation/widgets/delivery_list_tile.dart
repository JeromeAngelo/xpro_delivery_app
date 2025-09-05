import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';

class DeliveryListTile extends StatelessWidget {
  final DeliveryDataEntity delivery;
  final VoidCallback? onTap;
  final bool isFromLocal;
   final bool selectionMode;
  final VoidCallback? onLongPress;
   final ValueChanged<bool> onSelectionChanged;
 final bool isSelected;
  const DeliveryListTile({
    super.key,
    required this.delivery,
    required this.isFromLocal,
    this.onTap,
     required this.selectionMode,
    this.onLongPress,
     required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Use direct fields from DeliveryDataEntity instead of target
    final storeName = delivery.storeName;
    final municipality = delivery.municipality;
    final invoices = delivery.invoices;

    // ADDED: Show shimmer loading when customer data is null
    if (storeName == null && municipality == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Shimmer avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shimmer store name
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Shimmer address
                        Container(
                          height: 14,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Shimmer arrow
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              Row(
                children: [
                  // Shimmer status label
                  Container(
                    height: 14,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Shimmer status value
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              if (delivery.paymentMode != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Shimmer payment label
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Shimmer payment value
                    Container(
                      height: 14,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Shimmer payment label
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Shimmer payment value
                    Container(
                      height: 14,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            // Pre-load delivery data to local storage
            if (delivery.id != null) {
              context.read<DeliveryDataBloc>().add(
                GetLocalDeliveryDataByIdEvent(delivery.id!),
              );
            }
      
            // Navigate after ensuring data is in local storage
            if (delivery.id != null) {
              context.pushReplacement(
                '/delivery-and-invoice/${delivery.id}',
                extra: delivery,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.store,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName ?? 'No Store Name',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${invoices.length} ${invoices.length == 1 ? 'Invoice' : 'Invoices'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            municipality ?? 'No Address',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    selectionMode
            ? Checkbox(
                value: isSelected, // default unchecked
                 onChanged: (val) {
                          if (val != null) {
                            onSelectionChanged(val);
                          }
                        }, // leave null for now
              )
            : Icon(Icons.arrow_forward_ios), // your original trailing icon
      
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getDeliveryStatus(delivery),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
               
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get the delivery status
  String _getDeliveryStatus(DeliveryDataEntity delivery) {
    // Check if we have delivery updates
    if (delivery.deliveryUpdates.isNotEmpty) {
      // Get the last update
      final lastUpdate = delivery.deliveryUpdates.lastOrNull;
      if (lastUpdate != null && lastUpdate.title != null) {
        return lastUpdate.title!;
      }
    }

    // Default status if no updates are available
    return 'Pending';
  }
}
