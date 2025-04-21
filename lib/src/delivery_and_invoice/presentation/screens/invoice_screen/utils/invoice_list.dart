import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class InvoiceList extends StatelessWidget {
  final InvoiceEntity invoice;
  final VoidCallback? onTap;

  const InvoiceList({
    super.key,
    required this.invoice,
    this.onTap,
  });

@override
Widget build(BuildContext context) {
  // Get actual product count from the productsList
  final productCount = invoice.productsList.length;

  debugPrint('🎯 Building invoice tile with data:');
  debugPrint('   📝 Invoice #: ${invoice.invoiceNumber}');
  debugPrint('   🏷️ Status: ${invoice.status?.name}');
  debugPrint('   📦 Products Count: $productCount');

  return CommonListTiles(
    title: 'Invoice #${invoice.invoiceNumber}',
    subtitle: '$productCount Products | ${invoice.status?.name.toUpperCase()}',
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Icon(
        Icons.receipt_long,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    trailing: Icon(
      Icons.arrow_forward_ios,
      color: Theme.of(context).colorScheme.onSurface,
    ),
    onTap: onTap,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    backgroundColor: Theme.of(context).colorScheme.surface,
  );
}

}
