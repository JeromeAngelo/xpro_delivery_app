import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/entity/collection_entity.dart';

class FinalCollectionList extends StatelessWidget {
  final List<CollectionEntity> collections;
  final bool isOffline;

  const FinalCollectionList({
    super.key,
    required this.collections,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOffline) {
      return Column(
        children: [
          _buildOfflineIndicator(),
          const SizedBox(height: 8),
          _buildCustomerList(context),
        ],
      );
    }

    return _buildCustomerList(context);
  }

  Widget _buildCustomerList(BuildContext context) {
    debugPrint(
      '📋 CUSTOMER LIST: Processing ${collections.length} collections',
    );

    // Filter collections that have customer data (completed customers)
    final completedCollections =
        collections.where((collection) {
          final hasCustomer = collection.customer.target != null;
          debugPrint(
            '🔍 Collection ${collection.id}: has customer = $hasCustomer',
          );
          return hasCustomer;
        }).toList();

    debugPrint(
      '✅ CUSTOMER LIST: Found ${completedCollections.length} completed collections with customers',
    );

    if (completedCollections.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completedCollections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final collection = completedCollections[index];

        // Get customer data directly from collection entity
        final customer = collection.customer.target;
        final invoices = collection.invoices;

        debugPrint('👤 Processing customer for collection ${collection.id}:');
        debugPrint('   - Customer ID: ${customer?.id}');
        debugPrint('   - Customer Name: ${customer?.name}');
        debugPrint('   - Owner Name: ${customer?.ownerName}');
        debugPrint('   - Number of invoices: ${invoices.length}');
        debugPrint('   - Collection Total: ${collection.totalAmount}');

        // Log individual invoice details
        for (int i = 0; i < invoices.length; i++) {
          final invoice = invoices[i];
          debugPrint(
            '   - Invoice ${i + 1} (${invoice.refId ?? invoice.name}): ₱${NumberFormat('#,##0.00').format(invoice.totalAmount ?? 0.0)}',
          );
        }

        // Extract customer information directly from collection's customer relation
        final customerName =
            customer?.ownerName ?? customer?.name ?? 'Unknown Customer';
        final storeName = customer?.name ?? customerName;

        // Calculate total amount from all invoices
        double totalAmount = 0.0;
        if (invoices.isNotEmpty) {
          for (final invoice in invoices) {
            totalAmount += invoice.totalAmount ?? 0.0;
          }
        }

        // Fallback to collection totalAmount if invoices don't have amounts
        if (totalAmount == 0.0 && collection.totalAmount != null) {
          totalAmount = collection.totalAmount!;
          debugPrint(
            '   🔄 Using collection totalAmount as fallback: ₱${NumberFormat('#,##0.00').format(totalAmount)}',
          );
        }

        debugPrint('📊 Final display data:');
        debugPrint('   - Store Name: $storeName');
        debugPrint('   - Customer Name: $customerName');
        debugPrint(
          '   - Total Amount: ₱${NumberFormat('#,##0.00').format(totalAmount)}',
        );

        return _CustomerListTile(
          storeName: storeName,
          invoiceCount: invoices.length,
          totalAmount: totalAmount,
          index: index,
          isOffline: isOffline,
          onTap: () {
            debugPrint('🔄 Navigating to collection details: ${collection.id}');
            context.push(
              '/final-spec-collection/${collection.id}',
              extra: {
                'collection': collection,
                'customer': customer,
                'invoices': invoices.toList(),
                'isOffline': isOffline,
              },
            );
          },
        );
      },
    );
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
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Completed Customers',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed deliveries will appear here',
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

// ───────────────────────── Private Widgets ─────────────────────────

class _CustomerListTile extends StatelessWidget {
  final String storeName;
  final int invoiceCount;
  final double totalAmount;
  final int index;
  final bool isOffline;
  final VoidCallback onTap;

  const _CustomerListTile({
    required this.storeName,
    required this.invoiceCount,
    required this.totalAmount,
    required this.index,
    required this.isOffline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Light pastel icon backgrounds
    final iconBgColors = [
      const Color(0xFFE3F2FD), // light blue
      const Color(0xFFFFF3E0), // light orange
      const Color(0xFFE8F5E9), // light green
      const Color(0xFFF3E5F5), // light purple
    ];
    final iconColors = [
      const Color(0xFF1565C0), // blue
      const Color(0xFFEF6C00), // orange
      const Color(0xFF2E7D32), // green
      const Color(0xFF6A1B9A), // purple
    ];
    final iconBg = iconBgColors[index % iconBgColors.length];
    final iconFg = iconColors[index % iconColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isOffline ? Colors.orange.withOpacity(0.05) : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isOffline
                    ? Colors.orange.withOpacity(0.3)
                    : colorScheme.outline.withOpacity(0.1),
          ),
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
                color: isOffline ? Colors.orange.withOpacity(0.1) : iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForIndex(index),
                color: isOffline ? Colors.orange : iconFg,
                size: 24,
              ),
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
                    '$invoiceCount Invoice${invoiceCount == 1 ? '' : 's'} • ₱${NumberFormat('#,##0.00').format(totalAmount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    final icons = [
      Icons.storefront_outlined,
      Icons.shopping_basket_outlined,
      Icons.restaurant_outlined,
      Icons.local_grocery_store_outlined,
      Icons.medical_services_outlined,
      Icons.house_outlined,
    ];
    return icons[index % icons.length];
  }
}
