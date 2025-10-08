import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class CompletedCustomerDashboardWidget extends StatelessWidget {
  final CollectionEntity collection;
  final bool isLoading;

  const CompletedCustomerDashboardWidget({
    super.key,
    required this.collection,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingSkeleton(context);
    }

    // Format currency
    final currencyFormatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
    );

    // final invoices = collection.invoices ?? [];
    // final invoiceNumbers =
    //     invoices.isNotEmpty
    //         ? invoices.map((inv) => inv.refId ?? 'N/A').join(', ')
    //         : 'N/A';
    // final totalInvoiceAmount = invoices.fold<double>(
    //   0.0,
    //   (sum, inv) => sum + (inv.totalAmount ?? 0),
    // );

    // Format date
    final dateFormatter = DateFormat('MMM dd, yyyy hh:mm a');

    return DashboardSummary(
      title: 'Collection Details',
      isLoading: isLoading,
      crossAxisCount: 3,
      items: [
        DashboardInfoItem(
          icon: Icons.collections_bookmark,
          value: collection.collectionName ?? 'N/A',
          label: 'Collection Name',
          iconColor: Colors.blue,
        ),
        DashboardInfoItem(
          icon: Icons.receipt_long,
          value: collection.deliveryData?.deliveryNumber ?? 'N/A',
          label: 'Delivery Number',
          iconColor: Colors.indigo,
        ),
        DashboardInfoItem(
          icon: Icons.store,
          value: collection.customer?.name ?? 'N/A',
          label: 'Store Name',
          iconColor: Colors.green,
        ),
        DashboardInfoItem(
          icon: Icons.person,
          value: collection.customer?.ownerName ?? 'N/A',
          label: 'Owner Name',
          iconColor: Colors.orange,
        ),
        DashboardInfoItem(
          icon: Icons.payments,
          value:
              collection.totalAmount != null
                  ? currencyFormatter.format(collection.totalAmount)
                  : 'N/A',
          label: 'Collection Amount',
          iconColor: Colors.purple,
        ),

        DashboardInfoItem(
          icon: Icons.local_shipping,
          value: collection.trip?.tripNumberId ?? 'N/A',
          label: 'Trip Number',
          iconColor: Colors.brown,
        ),
        DashboardInfoItem(
          icon: Icons.access_time,
          value:
              collection.created != null
                  ? dateFormatter.format(collection.created!)
                  : 'N/A',
          label: 'Created At',
          iconColor: Colors.amber,
        ),
        DashboardInfoItem(
          icon: Icons.update,
          value:
              collection.updated != null
                  ? dateFormatter.format(collection.updated!)
                  : 'N/A',
          label: 'Updated At',
          iconColor: Colors.grey,
        ),
        DashboardInfoItem(
          icon: Icons.location_on,
          value: _buildAddressString(collection),
          label: 'Customer Address',
          iconColor: Colors.red,
        ),
      ],
    );
  }

  String _buildAddressString(CollectionEntity collection) {
    final addressParts =
        [
          collection.customer?.municipality,
          collection.customer?.province,
        ].where((part) => part != null && part.isNotEmpty).toList();

    return addressParts.isNotEmpty ? addressParts.join(', ') : 'N/A';
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 180,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Grid of skeleton items
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: List.generate(
                12, // Updated number of items
                (index) => _buildDashboardItemSkeleton(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItemSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),

            // Content placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Value placeholder
                  Container(
                    width: double.infinity,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Label placeholder
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
