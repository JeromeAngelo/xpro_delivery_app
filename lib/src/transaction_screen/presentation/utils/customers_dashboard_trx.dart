import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

class CustomersDashboardTrx extends StatelessWidget {
  final DeliveryDataEntity deliveryData;

  const CustomersDashboardTrx({super.key, required this.deliveryData});

  @override
  Widget build(BuildContext context) {
    final storeName = (deliveryData.storeName ?? '').trim();
    final address = (deliveryData.municipality ?? '').trim();
    final mop = (deliveryData.paymentMode ?? '').trim();

    final hasAnyCustomerInfo =
        storeName.isNotEmpty || address.isNotEmpty || mop.isNotEmpty;

    if (!hasAnyCustomerInfo) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔷 TITLE
              Text(
                'Customer Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              /// 🔷 CONTENT
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildLeftColumn(context)),
                    const SizedBox(width: 40),
                    Expanded(child: _buildRightColumn(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔷 LEFT COLUMN
  Widget _buildLeftColumn(BuildContext context) {
    final storeName = (deliveryData.storeName ?? '').trim();
    final address = (deliveryData.municipality ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.store,
          title: "Store Name",
          value: storeName.isEmpty ? 'N/A' : storeName,
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.location_on,
          title: "Address",
          value: address.isEmpty ? 'N/A' : address,
        ),
      ],
    );
  }

  /// 🔷 RIGHT COLUMN
  Widget _buildRightColumn(BuildContext context) {
    final mop = (deliveryData.paymentMode ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.payment,
          title: "Mode of Payment",
          value: mop.isEmpty ? 'N/A' : mop,
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.attach_money,
          title: "Total Amount",
          value: _calculateTotalAmount(),
        ),
      ],
    );
  }

  /// 🔷 TOTAL CALCULATION (NO CHANGE)
  String _calculateTotalAmount() {
    double total = 0.0;

    final invoices = deliveryData.invoices;

    for (final inv in invoices) {
      total += (inv.totalAmount ?? 0.0);
    }

    return '₱${NumberFormat('#,##0.00').format(total)}';
  }

  /// 🔷 INFO ROW (IMPROVED STYLE)
  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
