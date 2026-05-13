import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: undeliveredInvoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cancelledInvoice = undeliveredInvoices[index];
        final customer = cancelledInvoice.customer.target;
        final invoices = cancelledInvoice.invoices;

        // Extract customer information
        final customerName =
            customer?.ownerName ?? customer?.name ?? 'Unknown Customer';
        final storeName = customer?.name ?? customerName;

        // Format reason and date
        final reasonText = _formatReasonAndDate(
          cancelledInvoice.reason,
          cancelledInvoice.created,
        );

        debugPrint(
          '📊 SUMMARY: Displaying customer $customerName with $reasonText',
        );

        return _CustomerListTile(
          storeName: storeName,
          invoiceCount: invoices.length,
          reasonText: reasonText,
          index: index,
          hasImage:
              cancelledInvoice.image != null &&
              cancelledInvoice.image!.isNotEmpty,
          onTap: () {
            context.push('/customer-undelivered-screen/${cancelledInvoice.id}');
          },
        );
      },
    );
  }

  String _formatReasonAndDate(UndeliverableReason? reason, DateTime? date) {
    final dateStr =
        date != null
            ? DateFormat('MMM dd, yyyy').format(date.toLocal())
            : 'No date';
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
      case UndeliverableReason.noPaymentAvailable:
        return 'No Payment Available';
      case UndeliverableReason.other:
        return 'Other';
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

// ───────────────────────── Private Widgets ─────────────────────────

class _CustomerListTile extends StatelessWidget {
  final String storeName;
  final int invoiceCount;
  final String reasonText;
  final int index;
  final bool hasImage;
  final VoidCallback onTap;

  const _CustomerListTile({
    required this.storeName,
    required this.invoiceCount,
    required this.reasonText,
    required this.index,
    required this.hasImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Light pastel icon backgrounds (error-themed for undelivered)
    final iconBgColors = [
      const Color(0xFFFFEBEE), // light red
      const Color(0xFFFFF3E0), // light orange
      const Color(0xFFF3E5F5), // light purple
      const Color(0xFFE3F2FD), // light blue
    ];
    final iconColors = [
      const Color(0xFFC62828), // red
      const Color(0xFFEF6C00), // orange
      const Color(0xFF6A1B9A), // purple
      const Color(0xFF1565C0), // blue
    ];
    final iconBg = iconBgColors[index % iconBgColors.length];
    final iconFg = iconColors[index % iconColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon in rounded square
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.cancel_outlined, color: iconFg, size: 24),
            ),
            const SizedBox(width: 14),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName.toUpperCase(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$invoiceCount Invoice${invoiceCount == 1 ? '' : 's'} • $reasonText',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Trailing indicators + Chevron
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.photo_camera,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                  ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withOpacity(0.3),
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
