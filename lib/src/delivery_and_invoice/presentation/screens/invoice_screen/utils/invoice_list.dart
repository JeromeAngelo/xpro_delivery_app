import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

import '../../../../../../core/enums/invoice_status.dart';

class InvoiceList extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final VoidCallback? onTap;

  const InvoiceList({super.key, required this.deliveryData, this.onTap});

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  @override
  Widget build(BuildContext context) {
    // Get invoice data from delivery data relation
    final invoice = widget.deliveryData.invoice.target;
    
    if (invoice == null) {
      debugPrint('⚠️ No invoice data found in delivery data: ${widget.deliveryData.id}');
      return const SizedBox.shrink();
    }

    // Calculate product count from delivery data invoice items
    final productCount = _getProductCount();
    final invoiceStatus = _getInvoiceStatus();

    debugPrint('🎯 Building invoice tile with data:');
    debugPrint('   📝 Invoice #: ${invoice.refId ?? invoice.name}');
    debugPrint('   🏷️ Status: $invoiceStatus');
    debugPrint('   📦 Products Count: $productCount');

    return CommonListTiles(
      title: 'Invoice #${invoice.refId ?? invoice.name ?? 'Unknown'}',
      subtitle: '$productCount Products | ${invoiceStatus.toUpperCase()}',
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

  int _getProductCount() {
    try {
      // Get the count of invoice items from the delivery data
      final invoiceItemsCount = widget.deliveryData.invoiceItems.length;
      
      debugPrint('📊 Invoice Items Analysis:');
      debugPrint('   🔗 Delivery Data ID: ${widget.deliveryData.id}');
      debugPrint('   📦 Invoice Items Count: $invoiceItemsCount');
      
      // Log individual items for debugging
      if (invoiceItemsCount > 0) {
        debugPrint('   📋 Invoice Items Details:');
        for (int i = 0; i < widget.deliveryData.invoiceItems.length; i++) {
          final item = widget.deliveryData.invoiceItems[i];
          debugPrint('     ${i + 1}. ${item.name ?? 'Unknown'} (ID: ${item.id})');
        }
      } else {
        debugPrint('   ⚠️ No invoice items found in delivery data');
      }
      
      return invoiceItemsCount;
    } catch (e) {
      debugPrint('❌ Error getting product count: $e');
      return 0;
    }
  }
String _getInvoiceStatus() {
  try {
    final invoice = widget.deliveryData.invoice.target;
    final itemsCount = widget.deliveryData.invoiceItems.length;
    final invoiceStatus = widget.deliveryData.invoiceStatus;
    
    debugPrint('🏷️ Status Analysis:');
    debugPrint('   💰 Total Amount: ${invoice?.totalAmount}');
    debugPrint('   📦 Items Count: $itemsCount');
    debugPrint('   🚚 Has Trip: ${widget.deliveryData.hasTrip}');
    debugPrint('   📋 Invoice Status: ${invoiceStatus?.name}');
    
    // Check if we have a specific invoice status from delivery data
    if (invoiceStatus != null) {
      switch (invoiceStatus) {
        case InvoiceStatus.none:
          return 'Pending';
        case InvoiceStatus.truck:
          return 'In Transit';
        case InvoiceStatus.unloading:
          return 'Unloading';
        case InvoiceStatus.unloaded:
          return 'Unloaded';
        case InvoiceStatus.delivered:
          return 'Delivered';
        case InvoiceStatus.cancelled:
          return 'Cancelled';
      }
    }
    
    // Fallback to previous logic if no invoice status is set
    // Check if delivery is in progress
    if (widget.deliveryData.hasTrip == true) {
      return 'In Transit';
    }
    
    // Check if invoice has items and amount
    if (itemsCount > 0 && invoice?.totalAmount != null && invoice!.totalAmount! > 0) {
      return 'Ready for Delivery';
    }
    
    // Check if invoice has amount but no items
    if (invoice?.totalAmount != null && invoice!.totalAmount! > 0 && itemsCount == 0) {
      return 'Pending Items';
    }
    
    // Check if invoice has items but no amount
    if (itemsCount > 0 && (invoice?.totalAmount == null || invoice!.totalAmount! <= 0)) {
      return 'Pending Payment';
    }
    
    return 'Draft';
  } catch (e) {
    debugPrint('❌ Error determining invoice status: $e');
    return 'Unknown';
  }
}

}
