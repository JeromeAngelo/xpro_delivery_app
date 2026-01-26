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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 30),
            _buildDashboardContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Undelivered Summary',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cancelled Invoices Overview',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    if (cancelledInvoices.isEmpty) {
      return _buildEmptyState(context);
    }

    if (isOffline) {
      return Column(
        children: [
          Container(
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
                  'Offline Data',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCancelledInvoiceStats(context),
        ],
      );
    }

    return _buildCancelledInvoiceStats(context);
  }

  Widget _buildCancelledInvoiceStats(BuildContext context) {
    debugPrint('📊 DASHBOARD: Calculating cancelled invoice statistics');
    debugPrint('📊 Total cancelled invoices received: ${cancelledInvoices.length}');

    // Total cancelled invoices count
    final totalCancelledInvoices = cancelledInvoices.length;
    debugPrint('📦 DASHBOARD: Total cancelled invoices count: $totalCancelledInvoices');

    // Find the most common reason
    String mostCommonReason = _getMostCommonReason();
    debugPrint('📋 DASHBOARD: Most common reason: $mostCommonReason');

    // Get latest record date
    String latestRecordDate = _getLatestRecordDate();
    debugPrint('📅 DASHBOARD: Latest record date: $latestRecordDate');

    // Count invoices with images
    final invoicesWithImages = cancelledInvoices.where((invoice) => 
      invoice.image != null && invoice.image!.isNotEmpty
    ).length;
    debugPrint('📷 DASHBOARD: Invoices with images: $invoicesWithImages');

    // Debug summary
    debugPrint('📊 DASHBOARD SUMMARY:');
    debugPrint('   📦 Total Cancelled: $totalCancelledInvoices');
    debugPrint('   📋 Common Reason: $mostCommonReason');
    debugPrint('   📷 With Images: $invoicesWithImages');
    debugPrint('   📅 Latest Date: $latestRecordDate');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      crossAxisSpacing: 5,
      mainAxisSpacing: 22,
      children: [
        _buildInfoItem(
          context,
          Icons.cancel_outlined,
          totalCancelledInvoices.toString(),
          'Total Undelivered',
        ),
        _buildInfoItem(
          context,
          Icons.error_outline,
          mostCommonReason,
          'Common Reason',
        ),
        _buildInfoItem(
          context,
          Icons.photo_camera_outlined,
          invoicesWithImages.toString(),
          'With Evidence',
        ),
        _buildInfoItem(
          context,
          Icons.calendar_today,
          latestRecordDate,
          'Latest Record',
        ),
      ],
    );
  }

  String _getMostCommonReason() {
    if (cancelledInvoices.isEmpty) return 'No Data';

    // Count occurrences of each reason
    final reasonCounts = <UndeliverableReason, int>{};
    
    for (var invoice in cancelledInvoices) {
      final reason = invoice.reason ?? UndeliverableReason.none;
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }

    if (reasonCounts.isEmpty) return 'No Data';

    // Find the most common reason
    var mostCommon = reasonCounts.entries.first;
    for (var entry in reasonCounts.entries) {
      if (entry.value > mostCommon.value) {
        mostCommon = entry;
      }
    }

    // Convert enum to readable string
    return _getReasonDisplayName(mostCommon.key);
  }

  String _getReasonDisplayName(UndeliverableReason reason) {
    switch (reason) {
      case UndeliverableReason.storeClosed:
        return 'Store Closed';
      case UndeliverableReason.customerNotAvailable:
        return 'Customer N/A';
      case UndeliverableReason.environmentalIssues:
        return 'Environmental';
      case UndeliverableReason.wrongInvoice:
        return 'Wrong Invoice';
      case UndeliverableReason.none:
      return 'Unspecified';
    }
  }

  String _getLatestRecordDate() {
    if (cancelledInvoices.isEmpty) return 'No Date';

    // Find the most recent created date
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

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOffline ? Colors.orange.withOpacity(0.3) : Colors.transparent,
        ),
        color: isOffline ? Colors.orange.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Icon(
              icon,
              color: isOffline 
                  ? Colors.orange 
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            'No Undelivered Items',
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
          ),
        ],
      ),
    );
  }
}
