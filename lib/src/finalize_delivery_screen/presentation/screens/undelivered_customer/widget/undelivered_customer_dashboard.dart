import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

class UndeliveredCustomerDashboard extends StatelessWidget {
  final List<CancelledInvoiceEntity> cancelledInvoices;
  final bool isOffline;

  const UndeliveredCustomerDashboard({
    super.key,
    required this.cancelledInvoices,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Undelivered Summary ──
        _buildSectionHeader(
          context,
          title: 'UNDELIVERED SUMMARY',
          trailing: 'Cancelled Invoices Overview',
        ),
        const SizedBox(height: 12),

        // ── Total Undelivered (large card) ──
        _buildTotalUndeliveredCard(context, stats['totalCancelled'] as int),
        const SizedBox(height: 12),

        // ── Two smaller stat cards ──
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: 'With Evidence',
                value: (stats['invoicesWithImages'] as int).toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Latest Record',
                value: stats['latestRecordDate'] as String,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Common Reason (full-width card) ──
        _buildStatCard(
          context,
          label: 'Most Common Reason',
          value: stats['mostCommonReason'] as String,
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ───────────────────────── Stats Calculation ─────────────────────────

  Map<String, dynamic> _calculateStats() {
    debugPrint('📊 DASHBOARD: Calculating cancelled invoice statistics');
    debugPrint(
      '📊 Total cancelled invoices received: ${cancelledInvoices.length}',
    );

    final totalCancelledInvoices = cancelledInvoices.length;
    final mostCommonReason = _getMostCommonReason();
    final latestRecordDate = _getLatestRecordDate();
    final invoicesWithImages =
        cancelledInvoices
            .where(
              (invoice) => invoice.image != null && invoice.image!.isNotEmpty,
            )
            .length;

    debugPrint('📊 DASHBOARD SUMMARY:');
    debugPrint('   📦 Total Cancelled: $totalCancelledInvoices');
    debugPrint('   📋 Common Reason: $mostCommonReason');
    debugPrint('   📷 With Images: $invoicesWithImages');
    debugPrint('   📅 Latest Date: $latestRecordDate');

    return {
      'totalCancelled': totalCancelledInvoices,
      'mostCommonReason': mostCommonReason,
      'invoicesWithImages': invoicesWithImages,
      'latestRecordDate': latestRecordDate,
    };
  }

  String _getMostCommonReason() {
    if (cancelledInvoices.isEmpty) return 'No Data';

    final reasonCounts = <UndeliverableReason, int>{};
    for (var invoice in cancelledInvoices) {
      final reason = invoice.reason ?? UndeliverableReason.none;
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }

    if (reasonCounts.isEmpty) return 'No Data';

    var mostCommon = reasonCounts.entries.first;
    for (var entry in reasonCounts.entries) {
      if (entry.value > mostCommon.value) {
        mostCommon = entry;
      }
    }

    return _getReasonDisplayName(mostCommon.key);
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

  String _getLatestRecordDate() {
    if (cancelledInvoices.isEmpty) return 'No Date';

    DateTime? latestDate;
    for (var invoice in cancelledInvoices) {
      if (invoice.created != null) {
        if (latestDate == null || invoice.created!.isAfter(latestDate)) {
          latestDate = invoice.created;
        }
      }
    }

    if (latestDate != null) {
      return DateFormat('MMM dd, yyyy').format(latestDate.toLocal());
    }

    return 'No Date';
  }

  // ───────────────────────── UI Helpers ─────────────────────────

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String trailing,
    Color? trailingColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
        Text(
          trailing,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color:
                trailingColor ?? theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalUndeliveredCard(BuildContext context, int totalCancelled) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isOffline
                  ? Colors.orange.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Undelivered',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                totalCancelled.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Invoices',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isOffline
                  ? Colors.orange.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
