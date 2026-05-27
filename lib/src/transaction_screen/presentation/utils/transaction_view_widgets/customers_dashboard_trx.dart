import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';

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
    // Use paymentSelection enum for display, fallback to paymentMode string
    final paymentSelection = deliveryData.paymentSelection;
    final String mopDisplay;
    if (paymentSelection != null) {
      mopDisplay = _formatModeOfPayment(paymentSelection);
    } else {
      final paymentMode = (deliveryData.paymentMode ?? '').trim();
      mopDisplay = paymentMode.isEmpty ? 'N/A' : paymentMode;
    }

    // Use totalAmount directly from entity
    final totalAmount = deliveryData.totalAmount;
    final String totalAmountDisplay =
        (totalAmount != null && totalAmount > 0)
            ? _formatCurrency(totalAmount)
            : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.payment,
          title: "Mode of Payment",
          value: mopDisplay,
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.attach_money,
          title: "Total Amount",
          value: totalAmountDisplay,
        ),
      ],
    );
  }

  /// 🔷 FORMAT MODE OF PAYMENT FROM ENUM
  String _formatModeOfPayment(ModeOfPayment mode) {
    switch (mode) {
      case ModeOfPayment.bankTransfer:
        return 'Bank Transfer';
      case ModeOfPayment.cashOnDelivery:
        return 'DTC - COD';
      case ModeOfPayment.dtcCheque:
        return 'DTC - CHK';
      case ModeOfPayment.eWallet:
        return 'E-Wallet';
      case ModeOfPayment.stcCash:
        return 'STC-Cash';
      case ModeOfPayment.stcCheque:
        return 'STC-CHK';
    }
  }

  /// 🔷 FORMAT CURRENCY WITH THOUSAND SEPARATORS
  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Add commas to integer part
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    return '₱${buffer.toString()}.$decimalPart';
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
