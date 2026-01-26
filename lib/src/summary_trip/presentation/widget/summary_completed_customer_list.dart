import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';
class SummaryCompletedCustomerList extends StatelessWidget {
  final List<CollectionEntity> collections;

  const SummaryCompletedCustomerList({
    super.key,
    required this.collections,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCustomerList(context);
  }

  Widget _buildCustomerList(BuildContext context) {
    debugPrint('📋 CUSTOMER LIST: Processing ${collections.length} collections');

    // Filter collections that have customer data (completed customers)
    final completedCollections = collections.where((collection) {
      final hasCustomer = collection.customer.target != null;
      debugPrint('🔍 Collection ${collection.id}: has customer = $hasCustomer');
      return hasCustomer;
    }).toList();

    debugPrint(
      '✅ CUSTOMER LIST: Found ${completedCollections.length} completed collections with customers',
    );

    if (completedCollections.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completedCollections.length,
      itemBuilder: (context, index) {
        final collection = completedCollections[index];

        final customer = collection.customer.target;
        final invoices = collection.invoices;

        debugPrint('👤 Processing customer for collection ${collection.id}:');
        debugPrint('   - Customer ID: ${customer?.id}');
        debugPrint('   - Customer Name: ${customer?.name}');
        debugPrint('   - Owner Name: ${customer?.ownerName}');
        debugPrint('   - Number of invoices: ${invoices.length}');
        debugPrint('   - Collection Total: ${collection.totalAmount}');

        // Calculate total amount
        double totalAmount = 0.0;
        for (final invoice in invoices) {
          totalAmount += invoice.totalAmount ?? 0.0;
        }

        if (totalAmount == 0.0 && collection.totalAmount != null) {
          totalAmount = collection.totalAmount!;
          debugPrint(
            '   🔄 Using collection totalAmount fallback: ₱${NumberFormat('#,##0.00').format(totalAmount)}',
          );
        }

        final customerName =
            customer?.ownerName ?? customer?.name ?? 'Unknown Customer';
        final storeName = customer?.name ?? customerName;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CommonListTiles(
            onTap: () {
              debugPrint(
                '🔄 Navigating to collection details: ${collection.id}',
              );
              context.push(
                '/summary-collection/${collection.id}',
                extra: {
                  'collection': collection,
                  'customer': customer,
                  'invoices': invoices.toList(),
                },
              );
            },
            title: storeName,
            subtitle:
                '${invoices.length} ${invoices.length == 1 ? 'Invoice' : 'Invoices'} • ₱${NumberFormat('#,##0.00').format(totalAmount)}',
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.store,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (customer?.ownerName != null &&
                    customer!.ownerName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
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
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
      },
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
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Completed Customers',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed deliveries will appear here',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
