import 'package:intl/intl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/src/delivery_monitoring/presentation/widgets/delivery_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerInformationTile extends StatelessWidget {
  const CustomerInformationTile({super.key, required this.deliveryData});
  final DeliveryDataEntity deliveryData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with store name
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            deliveryData.customer?.name ?? 'Unknown Store',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Delivery #: ${deliveryData.deliveryNumber ?? 'N/A'}',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(),
          ),
          const SizedBox(height: 4),

          Text(
            'Trip Number: ${deliveryData.trip!.tripNumberId ?? 'N/A'}',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(),
          ),
          const SizedBox(height: 4),

          Text(
            'Route Name ${deliveryData.trip!.name ?? 'N/A'}',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(),
          ),
          const Divider(height: 32),

          // Customer details
          _buildDetailItem(
            context,
            'Owner',
            deliveryData.customer?.ownerName ?? 'N/A',
            Icons.person,
          ),
          _buildDetailItem(
            context,
            'Contact',
            deliveryData.customer?.contactNumber ?? 'N/A',
            Icons.phone,
          ),
          _buildDetailItem(
            context,
            'Address',
            ' ${deliveryData.customer?.municipality ?? ''}, ${deliveryData.customer?.province ?? ''}',
            Icons.location_on,
          ),
          _buildDetailItem(
            context,
            'Payment Mode',
            deliveryData.customer?.paymentMode ?? 'N/A',
            Icons.payment,
          ),
          _buildDetailItem(
            context,
            'Total Amount',
            _formatCurrency(deliveryData),
            Icons.attach_money,
          ),

          const Divider(height: 32),

          // Delivery status history
          Text(
            'Delivery Status History',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (deliveryData.deliveryUpdates.isEmpty)
            const Text('No status updates available')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deliveryData.deliveryUpdates.length,
              itemBuilder: (context, index) {
                final status = deliveryData.deliveryUpdates[index];
                final statusData = DeliveryStatusData.fromName(
                  status.title ?? 'Unknown',
                );

                return ListTile(
                  leading: Icon(statusData.icon, color: statusData.color),
                  title: Text(
                    status.title ?? 'Unknown Status',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    status.subtitle ?? '',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(),
                  ),
                  trailing: Text(
                    status.time != null ? _formatDateTime(status.time) : '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (deliveryData.trip?.id != null) {
                    context.go('/tripticket/${deliveryData.trip!.id}');
                  }
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Trip Details'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (deliveryData.customer?.id != null) {
                    context.go('/customer/${deliveryData.customer!.id}');
                  }
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Customer Details'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.pop('/delivery-monitoring');
                },
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(DeliveryDataEntity delivery) {
    double totalAmount = 0.0;

    // Calculate total from all invoices if available
    if (delivery.invoices != null && delivery.invoices!.isNotEmpty) {
      totalAmount = delivery.invoices!.fold<double>(
        0.0,
        (sum, invoice) => sum + (invoice.totalAmount ?? 0.0),
      );
    } else if (delivery.invoice?.totalAmount != null) {
      // Fallback to single invoice
      totalAmount = delivery.invoice!.totalAmount!;
    } else {
      return 'N/A';
    }

    // Format with commas and currency symbol
    final formatter = NumberFormat('#,##0.00');
    return '₱${formatter.format(totalAmount)}';
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';

    try {
      // If it's already a DateTime
      if (dateTime is DateTime) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }

      // If it's a String, try to parse it
      if (dateTime is String) {
        final parsedDate = DateTime.tryParse(dateTime);
        if (parsedDate != null) {
          return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}';
        }
        return dateTime; // Return the original string if parsing fails
      }

      // For any other type, convert to string
      return dateTime.toString();
    } catch (e) {
      return '';
    }
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
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
