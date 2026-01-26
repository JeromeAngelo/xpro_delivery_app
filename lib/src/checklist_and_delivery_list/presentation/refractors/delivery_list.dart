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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerInfo(context, delivery),
              const SizedBox(height: 16),
              _buildDeliveryStatus(context, delivery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, DeliveryDataEntity delivery) {
    // Use direct fields from DeliveryDataEntity instead of target
    final storeName = delivery.storeName;
    final refId = delivery.refID;
    final municipality = delivery.municipality;
    final invoiceData = delivery.invoice.target;

    if (storeName == null && refId == null && municipality == null) {
      // Show loading or placeholder if data is still being fetched
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            Icons.store,
            isLoading
                ? 'Loading customer data...'
                : 'Customer data unavailable',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color:
                  isLoading
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (delivery.id != null)
            Text(
              'ID: ${delivery.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          context,
          Icons.store,
          storeName ?? 'No Store Name',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          Icons.receipt_sharp,
          _getInvoiceCountText(delivery),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, Icons.location_on, municipality ?? "Unknown"),
        const SizedBox(height: 8),
        if (invoiceData != null)
          _buildInfoRow(
            context,
            Icons.payments_rounded,
            '₱${invoiceData.totalAmount?.toStringAsFixed(2) ?? "0.00"}',
          ),
      ],
    );
  }

  Widget _buildDeliveryStatus(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    String status = "Pending";

    // Get status from the delivery updates
    if (delivery.deliveryUpdates.isNotEmpty) {
      status = delivery.deliveryUpdates.last.title ?? "Pending";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Status:",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.outline,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  String _getInvoiceCountText(DeliveryDataEntity customer) {
    final invoiceCount = customer.invoices.length;

    if (invoiceCount == 0) {
      return "No Invoices Available";
    } else if (invoiceCount == 1) {
      return "1 Invoice";
    } else {
      return "$invoiceCount Invoices";
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text, {
    TextStyle? style,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: style ?? Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
