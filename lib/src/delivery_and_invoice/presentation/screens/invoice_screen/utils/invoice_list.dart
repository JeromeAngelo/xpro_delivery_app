import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';

class InvoiceList extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final InvoiceDataModel invoice;
  final VoidCallback? onTap;

  const InvoiceList({
    super.key, 
    required this.deliveryData, 
    required this.invoice,
    this.onTap,
  });

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  InvoiceStatus? _cachedInvoiceStatus;

  @override
  void initState() {
    super.initState();
    _loadInvoiceStatus();
  }

  void _loadInvoiceStatus() {
    if (widget.invoice.id != null) {
      debugPrint('📡 Loading invoice status for invoice: ${widget.invoice.id}');
      context.read<InvoiceStatusBloc>().add(
        GetInvoiceStatusByInvoiceIdEvent(widget.invoice.id!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the passed invoice directly
    final invoice = widget.invoice;

    // Debug: Check data structure
    _debugDataStructure();

    // Calculate product count from delivery data invoice items
    final productCount = _getProductCount();

    debugPrint('🎯 Building invoice tile with data:');
    debugPrint('   📝 Invoice ID: ${invoice.id}');
    debugPrint('   📝 Invoice #: ${invoice.refId ?? invoice.name}');
    debugPrint('   📦 Products Count: $productCount');

    return BlocListener<InvoiceStatusBloc, InvoiceStatusState>(
      listener: (context, state) {
        if (state is InvoiceStatusByInvoiceIdLoaded && 
            state.invoiceId == widget.invoice.id) {
          // Cache the status from the first record (if any)
          if (state.invoiceStatus.isNotEmpty) {
            setState(() {
              _cachedInvoiceStatus = state.invoiceStatus.first.tripStatus;
            });
            debugPrint('✅ Invoice status loaded: ${_cachedInvoiceStatus?.name}');
          }
        }
      },
      child: BlocBuilder<InvoiceStatusBloc, InvoiceStatusState>(
        builder: (context, state) {
          // Determine invoice status to display
          String invoiceStatusText = _getInvoiceStatusText();

          return CommonListTiles(
            title: 'Invoice #${invoice.refId ?? invoice.name ?? 'Unknown'}',
            subtitle: '$productCount Products | ${invoiceStatusText.toUpperCase()}',
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state is InvoiceStatusLoading && 
                    (state is InvoiceStatusByInvoiceIdLoaded ? 
                     (state as InvoiceStatusByInvoiceIdLoaded).invoiceId == widget.invoice.id : false))
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            onTap: widget.onTap,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
    );
  }

  int _getProductCount() {
    try {
      // Try multiple approaches to get the correct count
      debugPrint('📊 Invoice Items Analysis - Starting multiple approaches:');
      debugPrint('   🔗 Invoice ID: ${widget.invoice.id}');
      debugPrint('   🔗 Delivery Data ID: ${widget.deliveryData.id}');
      
      // Approach 1: Filter from delivery data invoice items
      final invoiceSpecificItemsCount = _getInvoiceSpecificItemsCount();
      debugPrint('   📦 Approach 1 (Filtered from delivery): $invoiceSpecificItemsCount items');
      
      // Approach 2: Try to get count from invoice itself (fallback)
      int fallbackCount = 0;
      // If the invoice-specific filtering didn't work, we might need a fallback
      if (invoiceSpecificItemsCount == 0 && widget.deliveryData.invoiceItems.isNotEmpty) {
        // Check if this is the primary invoice (first one in the list)
        final allInvoices = widget.deliveryData.invoices;
        if (allInvoices.isNotEmpty) {
          final isFirstInvoice = allInvoices.first.id == widget.invoice.id;
          if (isFirstInvoice && allInvoices.length == 1) {
            // If there's only one invoice, assume all items belong to it
            fallbackCount = widget.deliveryData.invoiceItems.length;
            debugPrint('   📦 Approach 2 (Single invoice fallback): $fallbackCount items');
          } else if (allInvoices.length > 1) {
            // Multiple invoices: distribute items evenly as fallback
            fallbackCount = (widget.deliveryData.invoiceItems.length / allInvoices.length).ceil();
            debugPrint('   📦 Approach 2 (Multi-invoice distribution): $fallbackCount items');
          }
        }
      }
      
      final finalCount = invoiceSpecificItemsCount > 0 ? invoiceSpecificItemsCount : fallbackCount;
      debugPrint('   ✅ Final count: $finalCount items');
      
      return finalCount;
    } catch (e) {
      debugPrint('❌ Error getting product count: $e');
      return 0;
    }
  }

  int _getInvoiceSpecificItemsCount() {
    try {
      debugPrint('🔍 Debug: Starting invoice-specific items analysis');
      debugPrint('   🎯 Target Invoice ID: ${widget.invoice.id}');
      debugPrint('   📦 Total Invoice Items in Delivery: ${widget.deliveryData.invoiceItems.length}');
      
      // Debug: Log all invoice items and their relations
      debugPrint('   📋 All Invoice Items in Delivery:');
      for (int i = 0; i < widget.deliveryData.invoiceItems.length; i++) {
        final item = widget.deliveryData.invoiceItems[i];
        debugPrint('     ${i + 1}. Item: ${item.name ?? 'Unknown'} (ID: ${item.id})');
        debugPrint('         - Related Invoice ID: ${item.invoiceData.target?.id ?? 'NULL'}');
        debugPrint('         - Invoice Relation Exists: ${item.invoiceData.target != null}');
        debugPrint('         - Raw Invoice Data ID: ${item.invoiceDataId ?? 'NULL'}');
        
        // Check if the item has any reference to our target invoice
        final targetInvoiceId = widget.invoice.id;
        if (item.invoiceDataId == targetInvoiceId) {
          debugPrint('         - ✅ MATCH FOUND via invoiceDataId!');
        }
        if (item.invoiceData.target?.id == targetInvoiceId) {
          debugPrint('         - ✅ MATCH FOUND via invoiceData.target!');
        }
      }
      
      // Filter invoice items that belong to this specific invoice
      final invoiceSpecificItems = widget.deliveryData.invoiceItems
          .where((item) {
            final itemInvoiceId = item.invoiceData.target?.id;
            final rawInvoiceDataId = item.invoiceDataId;
            final targetInvoiceId = widget.invoice.id;
            
            debugPrint('🔍 Comparing:');
            debugPrint('   - Item Invoice ID (via target): "$itemInvoiceId"');
            debugPrint('   - Item Invoice ID (via rawId): "$rawInvoiceDataId"');
            debugPrint('   - Target Invoice ID: "$targetInvoiceId"');
            
            // Check both the relation target and the direct ID field
            final matchesTarget = itemInvoiceId == targetInvoiceId;
            final matchesRawId = rawInvoiceDataId == targetInvoiceId;
            
            debugPrint('   - Matches via target: $matchesTarget');
            debugPrint('   - Matches via rawId: $matchesRawId');
            
            return matchesTarget || matchesRawId;
          })
          .toList();
      
      debugPrint('📊 Invoice-Specific Items Analysis:');
      debugPrint('   🎯 Target Invoice ID: ${widget.invoice.id}');
      debugPrint('   📦 Total Invoice Items in Delivery: ${widget.deliveryData.invoiceItems.length}');
      debugPrint('   📦 Items for this Invoice: ${invoiceSpecificItems.length}');
      
      // Log individual matching items for debugging
      if (invoiceSpecificItems.isNotEmpty) {
        debugPrint('   📋 Matching Invoice-Specific Items Details:');
        for (int i = 0; i < invoiceSpecificItems.length; i++) {
          final item = invoiceSpecificItems[i];
          debugPrint('     ${i + 1}. ${item.name ?? 'Unknown'} (ID: ${item.id})');
          debugPrint('         - Quantity: ${item.quantity}');
          debugPrint('         - Total Amount: ${item.totalAmount}');
        }
      } else {
        debugPrint('   ⚠️ No items found for this specific invoice');
        debugPrint('   🔍 This might indicate:');
        debugPrint('      - Invoice items are not properly related to invoices');
        debugPrint('      - Data is not properly expanded when fetching');
        debugPrint('      - Invoice items belong to a different invoice ID');
      }
      
      return invoiceSpecificItems.length;
    } catch (e) {
      debugPrint('❌ Error getting invoice-specific items count: $e');
      return 0;
    }
  }
  void _debugDataStructure() {
    debugPrint('🔍 Data Structure Debug:');
    debugPrint('   📊 Delivery Data ID: ${widget.deliveryData.id}');
    debugPrint('   📊 Delivery Data has ${widget.deliveryData.invoices.length} invoices');
    debugPrint('   📊 Delivery Data has ${widget.deliveryData.invoiceItems.length} invoice items');
    
    // Log all invoices in this delivery
    debugPrint('   📋 All Invoices in Delivery:');
    for (int i = 0; i < widget.deliveryData.invoices.length; i++) {
      final inv = widget.deliveryData.invoices[i];
      debugPrint('     ${i + 1}. Invoice: ${inv.refId ?? inv.name} (ID: ${inv.id})');
    }
    
    debugPrint('   🎯 Current Invoice: ${widget.invoice.refId ?? widget.invoice.name} (ID: ${widget.invoice.id})');
  }

String _getInvoiceStatusText() {
  try {
    final invoice = widget.invoice;
    final itemsCount = _getInvoiceSpecificItemsCount();
    
    debugPrint('🏷️ Status Analysis:');
    debugPrint('   💰 Total Amount: ${invoice.totalAmount}');
    debugPrint('   📦 Items Count: $itemsCount');
    debugPrint('   🚚 Has Trip: ${widget.deliveryData.hasTrip}');
    debugPrint('   📋 Cached Invoice Status: ${_cachedInvoiceStatus?.name}');
    debugPrint('   📋 Delivery Invoice Status: ${widget.deliveryData.invoiceStatus?.name}');
    
    // Priority 1: Use cached status from InvoiceStatusBloc (most accurate)
    if (_cachedInvoiceStatus != null) {
      switch (_cachedInvoiceStatus!) {
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
    
    // Priority 2: Use delivery data invoice status
    final deliveryInvoiceStatus = widget.deliveryData.invoiceStatus;
    if (deliveryInvoiceStatus != null) {
      switch (deliveryInvoiceStatus) {
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
    
    // Priority 3: Fallback logic based on delivery state
    if (widget.deliveryData.hasTrip == true) {
      return 'In Transit';
    }
    
    // Priority 4: Status based on invoice content
    if (itemsCount > 0 && invoice.totalAmount != null && invoice.totalAmount! > 0) {
      return 'Ready for Delivery';
    }
    
    if (invoice.totalAmount != null && invoice.totalAmount! > 0 && itemsCount == 0) {
      return 'Pending Items';
    }
    
    if (itemsCount > 0 && (invoice.totalAmount == null || invoice.totalAmount! <= 0)) {
      return 'Pending Payment';
    }
    
    return 'Draft';
  } catch (e) {
    debugPrint('❌ Error determining invoice status: $e');
    return 'Unknown';
  }
}

}
