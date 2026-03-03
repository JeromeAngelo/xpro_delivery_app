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


import '../../../../../core/common/widgets/filter_widgets/filter_option.dart';
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
final Function(String?)? onStatusFilterChanged; // ✅ NEW
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
     this.onStatusFilterChanged, // ✅ NEW
  });

  @override
  State<DeliveryDataTable> createState() => _DeliveryDataTableState();
}

class _DeliveryDataTableState extends State<DeliveryDataTable> {
  List<int> _selectedRows = [];

  String? _deliveryStatusFilter; // null = no filter (show all)

  @override
  Widget build(BuildContext context) {
    final headerStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    final visibleDeliveries = _visibleDeliveries();

    return DataTableLayout(
      title: 'Delivery Data',
      searchBar: DeliveryDataSearchBar(
        controller: widget.searchController,
        searchQuery: widget.searchQuery,
        onSearchChanged: widget.onSearchChanged,
      ),
      onCreatePressed: () {
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

      rows: widget.isLoading
          ? _buildLoadingRows()
          : _buildDataRows(visibleDeliveries),

      currentPage: widget.currentPage,
      totalPages: widget.totalPages,
      onPageChanged: widget.onPageChanged,
      isLoading: widget.isLoading,
      enableSelection: true,

      // ✅ Enable filter icon + menu
      filterCategories: _deliveryFilterCategories(),

      // ✅ Receive filter selections
      onFilterApplied: _handleFilterApplied,
      // optional: Apply/Clear callback (no values)
      onFiltered: () {},

      onRowsSelected: _handleRowsSelected,
      dataLength: '${visibleDeliveries.length}', // ✅ reflects filtered count
      onDeleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulk delete feature coming soon')),
        );
      },
    );
  }

  // ----------------------------
  // ✅ FILTERING (ONLY IF USER SETS FILTER)
  // ----------------------------

void _handleFilterApplied(Map<String, List<dynamic>> filters) {
  final values = filters['delivery_status'];
  final String? newStatus =
      (values != null && values.isNotEmpty) ? values.first.toString() : null;

  // notify parent (screen) so it can filter FULL list and paginate correctly
  widget.onStatusFilterChanged?.call(newStatus);
}

  List<FilterCategory> _deliveryFilterCategories() {
    return [
      FilterCategory(
        id: 'delivery_status',
        title: 'Status',
        icon: Icons.local_shipping_outlined,
        allowMultiple: false,
        options: [
          FilterOption(id: 'pending', label: 'Pending', value: 'Pending'),
          FilterOption(id: 'in_transit', label: 'In Transit', value: 'In Transit'),
          FilterOption(id: 'arrived', label: 'Arrived', value: 'Arrived'),
          FilterOption(id: 'unloading', label: 'Unloading', value: 'Unloading'),
          FilterOption(id: 'received', label: 'Received', value: 'Received'),
          FilterOption(id: 'delivered', label: 'Delivered', value: 'Delivered'),
          FilterOption(id: 'undelivered', label: 'Undelivered', value: 'Undelivered'),
          FilterOption(id: 'no_updates', label: 'No Updates', value: 'No Updates'),
        ],
      ),
    ];
  }

  /// Same logic as DeliveryDataStatusChip, but returns the label string
  String _getLatestDeliveryStatusLabel(DeliveryDataEntity delivery) {
  if (delivery.deliveryUpdates.isNotEmpty) {
    final sorted = List.of(delivery.deliveryUpdates);
    sorted.sort((a, b) {
      final ta = a.time ?? a.created ?? DateTime.now();
      final tb = b.time ?? b.created ?? DateTime.now();
      return tb.compareTo(ta);
    });

    final title = sorted.first.title?.toLowerCase().trim() ?? '';
    switch (title) {
      case 'arrived':
        return 'Arrived';
      case 'unloading':
        return 'Unloading';
      case 'mark as undelivered':
        return 'Undelivered';
      case 'in transit':
        return 'In Transit';
      case 'pending':
        return 'Pending';
      case 'mark as received':
        return 'Received';
      case 'end delivery':
        return 'Delivered';
      default:
        return sorted.first.title ?? 'Unknown';
    }
  }
  return 'No Updates';
}
  /// ✅ Returns all deliveries if user DID NOT select a filter
  List<DeliveryDataEntity> _visibleDeliveries() {
    final list = widget.deliveryData;

    if (_deliveryStatusFilter == null) return list;

    return list
        .where((d) => _getLatestDeliveryStatusLabel(d) == _deliveryStatusFilter)
        .toList();
  }

  // ----------------------------
  // ROW BUILDERS
  // ----------------------------

  List<DataRow> _buildLoadingRows() {
    return List.generate(
      10,
      (index) => DataRow(
        cells: [
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(150)),
          DataCell(_buildShimmerCell(100)),
          DataCell(_buildStatusShimmer()),
          DataCell(_buildStatusShimmer()),
          DataCell(_buildShimmerCell(60)),
          DataCell(_buildShimmerCell(80)),  // ref id shimmer
          DataCell(_buildShimmerCell(100)), // created shimmer
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

  List<DataRow> _buildDataRows(List<DeliveryDataEntity> deliveries) {
    return deliveries.map((delivery) {
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
                  '${delivery.invoices?.length ?? 0}',
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
                  onPressed: () => _navigateToDeliveryDetails(context, delivery),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit',
                  onPressed: () {
                    if (delivery.id != null) {
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
                      // showDeliveryDeleteDialog(context, delivery);
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

  // ----------------------------
  // Utilities / existing code
  // ----------------------------

  void _navigateToDeliveryDetails(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    if (delivery.id != null) {
      context.read<DeliveryDataBloc>().add(
            GetDeliveryDataByIdEvent(delivery.id!),
          );

      context.go('/delivery-details/${delivery.id}');
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

  void _handleRowsSelected(List<int> selectedIndices) {
    setState(() {
      _selectedRows = selectedIndices;
    });

    debugPrint('Selected ${_selectedRows.length} rows: $_selectedRows');

    final deliveries = _visibleDeliveries(); // ✅ selection matches visible list
    final selectedDeliveries = _selectedRows
        .map((index) => index < deliveries.length ? deliveries[index] : null)
        .whereType<DeliveryDataEntity>()
        .toList();

    debugPrint('Selected ${selectedDeliveries.length} deliveries');
  }

  // shimmer helpers (unchanged)
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}