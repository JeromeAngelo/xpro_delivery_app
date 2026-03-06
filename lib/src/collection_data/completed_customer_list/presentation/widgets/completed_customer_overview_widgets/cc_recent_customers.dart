import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';

class RecentCompletedCustomers extends StatelessWidget {
  final List<CollectionEntity> collections;
  final bool isLoading;

  const RecentCompletedCustomers({
    super.key,
    required this.collections,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sort collections by creation date (newest first)
    final sortedCollections = List<CollectionEntity>.from(collections)..sort(
      (a, b) =>
          (b.created ?? DateTime.now()).compareTo(a.created ?? DateTime.now()),
    );

    // Take only the 5 most recent collections
    final recentCollections = sortedCollections.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Collections',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/completed-collections'),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (recentCollections.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No collections found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2), // Store Name
                  1: FlexColumnWidth(1.5), // Collection Name
                  2: FlexColumnWidth(1.5), // Delivery Number
                  3: FlexColumnWidth(1.5), // Created Date
                  4: FlexColumnWidth(1.5), // Amount
                  5: FlexColumnWidth(1), // Actions
                },
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                children: [
                  // Table Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    children: [
                      _buildTableHeader(context, 'Store Name'),
                      _buildTableHeader(context, 'Delivery #'),
                      _buildTableHeader(context, 'Trip'),

                      _buildTableHeader(context, 'Created Date'),
                      _buildTableHeader(context, 'Amount'),
                      _buildTableHeader(context, 'Actions'),
                    ],
                  ),
                  // Table Rows
                  ...recentCollections.map(
                    (collection) => TableRow(
                      children: [
                        _buildTableCell(
                          context,
                          collection.customer?.name ?? 'N/A',
                        ),
                        _buildTableCell(
                          context,
                          collection.deliveryData?.deliveryNumber ?? 'N/A',
                        ),
                        _buildTableCell(
                          context,
                          collection.trip?.name ??
                              collection.trip?.tripNumberId ??
                              'N/A',
                        ),

                        _buildTableCell(
                          context,
                          _formatDate(collection.created),
                        ),
                        _buildTableCell(
                          context,
                          _formatCurrency(collection.totalAmount ?? 0),
                        ),
                        _buildActionCell(context, collection),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTableCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(text),
    );
  }

  Widget _buildActionCell(BuildContext context, CollectionEntity collection) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.visibility, color: Colors.blue),
            onPressed: () {
              if (collection.id != null) {
                context.go('/completed-collections/details/${collection.id}');
              }
            },
            tooltip: 'View Details',
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.green),
            onPressed: () {
              // Print collection receipt
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Printing receipt for ${collection.customer?.name ?? 'collection'}...',
                  ),
                ),
              );
            },
            tooltip: 'Print Receipt',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return formatter.format(amount);
  }
}
