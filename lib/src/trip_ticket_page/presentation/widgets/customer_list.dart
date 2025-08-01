import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';

class CustomerListTile extends StatelessWidget {
  final List<DeliveryDataEntity> customers;
  final Map<String, DeliveryDataEntity> loadedDeliveryData;
  final bool isLoading;

  const CustomerListTile({
    super.key,
    required this.customers,
    required this.loadedDeliveryData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
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
              'No customers found for this trip',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    // Debug print to check customer data
    debugPrint('📋 Customer list has ${customers.length} items');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];

        // Try to get the fully loaded delivery data if available
        final loadedCustomer =
            customer.id != null && loadedDeliveryData.containsKey(customer.id)
                ? loadedDeliveryData[customer.id]
                : customer;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerInfo(context, loadedCustomer ?? customer),
                const SizedBox(height: 16),
                _buildDeliveryStatus(context, loadedCustomer ?? customer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerInfo(BuildContext context, DeliveryDataEntity customer) {
    // Use direct fields from DeliveryDataEntity instead of target
    final storeName = customer.storeName;
    final refId = customer.refID;
    final municipality = customer.municipality;
    final province = customer.province;
    final invoiceTarget = customer.invoice.target;

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
          if (customer.id != null)
            Text(
              'ID: ${customer.id}',
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
          refId ?? 'No Ref ID',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          Icons.location_on,
          municipality ?? province ?? "Unknown Location",
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          Icons.payments_rounded,
          invoiceTarget?.totalAmount != null 
              ? '₱${invoiceTarget!.totalAmount!.toStringAsFixed(2)}'
              : '₱0.00',
        ),
        // Other fields can be added here
      ],
    );
  }

  Widget _buildDeliveryStatus(
    BuildContext context,
    DeliveryDataEntity customer,
  ) {
    String status = "No Status";

    // Safely get status from the customer object
    try {
      if (customer.deliveryUpdates.isNotEmpty == true) {
        final lastUpdate = customer.deliveryUpdates.last;
        status = lastUpdate.title ?? "No Status";
      }
    } catch (e) {
      debugPrint('⚠️ Error getting delivery status: $e');
      status = "Status Unavailable";
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
