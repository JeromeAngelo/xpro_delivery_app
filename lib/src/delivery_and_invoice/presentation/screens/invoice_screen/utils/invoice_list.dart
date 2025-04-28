import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class InvoiceList extends StatefulWidget {
  final InvoiceEntity invoice;
  final VoidCallback? onTap;

  const InvoiceList({super.key, required this.invoice, this.onTap});

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  @override
  Widget build(BuildContext context) {
    // Get actual product count from the productsList
    final productCount = widget.invoice.productsList.length;

    debugPrint('🎯 Building invoice tile with data:');
    debugPrint('   📝 Invoice #: ${widget.invoice.invoiceNumber}');
    debugPrint('   🏷️ Status: ${widget.invoice.status?.name}');
    debugPrint('   📦 Products Count: $productCount');

    return CommonListTiles(
      title: 'Invoice #${widget.invoice.invoiceNumber}',
      subtitle:
          '$productCount Products | ${widget.invoice.status?.name.toUpperCase()}',
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
      onTap: widget.onTap,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
