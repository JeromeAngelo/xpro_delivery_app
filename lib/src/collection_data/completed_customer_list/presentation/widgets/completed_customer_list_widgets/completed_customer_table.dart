import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CompletedCustomerDataTable extends StatelessWidget {
  final List<CollectionEntity> collections;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const CompletedCustomerDataTable({
    super.key,
    required this.collections,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Format currency
    final currencyFormatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
    );

    return DataTableLayout(
      title: 'Completed Collections',
      searchBar: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search by store name, delivery number, or collection...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onSearchChanged,
      ),
      onCreatePressed: null, // No create button for completed collections
      columns: const [
        DataColumn(label: Text('Delivery #')),
        DataColumn(label: Text('Store Name')),
        DataColumn(label: Text('Trip Name')),
        DataColumn(label: Text('Total Amount')),
        DataColumn(label: Text('Completed At')),
        DataColumn(label: Text('Actions')),
      ],
      rows:
          collections.map((collection) {
            return DataRow(
              cells: [
                DataCell(
                  Text(collection.deliveryData!.deliveryNumber ?? 'N/A'),
                  onTap: () => _navigateToCollectionData(context, collection),
                ),
                DataCell(
                  Text(collection.customer!.name ?? 'N/A'),
                  onTap: () => _navigateToCollectionData(context, collection),
                ),

                DataCell(
                  InkWell(
                    onTap: () {
                      if (collection.trip!.id != null) {
                        context.go('/collections/${collection.trip!.id}');
                      }
                    },
                    child: Text(
                      collection.trip!.name ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    collection.totalAmount != null
                        ? currencyFormatter.format(collection.totalAmount)
                        : 'N/A',
                  ),
                  onTap: () => _navigateToCollectionData(context, collection),
                ),
                DataCell(
                  Text(
                    collection.created != null
                        ? DateFormat(
                          'MMM dd, yyyy hh:mm a',
                        ).format(collection.created!)
                        : 'N/A',
                  ),
                  onTap: () => _navigateToCollectionData(context, collection),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {
                          // View collection details
                          _showCollectionDetailsDialog(context, collection);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.green),
                        tooltip: 'Print Receipt',
                        onPressed: () {
                          // Print receipt
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Printing receipt...'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: onPageChanged,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRetry: onRetry,
      onFiltered: () {
        // Show filter options
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filter options coming soon')),
        );
      },
      dataLength: '${collections.length}',
      onDeleted: () {},
    );
  }

  void _showCollectionDetailsDialog(
    BuildContext context,
    CollectionEntity collection,
  ) {
    // Format currency
    final currencyFormatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(collection.collectionName ?? 'Collection Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'Collection ID',
                    collection.collectionId ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Collection Name',
                    collection.collectionName ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Delivery Number',
                    collection.deliveryData?.deliveryNumber ?? 'N/A',
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Customer Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  _buildDetailRow(
                    'Store Name',
                    collection.customer?.name ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Owner Name',
                    collection.customer?.ownerName ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Contact',
                    collection.customer?.contactNumber ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Municipality',
                    collection.customer?.municipality ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Province',
                    collection.customer?.province ?? 'N/A',
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Trip Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  _buildDetailRow(
                    'Trip ID',
                    collection.trip?.tripNumberId ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Trip Status',
                    collection.trip?.isEndTrip == true ? 'Completed' : 'Active',
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Collection Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  _buildDetailRow(
                    'Total Amount',
                    collection.totalAmount != null
                        ? currencyFormatter.format(collection.totalAmount)
                        : 'N/A',
                  ),
                  _buildDetailRow(
                    'Created At',
                    collection.created != null
                        ? DateFormat(
                          'MMM dd, yyyy hh:mm a',
                        ).format(collection.created!)
                        : 'N/A',
                  ),
                  _buildDetailRow(
                    'Updated At',
                    collection.updated != null
                        ? DateFormat(
                          'MMM dd, yyyy hh:mm a',
                        ).format(collection.updated!)
                        : 'N/A',
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Invoice Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  collection.invoice != null
                      ? Column(
                        children: [
                          _buildDetailRow(
                            'Invoice Number',
                            collection.invoice?.refId ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Invoice Amount',
                            collection.invoice?.totalAmount != null
                                ? currencyFormatter.format(
                                  collection.invoice!.totalAmount!,
                                )
                                : 'N/A',
                          ),
                          _buildDetailRow(
                            'Invoice Date',
                            collection.invoice?.created != null
                                ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(collection.invoice!.created!)
                                : 'N/A',
                          ),
                        ],
                      )
                      : const Text('No invoice information available'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Printing receipt...')),
                  );
                },
                child: const Text('Print Receipt'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _navigateToCollectionData(
    BuildContext context,
    CollectionEntity collection,
  ) {
    if (collection.id != null) {
      context.read<CollectionsBloc>().add(
        GetCollectionByIdEvent(collection.id!),
      );

      context.go('/completed-collections/${collection.id}');
    }
  }
}
