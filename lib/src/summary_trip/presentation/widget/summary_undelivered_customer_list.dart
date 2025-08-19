import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

class SummaryUndeliveredCustomerList extends StatelessWidget {
  final List<CancelledInvoiceEntity> cancelledInvoices;
  final bool isOffline;

  const SummaryUndeliveredCustomerList({
    super.key,
    required this.cancelledInvoices,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOffline) {
      return Column(
        children: [
          _buildOfflineIndicator(),
          const SizedBox(height: 8),
          _buildCancelledInvoiceList(context),
        ],
      );
    }

    return _buildCancelledInvoiceList(context);
  }

  Widget _buildCancelledInvoiceList(BuildContext context) {
    debugPrint(
      '📋 SUMMARY: Processing ${cancelledInvoices.length} cancelled invoices',
    );

    // Filter cancelled invoices that have customer data (undelivered customers)
    final undeliveredInvoices =
        cancelledInvoices.where((invoice) {
          final hasCustomer = invoice.customer.target != null;
          debugPrint(
            '🔍 SUMMARY: Cancelled Invoice ${invoice.id}: has customer = $hasCustomer',
          );
          return hasCustomer;
        }).toList();

    debugPrint(
      '✅ SUMMARY: Found ${undeliveredInvoices.length} undelivered invoices with customers',
    );

    if (undeliveredInvoices.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: undeliveredInvoices.length,
      itemBuilder: (context, index) {
        final cancelledInvoice = undeliveredInvoices[index];

        // Get customer data directly from cancelled invoice entity
        final customer = cancelledInvoice.customer.target;
        final invoices = cancelledInvoice.invoices;

        debugPrint(
          '👤 SUMMARY: Processing customer for cancelled invoice ${cancelledInvoice.id}:',
        );
        debugPrint('   - Customer ID: ${customer?.id}');
        debugPrint('   - Customer Name: ${customer?.name}');
        debugPrint('   - Store Name: ${customer?.ownerName}');
        debugPrint('   - Number of invoices: ${invoices.length}');
        
        // Log individual invoice details
        for (int i = 0; i < invoices.length; i++) {
          final invoice = invoices[i];
          debugPrint('   - Invoice ${i + 1} (${invoice.refId ?? invoice.name}): ₱${NumberFormat('#,##0.00').format(invoice.totalAmount ?? 0.0)}');
        }
        
        debugPrint(
          '   - Reason: ${cancelledInvoice.reason.toString().split('.').last}',
        );
        debugPrint('   - Has Image: ${cancelledInvoice.image != null}');

        // Extract customer information directly from cancelled invoice's customer relation
        final customerName =
            customer?.ownerName ?? customer?.name ?? 'Unknown Customer';
        final storeName = customer?.name ?? customer?.name ?? customerName;

        // Format the reason and date for subtitle
        final reasonText = _formatReasonAndDate(
          cancelledInvoice.reason,
          cancelledInvoice.created,
        );

        debugPrint('📊 SUMMARY: Final display data:');
        debugPrint('   - Store Name: $storeName');
        debugPrint('   - Customer Name: $customerName');
        debugPrint('   - Reason & Date: $reasonText');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CommonListTiles(
            onTap: () {
              context.push(
                '/customer-undelivered-screen/${cancelledInvoice.id}',
              );
            },
            title: storeName,
            subtitle: '${invoices.length} ${invoices.length == 1 ? 'Invoice' : 'Invoices'} • $reasonText',
            leading: CircleAvatar(
              backgroundColor:
                  isOffline
                      ? Colors.orange.withOpacity(0.1)
                      : Theme.of(context).colorScheme.error.withOpacity(0.1),
              child: Icon(
                Icons.cancel_outlined,
                color:
                    isOffline
                        ? Colors.orange
                        : Theme.of(context).colorScheme.error,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOffline)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.offline_bolt,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                // Add image indicator if available
                if (cancelledInvoice.image != null &&
                    cancelledInvoice.image!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.photo_camera,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  ),
                // Add customer status indicator
                if (customer?.ownerName != null &&
                    customer!.ownerName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                  ),
                // Add summary indicator
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.summarize,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 16,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side:
                  isOffline
                      ? BorderSide(color: Colors.orange.withOpacity(0.3))
                      : BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.3),
                      ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            backgroundColor:
                isOffline
                    ? Colors.orange.withOpacity(0.05)
                    : Theme.of(context).colorScheme.error.withOpacity(0.05),
          ),
        );
      },
    );
  }

  String _formatReasonAndDate(UndeliverableReason? reason, DateTime? date) {
    // Format the date
    final dateStr =
        date != null
            ? DateFormat('MMM dd, yyyy').format(date.toLocal())
            : 'No date';

    // Format the reason using the enum
    final formattedReason = _getReasonDisplayName(
      reason ?? UndeliverableReason.none,
    );

    return '$formattedReason - $dateStr';
  }

  String _getReasonDisplayName(UndeliverableReason reason) {
    switch (reason) {
      case UndeliverableReason.storeClosed:
        return 'Store Closed';
      case UndeliverableReason.customerNotAvailable:
        return 'Customer Not Available';
      case UndeliverableReason.environmentalIssues:
        return 'Environmental Issues';
      case UndeliverableReason.wrongInvoice:
        return 'Wrong Invoice';
      case UndeliverableReason.none:
        return 'Unspecified Reason';
    }
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            'Showing offline data',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Undelivered Customers',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All deliveries completed successfully',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
