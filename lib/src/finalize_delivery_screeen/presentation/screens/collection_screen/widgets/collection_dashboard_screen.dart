import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';

class CollectionDashboardScreen extends StatelessWidget {
  final List<CollectionEntity> collections;
  final bool isOffline;

  const CollectionDashboardScreen({
    super.key,
    required this.collections,
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
                'Collection Summary',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Today\'s Collection Overview',
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
    if (collections.isEmpty) {
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
          _buildCollectionStats(context),
        ],
      );
    }

    return _buildCollectionStats(context);
  }

  Widget _buildCollectionStats(BuildContext context) {
    debugPrint('📊 DASHBOARD: Calculating collection statistics');
    debugPrint('📊 Total collections received: ${collections.length}');

    // Calculate total amount from all invoices in all collections
    double totalAmount = 0.0;
    int totalInvoices = 0;
    
    for (final collection in collections) {
      final invoices = collection.invoices;
      final invoicesCount = invoices.length;
      totalInvoices += invoicesCount;
      
      debugPrint('📊 Collection ${collection.id}: ${invoicesCount} invoices');
      
      // Calculate amount from invoices in this collection
      double collectionAmount = 0.0;
      for (final invoice in invoices) {
        final invoiceAmount = invoice.totalAmount ?? 0.0;
        collectionAmount += invoiceAmount;
        debugPrint('   💰 Invoice ${invoice.refId ?? invoice.name}: ₱${NumberFormat('#,##0.00').format(invoiceAmount)}');
      }
      
      // Fallback to collection totalAmount if invoices don't have amounts
      if (collectionAmount == 0.0 && collection.totalAmount != null) {
        collectionAmount = collection.totalAmount!;
        debugPrint('   🔄 Using collection totalAmount as fallback: ₱${NumberFormat('#,##0.00').format(collectionAmount)}');
      }
      
      totalAmount += collectionAmount;
      debugPrint('💰 Collection ${collection.id} total: ₱${NumberFormat('#,##0.00').format(collectionAmount)}');
    }

    debugPrint('💰 DASHBOARD: Total amount from all invoices: ₱${NumberFormat('#,##0.00').format(totalAmount)}');

    // Total collections count
    final totalCollections = collections.length;
    debugPrint('📦 DASHBOARD: Total collections count: $totalCollections');
    debugPrint('📄 DASHBOARD: Total invoices across all collections: $totalInvoices');

    // Get completion date from trip data
    String completionDate = 'Today';
    if (collections.isNotEmpty && collections.first.trip.target?.timeAccepted != null) {
      final tripDate = collections.first.trip.target!.timeAccepted!;
      completionDate = DateFormat('MMM dd, yyyy').format(tripDate.toLocal());
      debugPrint('📅 DASHBOARD: Completion date: $completionDate');
    } else {
      debugPrint('📅 DASHBOARD: Using default completion date: $completionDate');
    }

    // Debug summary
    debugPrint('📊 DASHBOARD SUMMARY:');
    debugPrint('   💰 Total Amount: ₱${NumberFormat('#,##0.00').format(totalAmount)}');
    debugPrint('   📄 Total Invoices: $totalInvoices');
    debugPrint('   📦 Collections: $totalCollections');
    debugPrint('   📅 Date: $completionDate');

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
          Icons.attach_money,
          '₱${NumberFormat('#,##0.00').format(totalAmount)}',
          'Total Collections',
        ),
        _buildInfoItem(
          context,
          Icons.receipt_long,
          totalInvoices.toString(),
          'Total Invoices',
        ),
        _buildInfoItem(
          context,
          Icons.collections,
          totalCollections.toString(),
          'Collections',
        ),
        _buildInfoItem(
          context,
          Icons.calendar_month_outlined,
          completionDate,
          'Date Completed',
        ),
      ],
    );
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
            Icons.collections_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Collections Found',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Collections will appear here once available',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }
}
