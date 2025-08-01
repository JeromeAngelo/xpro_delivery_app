import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class InvoiceDeliveryDataWidget extends StatefulWidget {
  final DeliveryDataEntity? deliveryData;
  final bool isLoading;
  final VoidCallback? onInvoiceEdit;
  final VoidCallback? onInvoiceView;
  final VoidCallback? onViewItems;

  const InvoiceDeliveryDataWidget({
    super.key,
    required this.deliveryData,
    this.isLoading = false,
    this.onInvoiceEdit,
    this.onInvoiceView,
    this.onViewItems,
  });

  @override
  State<InvoiceDeliveryDataWidget> createState() =>
      _InvoiceDeliveryDataWidgetState();
}

class _InvoiceDeliveryDataWidgetState extends State<InvoiceDeliveryDataWidget> {
  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return DataTableLayout(
      title: 'Invoice Information',
      onCreatePressed:
          widget.onInvoiceEdit != null
              ? () {
                widget.onInvoiceEdit!();
              }
              : null,
      createButtonText: 'Edit Invoice',
      columns: [
        DataColumn(label: Text('Invoice ID', style: headerStyle)),
        DataColumn(label: Text('Invoice Name', style: headerStyle)),
        DataColumn(label: Text('Total Amount', style: headerStyle)),
        DataColumn(label: Text('Items Count', style: headerStyle)),
        DataColumn(label: Text('Customer', style: headerStyle)),
        DataColumn(label: Text('Delivery Number', style: headerStyle)),
        DataColumn(label: Text('Created Date', style: headerStyle)),
        DataColumn(label: Text('Actions', style: headerStyle)),
      ],
      rows: widget.isLoading ? _buildLoadingRows() : _buildInvoiceRows(),
      currentPage: 1,
      totalPages: 1,
      onPageChanged: (page) {
        // No pagination needed for single invoice
      },
      isLoading: widget.isLoading,
      dataLength: '1',
      onFiltered: () {},
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
          DataCell(_buildShimmerCell(80)),
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

  List<DataRow> _buildInvoiceRows() {
    if (widget.deliveryData?.invoice == null) {
      return [
        DataRow(
          cells: [
            const DataCell(Text('N/A')),
            const DataCell(Text('No Invoice Data')),
            const DataCell(Text('N/A')),
            const DataCell(Text('0')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    tooltip: 'Add Invoice',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add invoice feature coming soon'),
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

    final invoice = widget.deliveryData!.invoice!;

    return [
      DataRow(
        cells: [
          DataCell(
            Text(invoice.id ?? 'N/A'),
            onTap: () => _navigateToInvoiceDetails(context, invoice),
          ),
          DataCell(
            Text(invoice.name ?? 'N/A'),
            onTap: () => _navigateToInvoiceDetails(context, invoice),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAmountBackgroundColor(invoice.totalAmount),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                invoice.totalAmount != null ? '₱${invoice.totalAmount}' : 'N/A',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _getAmountTextColor(invoice.totalAmount),
                ),
              ),
            ),
            onTap: () => _navigateToInvoiceDetails(context, invoice),
          ),
          DataCell(
            _buildItemsCountChip(),
            onTap: () => _navigateToInvoiceDetails(context, invoice),
          ),
          DataCell(
            Text(widget.deliveryData!.customer?.name ?? 'N/A'),
            onTap: () => _navigateToInvoiceDetails(context, invoice),
          ),
          DataCell(
            Text(widget.deliveryData!.deliveryNumber ?? 'N/A'),
            onTap: () => _navigateToInvoiceDetails(context, invoice),
          ),
          
          DataCell(
            Text(_formatDate(widget.deliveryData!.created)),
            onTap: () => _navigateToInvoiceDetails(context, invoice),
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Details',
                  onPressed: () => _navigateToInvoiceDetails(context, invoice),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit Invoice',
                  onPressed: widget.onInvoiceEdit,
                ),
                if ((widget.deliveryData?.invoiceItems?.length ?? 0) > 0)
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.green),
                    tooltip: 'View Items',
                    onPressed: widget.onViewItems,
                  ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildItemsCountChip() {
    final itemCount = widget.deliveryData?.invoiceItems?.length ?? 0;
    
    Color color;
    if (itemCount > 0) {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return Chip(
      label: Text(
        '$itemCount items',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  

  Color _getAmountBackgroundColor(dynamic totalAmount) {
    return totalAmount != null ? Colors.green[50]! : Colors.grey[50]!;
  }

  Color _getAmountTextColor(dynamic totalAmount) {
    return totalAmount != null ? Colors.green[700]! : Colors.grey[600]!;
  }

  void _navigateToInvoiceDetails(BuildContext context, dynamic invoice) {
    if (invoice.id != null) {
      // Navigate to invoice details screen
      if (widget.onInvoiceView != null) {
        widget.onInvoiceView!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing invoice: ${invoice.name ?? invoice.id}'),
          ),
        );
      }
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
}
