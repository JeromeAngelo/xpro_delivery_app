import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_dashboard.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class CompletedCustomerDashboard extends StatelessWidget {
  final List<CollectionEntity> collections;
  final bool isLoading;

  const CompletedCustomerDashboard({
    super.key,
    required this.collections,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingSkeleton(context);
    }

    // Calculate dashboard metrics
// Calculate dashboard metrics
final totalCollections = collections.length;

final totalAmount = collections.fold<double>(
  0,
  (sum, collection) => sum + (collection.totalAmount ?? 0),
);



    

    final uniqueTrips = collections
        .where((collection) => collection.trip?.id != null)
        .map((collection) => collection.trip!.id!)
        .toSet()
        .length;

    // Calculate average collection amount
    final averageAmount = totalCollections > 0 ? totalAmount / totalCollections : 0.0;

   

    // Format currency
    final currencyFormatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
    );

    return DashboardSummary(
      title: 'Collections Overview',
      isLoading: isLoading,
      items: [
        // Total Collections
        DashboardInfoItem(
          icon: Icons.collections_bookmark,
          value: totalCollections.toString(),
          label: 'Total Collections',
          iconColor: Colors.blue,
        ),

        // Total Collection Amount
        DashboardInfoItem(
          icon: Icons.monetization_on,
          value: currencyFormatter.format(totalAmount),
          label: 'Total Collection Amount',
          iconColor: Colors.green,
        ),

       

        // Unique Trips
        DashboardInfoItem(
          icon: Icons.local_shipping,
          value: uniqueTrips.toString(),
          label: 'Trips Completed',
          iconColor: Colors.purple,
        ),

        // Average Collection Amount
        DashboardInfoItem(
          icon: Icons.trending_up,
          value: currencyFormatter.format(averageAmount),
          label: 'Average Collection',
          iconColor: Colors.indigo,
        ),

       
      ],
      crossAxisCount: 3,
      childAspectRatio: 3.0,
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 250,
                height: 24,
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
                6,
                (index) => _buildDashboardSkeletonItem(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSkeletonItem(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
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
    );
  }
}
