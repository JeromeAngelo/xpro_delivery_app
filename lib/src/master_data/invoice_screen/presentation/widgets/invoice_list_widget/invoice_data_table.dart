import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/master_data/invoice_screen/presentation/widgets/invoice_list_widget/invoice_delete_dialog.dart';
import 'package:xpro_delivery_admin_app/src/master_data/invoice_screen/presentation/widgets/invoice_list_widget/invoice_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InvoiceDataTable extends StatelessWidget {
  final List<InvoiceDataEntity> invoices;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const InvoiceDataTable({
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
  });

  @override
  Widget build(BuildContext context) {
    return DataTableLayout(
      title: 'Invoices',
      searchBar: InvoiceSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create invoice screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create invoice feature coming soon')),
        );
      },
      createButtonText: 'Create Invoice',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Reference ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Total Amount')),
        DataColumn(label: Text('Volume')),
        DataColumn(label: Text('Weight')),
        DataColumn(label: Text('Actions')),
      ],
      rows: invoices.map((invoice) {
        return DataRow(
          cells: [
            DataCell(
              Text(invoice.id?.substring(0, 8) ?? 'N/A'),
              onTap: () => _navigateToInvoiceDetails(context, invoice),
            ),
            DataCell(
              Text(invoice.refId ?? 'N/A'),
              onTap: () => _navigateToInvoiceDetails(context, invoice),
            ),
            DataCell(
              Text(invoice.name ?? 'N/A'),
              onTap: () => _navigateToInvoiceDetails(context, invoice),
            ),
            DataCell(
              Text(invoice.customer?.name ?? 'N/A'),
              onTap: () => _navigateToInvoiceDetails(context, invoice),
            ),
            DataCell(
              Text(_formatDate(invoice.documentDate)),
              onTap: () => _navigateToInvoiceDetails(context, invoice),
            ),
            DataCell(
              Text(_formatAmount(invoice.totalAmount)),
              onTap: () => _navigateToInvoiceDetails(context, invoice),
            ),
            DataCell(
              Text(_formatVolume(invoice.volume)),
              onTap: () => _navigateToInvoiceDetails(context, invoice),
            ),
            DataCell(
              Text(_formatWeight(invoice.weight)),
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
                      showInvoiceDeleteDialog(context, invoice);
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
    return '${weight.toStringAsFixed(2)} kg';
  }

  void _navigateToInvoiceDetails(BuildContext context, InvoiceDataEntity invoice) {
    if (invoice.id != null) {
      // First, dispatch the event to load the invoice data
      context.read<InvoiceDataBloc>().add(GetInvoiceDataByIdEvent(invoice.id!));

      // Then navigate to the specific invoice screen with the actual ID
      context.go('/invoice/${invoice.id}');
    }
  }
}
