import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
class SummaryUndeliveredCustomerList extends StatelessWidget {
  final List<CancelledInvoiceEntity> cancelledInvoices;

  const SummaryUndeliveredCustomerList({
    super.key,
    required this.cancelledInvoices,
  });

  @override
  Widget build(BuildContext context) {
    // Filter cancelled invoices that have customer data (undelivered customers)
    final undeliveredInvoices = cancelledInvoices.where((invoice) {
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
        final customer = cancelledInvoice.customer.target;
        final invoices = cancelledInvoice.invoices;

        // Extract customer information
        final customerName = customer?.ownerName ?? customer?.name ?? 'Unknown Customer';
        final storeName = customer?.name ?? customerName;

        // Format reason and date
        final reasonText = _formatReasonAndDate(
          cancelledInvoice.reason,
          cancelledInvoice.created,
        );

        debugPrint('📊 SUMMARY: Displaying customer $customerName with $reasonText');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CommonListTiles(
            onTap: () {
              context.push('/customer-undelivered-screen/${cancelledInvoice.id}');
            },
            title: storeName,
            subtitle: '${invoices.length} ${invoices.length == 1 ? 'Invoice' : 'Invoices'} • $reasonText',
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
              child: Icon(
                Icons.cancel_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cancelledInvoice.image != null && cancelledInvoice.image!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.photo_camera,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  ),
                if (customer?.ownerName != null && customer!.ownerName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                  ),
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
              side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.05),
          ),
        );
      },
    );
  }

  String _formatReasonAndDate(UndeliverableReason? reason, DateTime? date) {
    final dateStr = date != null ? DateFormat('MMM dd, yyyy').format(date.toLocal()) : 'No date';
    final formattedReason = _getReasonDisplayName(reason ?? UndeliverableReason.none);
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All deliveries completed successfully',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
