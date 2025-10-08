import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/widgets/delivery_data_screen_widget/delivery_data_searchbar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import 'delivery_update_chip.dart';

class DeliveryDataTable extends StatefulWidget {
  final List<DeliveryDataEntity> deliveryData;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const DeliveryDataTable({
    super.key,
    required this.deliveryData,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  State<DeliveryDataTable> createState() => _DeliveryDataTableState();
}

class _DeliveryDataTableState extends State<DeliveryDataTable> {
  List<int> _selectedRows = [];

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return DataTableLayout(
      title: 'Delivery Data',
      searchBar: DeliveryDataSearchBar(
        controller: widget.searchController,
        searchQuery: widget.searchQuery,
        onSearchChanged: widget.onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create delivery screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create delivery feature coming soon')),
        );
      },
      createButtonText: 'Create Delivery',
      columns: [
        DataColumn(label: Text('Delivery Number', style: headerStyle)),
        DataColumn(label: Text('Customer', style: headerStyle)),
        DataColumn(label: Text('Invoice', style: headerStyle)),
        DataColumn(label: Text('Trip', style: headerStyle)),
        DataColumn(label: Text('Status', style: headerStyle)),
        DataColumn(label: Text('Items', style: headerStyle)),
        DataColumn(label: Text('Reference ID', style: headerStyle)),
        DataColumn(label: Text('Created', style: headerStyle)),
        DataColumn(label: Text('Actions', style: headerStyle)),
      ],
      rows: widget.isLoading ? _buildLoadingRows() : _buildDataRows(),
      currentPage: widget.currentPage,
      totalPages: widget.totalPages,
      onPageChanged: widget.onPageChanged,
      isLoading: widget.isLoading,
      enableSelection: true,
      onFiltered: _handleFiltering,
      onRowsSelected: _handleRowsSelected,
      dataLength: '${widget.deliveryData.length}',
      onDeleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulk delete feature coming soon')),
        );
      },
    );
  }

  List<DataRow> _buildLoadingRows() {
    // Create 10 shimmer loading rows
    return List.generate(
      10,
      (index) => DataRow(
        cells: [
          // Delivery Number cell
          DataCell(_buildShimmerCell(120)),
          // Customer cell
          DataCell(_buildShimmerCell(150)),
          // Invoice cell
          DataCell(_buildShimmerCell(100)),
          // Trip cell
          DataCell(_buildStatusShimmer()),
          // Status cell
          DataCell(_buildStatusShimmer()),
          // Items cell
          DataCell(_buildShimmerCell(60)),
          // Created cell
          DataCell(_buildShimmerCell(100)),
          // Actions cell
          DataCell(
            Row(
              children: [
                _buildShimmerIcon(),
                const SizedBox(width: 8),
                _buildShimmerIcon(),
                const SizedBox(width: 8),
                _buildShimmerIcon(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCell(double width) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildStatusShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 80,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildShimmerIcon() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  List<DataRow> _buildDataRows() {
    return widget.deliveryData.map((delivery) {
      // Debug print for each delivery
      debugPrint('🔍 TABLE: Processing delivery: ${delivery.id}');

      return DataRow(
        cells: [
          DataCell(
            Text(delivery.deliveryNumber ?? 'N/A'),
            onTap: () => _navigateToDeliveryDetails(context, delivery),
          ),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  delivery.customer?.name ?? 'No Customer',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (delivery.customer?.municipality != null)
                  Text(
                    delivery.customer!.municipality!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            onTap: () => _navigateToDeliveryDetails(context, delivery),
          ),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${delivery.invoices!.length} ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (delivery.invoice?.totalAmount != null)
                  Text(
                    '₱${delivery.invoice!.totalAmount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            onTap: () => _navigateToDeliveryDetails(context, delivery),
          ),
          DataCell(
            delivery.trip?.tripNumberId != null
                ? Chip(
                  label: Text(
                    delivery.trip!.tripNumberId!,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                )
                : const Text('No Trip'),
            onTap: () => _navigateToDeliveryDetails(context, delivery),
          ),
          DataCell(
            DeliveryDataStatusChip(delivery: delivery),
            onTap: () => _navigateToDeliveryDetails(context, delivery),
          ),
          DataCell(
            Text(
              '${delivery.invoiceItems?.length ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () => _navigateToDeliveryDetails(context, delivery),
          ),
          DataCell(
            Text(delivery.refID ?? 'N/A'),
            onTap: () => _navigateToDeliveryDetails(context, delivery),
          ),
          DataCell(
            Text(_formatDate(delivery.created)),
            onTap: () => _navigateToDeliveryDetails(context, delivery),
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Details',
                  onPressed:
                      () => _navigateToDeliveryDetails(context, delivery),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit',
                  onPressed: () {
                    // Edit delivery
                    if (delivery.id != null) {
                      // Navigate to edit screen with delivery data
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit delivery feature coming soon'),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () {
                    if (delivery.id != null) {
                      //  showDeliveryDeleteDialog(context, delivery);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  // Helper method to navigate to delivery details
  void _navigateToDeliveryDetails(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    if (delivery.id != null) {
      // First load the delivery data
      context.read<DeliveryDataBloc>().add(
        GetDeliveryDataByIdEvent(delivery.id!),
      );

      context.go('/delivery-details/${delivery.id}');

      // Show details dialog for now (can be changed to navigation later)
      //  _showDeliveryDetailsDialog(context, delivery);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('MM/dd/yyyy hh:mm a').format(date);
    } catch (e) {
      debugPrint('❌ Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  // Handle row selection
  void _handleRowsSelected(List<int> selectedIndices) {
    setState(() {
      _selectedRows = selectedIndices;
    });

    debugPrint('Selected ${_selectedRows.length} rows: $_selectedRows');

    // Get the selected delivery entities
    final selectedDeliveries =
        _selectedRows
            .map(
              (index) =>
                  index < widget.deliveryData.length
                      ? widget.deliveryData[index]
                      : null,
            )
            .where((delivery) => delivery != null)
            .toList();

    debugPrint('Selected ${selectedDeliveries.length} deliveries');
  }

  // Handle filtering action
  void _handleFiltering() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Options'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Delivery Number',
                      hintText: 'Filter by delivery number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      hintText: 'Filter by customer name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Trip Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(
                        value: 'with_trip',
                        child: Text('With Trip'),
                      ),
                      DropdownMenuItem(
                        value: 'without_trip',
                        child: Text('Without Trip'),
                      ),
                    ],
                    onChanged: (value) {
                      // Handle filter change
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Apply filters
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters applied')),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }
}
