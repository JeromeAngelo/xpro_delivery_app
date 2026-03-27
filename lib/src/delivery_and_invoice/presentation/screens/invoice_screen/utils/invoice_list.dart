import 'package:flutter/material.dart';

import '../../../../../../core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import '../../../../../../core/common/widgets/list_tiles.dart';

class InvoiceList extends StatelessWidget {
  final DeliveryDataEntity deliveryData;
  final VoidCallback? onTap;
  final VoidCallback? onTapToCancel;

  const InvoiceList({
    super.key,
    required this.deliveryData,
    this.onTap,
    this.onTapToCancel,
  });

  // ✅ Invoice label (ToMany invoices)
  String _invoiceLabel() {
    try {
      final invoices = deliveryData.invoices;
      if (invoices.isEmpty) return 'Invoice';

      // show first invoice refId if available, else name, else id
      final first = invoices.first;
      final ref = (first.refId ?? '').trim();
      if (ref.isNotEmpty) return 'Invoice #$ref';

      final name = (first.name ?? '').trim();
      if (name.isNotEmpty) return 'Invoice #$name';

      final id = (first.id ?? '').trim();
      if (id.isNotEmpty) return 'Invoice #$id';

      return 'Invoice';
    } catch (_) {
      return 'Invoice';
    }
  }

  // ✅ Optional “(x invoices)” display
  String _invoiceCountText() {
    try {
      final count = deliveryData.invoices.length;
      if (count <= 1) return '';
      return '$count invoices';
    } catch (_) {
      return '';
    }
  }

  // ✅ Product count from DeliveryData.invoiceItems
  int _productCount() {
    try {
      return deliveryData.invoiceItems.length;
    } catch (_) {
      return 0;
    }
  }

  // ✅ Status message rules:
  // - if isUnloading == false -> “The delivery is ready”
  // - if isUnloaded == true -> “The items are unloaded”
  // - otherwise -> “Unloading in progress”
  _StatusUI _statusUI(BuildContext context) {
    final isUnloaded = deliveryData.isUnloaded == true;
    final isUnloading = deliveryData.isUnloading == true;

    if (isUnloaded) {
      return _StatusUI(
        text: 'The items are unloaded',
        icon: Icons.check_circle,
        color: Colors.green,
        bg: Colors.green.withOpacity(0.10),
        border: Colors.green.withOpacity(0.30),
      );
    }

    if (!isUnloading) {
      return _StatusUI(
        text: 'The delivery is ready',
        icon: Icons.local_shipping_outlined,
        color: Theme.of(context).colorScheme.primary,
        bg: Theme.of(context).colorScheme.primary.withOpacity(0.10),
        border: Theme.of(context).colorScheme.primary.withOpacity(0.30),
      );
    }

    return _StatusUI(
      text: 'Unloading in progress',
      icon: Icons.hourglass_top_rounded,
      color: Colors.orange,
      bg: Colors.orange.withOpacity(0.10),
      border: Colors.orange.withOpacity(0.30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _invoiceLabel();
    final invoiceCountText = _invoiceCountText();
    final productCount = _productCount();
    final status = _statusUI(context);

    debugPrint('🧾 InvoiceList (clean)');
    debugPrint('   📦 DeliveryData: ${deliveryData.id}');
    debugPrint(
      '   🧾 Invoices: ${(() {
        try {
          return deliveryData.invoices.length;
        } catch (_) {
          return 0;
        }
      })()}',
    );
    debugPrint('   📦 Products(invoiceItems): $productCount');
    debugPrint('   🔄 isUnloading: ${deliveryData.isUnloading}');
    debugPrint('   ✅ isUnloaded: ${deliveryData.isUnloaded}');
    debugPrint('   🏷️ UI Status: ${status.text}');

    return CommonListTiles(
      title: title,
      subtitle:
          '$productCount Products | ${status.text}${invoiceCountText.isNotEmpty ? ' | $invoiceCountText' : ''}',
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.receipt_long,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      trailing: IconButton(
        onPressed: onTapToCancel,
        icon: Icon(
          Icons.cancel_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onTap: onTap,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}

class _StatusUI {
  final String text;
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;

  _StatusUI({
    required this.text,
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
  });
}
