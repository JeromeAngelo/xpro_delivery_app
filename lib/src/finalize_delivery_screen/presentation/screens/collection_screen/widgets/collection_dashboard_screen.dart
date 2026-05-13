import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/entity/collection_entity.dart';

class CollectionDashboardScreen extends StatelessWidget {
  final List<CollectionEntity> collections;
  final bool isOffline;
  final String? tripId;

  const CollectionDashboardScreen({
    super.key,
    required this.collections,
    this.isOffline = false,
    this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Collection Summary ──
        _buildSectionHeader(
          context,
          title: 'COLLECTION SUMMARY',
          trailing: 'ID: #${collections.first.trip.target?.name ?? 'FL-0000'}',
        ),
        const SizedBox(height: 12),

        // ── Total Collections (large card) ──
        _buildTotalCollectionsCard(context, stats['totalAmount'] as double),
        const SizedBox(height: 12),

        // ── Two smaller stat cards ──
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Total Invoices',
                value: (stats['totalInvoices'] as int).toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Date Completed',
                value: stats['completionDate'] as String,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ───────────────────────── Helpers ─────────────────────────

  Map<String, dynamic> _calculateStats() {
    double totalAmount = 0.0;
    int totalInvoices = 0;

    for (final collection in collections) {
      final invoices = collection.invoices;
      totalInvoices += invoices.length;

      double collectionAmount = 0.0;
      for (final invoice in invoices) {
        collectionAmount += invoice.totalAmount ?? 0.0;
      }
      if (collectionAmount == 0.0 && collection.totalAmount != null) {
        collectionAmount = collection.totalAmount!;
      }
      totalAmount += collectionAmount;
    }

    String completionDate = 'Today';
    if (collections.isNotEmpty &&
        collections.first.trip.target?.timeAccepted != null) {
      completionDate = DateFormat(
        'MMM dd, yyyy',
      ).format(collections.first.trip.target!.timeAccepted!.toLocal());
    }

    return {
      'totalAmount': totalAmount,
      'totalInvoices': totalInvoices,
      'totalCollections': collections.length,
      'completionDate': completionDate,
    };
  }

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

  Widget _buildTotalCollectionsCard(BuildContext context, double totalAmount) {
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
            'Total Collections',
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
                '₱${NumberFormat('#,##0.00').format(totalAmount)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'PHP',
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
