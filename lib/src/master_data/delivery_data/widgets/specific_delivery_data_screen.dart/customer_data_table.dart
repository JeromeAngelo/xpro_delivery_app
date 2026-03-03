import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class CustomerDataTableWidget extends StatefulWidget {
  final DeliveryDataEntity? deliveryData;
  final bool isLoading;
  final VoidCallback? onCustomerEdit;
  final VoidCallback? onCustomerView;

  const CustomerDataTableWidget({
    super.key,
    required this.deliveryData,
    this.isLoading = false,
    this.onCustomerEdit,
    this.onCustomerView,
  });

  @override
  State<CustomerDataTableWidget> createState() =>
      _CustomerDataTableWidgetState();
}

class _CustomerDataTableWidgetState extends State<CustomerDataTableWidget> {
  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return DataTableLayout(
      title: 'Customer Information',
      onCreatePressed:
          widget.onCustomerEdit != null
              ? () {
                widget.onCustomerEdit!();
              }
              : null,
      createButtonText: 'Edit Customer',
      columns: [
        DataColumn(label: Text('Customer ID', style: headerStyle)),
        DataColumn(label: Text('Name', style: headerStyle)),
        DataColumn(label: Text('Reference ID', style: headerStyle)),
        DataColumn(label: Text('Province', style: headerStyle)),
        DataColumn(label: Text('Municipality', style: headerStyle)),
        DataColumn(label: Text('Barangay', style: headerStyle)),
        DataColumn(label: Text('Coordinates', style: headerStyle)),
        DataColumn(label: Text('Created Date', style: headerStyle)),
        DataColumn(label: Text('Actions', style: headerStyle)),
      ],
      rows: widget.isLoading ? _buildLoadingRows() : _buildCustomerRows(),
      currentPage: 1,
      totalPages: 1,
      onPageChanged: (page) {
        // No pagination needed for single customer
      },
      isLoading: widget.isLoading,
      dataLength: '1',
      onDeleted: () {},
    );
  }

  List<DataRow> _buildLoadingRows() {
    return List.generate(1, (index) {
      return DataRow(
        cells: [
          DataCell(_buildShimmerCell(80)),
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(100)),
          DataCell(_buildShimmerCell(100)),
          DataCell(_buildShimmerCell(100)),
          DataCell(_buildShimmerCell(100)),
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(120)),
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
      );
    });
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

  List<DataRow> _buildCustomerRows() {
    if (widget.deliveryData?.customer == null) {
      return [
        DataRow(
          cells: [
            const DataCell(Text('N/A')),
            const DataCell(Text('No Customer Data')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    tooltip: 'Add Customer',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add customer feature coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ];
    }

    final customer = widget.deliveryData!.customer!;

    return [
      DataRow(
        cells: [
          DataCell(
            Text(customer.id ?? 'N/A'),
            onTap: () => _navigateToCustomerDetails(context, customer),
          ),
          DataCell(
            Text(customer.name ?? 'N/A'),
            onTap: () => _navigateToCustomerDetails(context, customer),
          ),
          DataCell(
            Text(customer.refId ?? 'N/A'),
            onTap: () => _navigateToCustomerDetails(context, customer),
          ),
          DataCell(
            Text(customer.province ?? 'N/A'),
            onTap: () => _navigateToCustomerDetails(context, customer),
          ),
          DataCell(
            Text(customer.municipality ?? 'N/A'),
            onTap: () => _navigateToCustomerDetails(context, customer),
          ),
          DataCell(
            Text(customer.barangay ?? 'N/A'),
            onTap: () => _navigateToCustomerDetails(context, customer),
          ),
          DataCell(
            Text(_formatCoordinates()),
            onTap: () => _navigateToCustomerDetails(context, customer),
          ),
          DataCell(
            Text(_formatDate(customer.created)),
            onTap: () => _navigateToCustomerDetails(context, customer),
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Details',
                  onPressed:
                      () => _navigateToCustomerDetails(context, customer),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit Customer',
                  onPressed: widget.onCustomerEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.green),
                  tooltip: 'View Location',
                  onPressed: () => _openMapsLocation(),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _navigateToCustomerDetails(BuildContext context, dynamic customer) {
    if (customer.id != null) {
      // Navigate to customer details screen
      if (widget.onCustomerView != null) {
        widget.onCustomerView!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing customer: ${customer.name ?? customer.id}'),
          ),
        );
      }
    }
  }

  void _openMapsLocation() {
    final customer = widget.deliveryData?.customer;
    if (customer?.latitude != null && customer?.longitude != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening maps for: ${customer!.latitude}, ${customer.longitude}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No coordinates available for this customer'),
        ),
      );
    }
  }

  String _formatCoordinates() {
    final customer = widget.deliveryData?.customer;
    if (customer?.latitude != null && customer?.longitude != null) {
      return '${customer!.latitude!.toStringAsFixed(6)}, ${customer.longitude!.toStringAsFixed(6)}';
    }
    return 'No coordinates';
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
}
