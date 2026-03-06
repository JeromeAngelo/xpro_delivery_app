import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class CollectionTripDashboardWidget extends StatelessWidget {
  final TripEntity trip;
  final List<CollectionEntity> completedCustomers;
  final bool isLoading;

  const CollectionTripDashboardWidget({
    super.key,
    required this.trip,
    required this.completedCustomers,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingSkeleton(context);
    }

    // Calculate total amount collected
    double totalAmountCollected = 0;
    for (var customer in completedCustomers) {
      if (customer.totalAmount != null) {
        totalAmountCollected += customer.totalAmount!;
      }
    }

    // Format currency
    final currencyFormatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
    );

    return DashboardSummary(
      title: 'Collection Summary',
      isLoading: isLoading,
      crossAxisCount: 3,
      items: [
        DashboardInfoItem(
          icon: Icons.receipt_long,
          value: trip.name ?? trip.tripNumberId ?? 'N/A',
          label: 'Trip Number',
          iconColor: Colors.blue,
        ),
        DashboardInfoItem(
          icon: Icons.people,
          value: completedCustomers.length.toString(),
          label: 'Completed Customers',
          iconColor: Colors.green,
        ),
        DashboardInfoItem(
          icon: Icons.payments,
          value: currencyFormatter.format(totalAmountCollected),
          label: 'Total Amount Collected',
          iconColor: Colors.purple,
        ),
        DashboardInfoItem(
          icon: Icons.calendar_today,
          value:
              trip.timeAccepted != null
                  ? DateFormat('MMM dd, yyyy').format(trip.timeAccepted!)
                  : 'N/A',
          label: 'Start Date',
          iconColor: Colors.orange,
        ),
        DashboardInfoItem(
          icon: Icons.done_all,
          value:
              trip.timeEndTrip != null
                  ? DateFormat('MMM dd, yyyy').format(trip.timeEndTrip!)
                  : 'N/A',
          label: 'End Date',
          iconColor: Colors.teal,
        ),
        DashboardInfoItem(
          icon: Icons.person,
          value: trip.user?.name ?? 'N/A',
          label: 'Collected by',
          iconColor: Colors.indigo,
        ),
      ],
    );
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
                width: 200,
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
                6, // Same number as actual items
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
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Label placeholder
                  Container(
                    width: 120,
                    height: 16,
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
