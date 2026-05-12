import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

class DeliveryList extends StatelessWidget {
  final List<DeliveryDataEntity> deliveries;
  final Map<String, dynamic> loadedDeliveryData;
  final bool isLoading;

  const DeliveryList({
    super.key,
    required this.deliveries,
    required this.loadedDeliveryData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 Building DeliveryList with ${deliveries.length} items');

    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No deliveries found for this trip',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];

        // Try to get the fully loaded delivery data if available
        DeliveryDataEntity displayDelivery = delivery;
        if (delivery.id != null &&
            loadedDeliveryData.containsKey(delivery.id)) {
          final loadedDelivery = loadedDeliveryData[delivery.id];
          if (loadedDelivery is DeliveryDataEntity) {
            displayDelivery = loadedDelivery;
          }
        }

        return _buildDeliveryCard(context, displayDelivery);
      },
    );
  }

  Widget _buildDeliveryCard(BuildContext context, DeliveryDataEntity delivery) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeliveryHeader(context, delivery),
              const SizedBox(height: 12),
              _buildDeliveryFooter(context, delivery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryHeader(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    final storeName = delivery.storeName;
    final municipality = delivery.municipality;
    final province = delivery.province;

    // Format location
    String location = 'Unknown Location';
    if (municipality != null && province != null) {
      location = '$province - $municipality';
    } else if (province != null) {
      location = province;
    } else if (municipality != null) {
      location = municipality;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store icon with red/orange background
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.store,
            color: Theme.of(context).colorScheme.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        // Store info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName ?? 'No Store Name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryFooter(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    final invoiceCount = delivery.invoices.length;
    final municipality = delivery.municipality;
    final province = delivery.province;

    // Format location (just province for footer)
    String location = province ?? municipality ?? 'Unknown';

    // Get status
    String status = "Pending";
    try {
      if (delivery.deliveryUpdates.isNotEmpty == true) {
        final lastUpdate = delivery.deliveryUpdates.last;
        status = lastUpdate.title ?? "Pending";
      }
    } catch (e) {
      debugPrint('⚠️ Error getting delivery status: $e');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      child: Row(
        children: [
          // Invoice count
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    invoiceCount == 0
                        ? 'No Invoices'
                        : invoiceCount == 1
                        ? '1 Invoice'
                        : '$invoiceCount Invoices',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Location
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pending_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
