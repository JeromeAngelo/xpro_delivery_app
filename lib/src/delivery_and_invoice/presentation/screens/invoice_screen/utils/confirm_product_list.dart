import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';

class ConfirmProductList extends StatelessWidget {
  final InvoiceItemsEntity invoiceItem;

  const ConfirmProductList({super.key, required this.invoiceItem});

  Widget _buildProductHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.inventory_2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoiceItem.name ?? 'No Name',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
              if (invoiceItem.brand != null && invoiceItem.brand!.isNotEmpty)
                Text(
                  'Brand: ${invoiceItem.brand}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (invoiceItem.refId != null && invoiceItem.refId!.isNotEmpty)
                Text(
                  'Ref: ${invoiceItem.refId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySection(BuildContext context) {
    final maxQuantity = (invoiceItem.quantity ?? 0).toInt();
    final baseQuantity = (invoiceItem.totalBaseQuantity ?? maxQuantity).toInt();

    return Padding(
      padding: const EdgeInsets.only(right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            invoiceItem.uom ?? 'UOM',
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              Container(
                width: 80,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  maxQuantity.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text('Quantity', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              Container(
                width: 80,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.1),
                ),
                child: Text(
                  baseQuantity.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Text(
                'Confirmed',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    // final baseQuantity = (invoiceItem.totalBaseQuantity ?? invoiceItem.quantity ?? 0).toInt();
    final unitPrice = invoiceItem.uomPrice ?? 0.0;
    //   final calculatedTotal = baseQuantity * unitPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unit Price', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '₱${unitPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '₱${invoiceItem.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInfo(BuildContext context) {
    final maxQuantity = (invoiceItem.quantity ?? 0).toInt();
    final baseQuantity = (invoiceItem.totalBaseQuantity ?? maxQuantity).toInt();

    if (baseQuantity != maxQuantity) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Delivering $baseQuantity of $maxQuantity items',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProductHeader(context),
            const SizedBox(height: 20),
            _buildQuantitySection(context),
            _buildQuantityInfo(context),
            const SizedBox(height: 16),
            _buildPriceSection(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
