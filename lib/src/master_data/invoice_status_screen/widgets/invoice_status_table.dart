import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/common/app/features/invoice_status/domain/entity/invoice_status_entity.dart';
import '../../../../core/common/widgets/app_structure/data_table_layout.dart';
import 'invoice_status_search_bar.dart';

class InvoiceStatusTable extends StatelessWidget {
  final List<InvoiceStatusEntity> invoices;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? customFunction;
  final IconData? customIcon;
  const InvoiceStatusTable({
    super.key,
    required this.invoices,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    this.errorMessage,
    this.onRetry,
    this.customFunction,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DataTableLayout(
      title: 'Invoices',
      searchBar: InvoiceStatusSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),

      showCustomAction: true,
      customActionIcon: customIcon,
      onCustomAction: customFunction,
      customActionTooltip: 'Import from Excel or CSV',
      onCreatePressed: () {
        // // Navigate to create invoice screen
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Create invoice feature coming soon')),
        // );
        // Function for exporting data to Excel
      },
      createButtonText: 'Create Invoice',

      columns: const [
        //DataColumn(label: Text('ID')),
        DataColumn(label: Text('Reference ID')),
        DataColumn(label: Text('Customer Name')),
        DataColumn(label: Text('Delivery Status')),
        DataColumn(label: Text('Document Date')),
        DataColumn(label: Text('Total Amount')),
        DataColumn(label: Text('Volume')),
        DataColumn(label: Text('Weight')),
        DataColumn(label: Text('Actions')),
      ],
      rows:
          invoices.map((invoice) {
            return DataRow(
              cells: [
                // DataCell(
                //   Text(invoice.id?.substring(0, 8) ?? 'N/A'),
                // ),
                DataCell(Text(invoice.invoiceData?.refId ?? 'N/A')),

                DataCell(Text(invoice.customer?.name ?? 'N/A')),
                DataCell(_buildTripStatusChip(invoice.tripStatus)),
                DataCell(Text(_formatDate(invoice.invoiceData?.documentDate))),
                DataCell(Text(_formatAmount(invoice.invoiceData?.totalAmount))),
                DataCell(Text(_formatVolume(invoice.invoiceData?.volume))),
                DataCell(Text(_formatWeight(invoice.invoiceData?.weight))),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () {
                          // Edit invoice
                          if (invoice.id != null) {
                            // Navigate to edit screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Edit invoice feature coming soon',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () {
                          // showInvoiceDeleteDialog(context, invoice);
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
        // Show filter options dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filter options coming soon')),
        );
      },
      dataLength: '${invoices.length}',
      onDeleted: () {},
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatAmount(double? amount) {
    if (amount == null) return 'N/A';
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatVolume(double? volume) {
    if (volume == null) return 'N/A';
    return '${volume.toStringAsFixed(2)} m³';
  }

  String _formatWeight(double? weight) {
    if (weight == null) return 'N/A';
    return '${weight.toStringAsFixed(2)} tons';
  }

  Widget _buildTripStatusChip(String? status) {
    final normalized = (status ?? 'none').toLowerCase().trim();

    Color bgColor;
    Color textColor = Colors.white;

    switch (normalized) {
      case 'pending':
        bgColor = Colors.orange;
        break;

      case 'arrived':
        bgColor = Colors.blue;
        break;

      case 'unloading':
        bgColor = Colors.deepPurple;
        break;

      case 'received':
        bgColor = Colors.teal;
        break;

      case 'delivered':
        bgColor = Colors.green;
        break;

      case 'cancelled':
        bgColor = Colors.red;
        break;

      case 'none':
      default:
        bgColor = Colors.grey;
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // void _navigateToInvoiceDetails(BuildContext context, InvoiceDataEntity invoice) {
  //   if (invoice.id != null) {
  //     // First, dispatch the event to load the invoice data
  //     context.read<InvoiceDataBloc>().add(GetInvoiceDataByIdEvent(invoice.id!));

  //     // Then navigate to the specific invoice screen with the actual ID
  //     context.go('/invoice/${invoice.id}');
  //   }
  // }
}
