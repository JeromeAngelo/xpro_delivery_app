import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CompletedCustomerInvoiceTable extends StatelessWidget {
  final List<CollectionEntity> collections;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final String? completedCustomerId;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const CompletedCustomerInvoiceTable({
    super.key,
    required this.collections,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.completedCustomerId,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return DataTableLayout(
      title: 'Collection Invoices',
      columns: const [
        DataColumn(label: Text('Collection Name')),
        DataColumn(label: Text('Invoice Numbers')),
        DataColumn(label: Text('Delivery Number')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Total Amount')),
        DataColumn(label: Text('Confirmed Total Amount')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: collections.map((collection) {
        final invoices = collection.invoices ?? [];

        // Join invoice numbers for display (or N/A)
        final invoiceNumbers = invoices.isNotEmpty
            ? invoices.map((inv) => inv.name ?? 'N/A').join(', ')
            : 'N/A';

        // Compute confirmed total amount (sum of all invoices)
        final confirmedTotal = invoices.fold<double>(
          0.0,
          (sum, inv) => sum + (inv.totalAmount ?? 0),
        );

        return DataRow(
          cells: [
            DataCell(
              Text(collection.collectionName ?? 'N/A'),
              onTap: () => _navigateToCollectionDetails(context, collection),
            ),
            DataCell(
              Text(invoiceNumbers),
              onTap: () {
                if (invoices.isNotEmpty) {
                  _navigateToMultipleInvoices(context, invoices);
                }
              },
            ),
            DataCell(
              Text(collection.deliveryData?.deliveryNumber ?? 'N/A'),
              onTap: () => _navigateToCollectionDetails(context, collection),
            ),
            DataCell(
              Text(_formatDate(collection.created)),
              onTap: () => _navigateToCollectionDetails(context, collection),
            ),
            DataCell(
              Text(_formatAmount(collection.totalAmount)),
              onTap: () => _navigateToCollectionDetails(context, collection),
            ),
            DataCell(
              Text(_formatAmount(confirmedTotal)),
              onTap: () => _navigateToCollectionDetails(context, collection),
            ),
            DataCell(
              Text(collection.status ?? 'Completed'),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    tooltip: 'View Collection Details',
                    onPressed: () =>
                        _navigateToCollectionDetails(context, collection),
                  ),
                  if (invoices.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.receipt, color: Colors.green),
                      tooltip: 'View Invoices',
                      onPressed: () =>
                          _navigateToMultipleInvoices(context, invoices),
                    ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    tooltip: 'View PDF',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'PDF viewer for ${collection.collectionName ?? 'collection'} coming soon',
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.purple),
                    tooltip: 'Print Collection Receipt',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Printing receipt for ${collection.collectionName ?? 'collection'}...',
                          ),
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
        _showFilterDialog(context);
      },
      dataLength: '${collections.length}',
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

  void _navigateToCollectionDetails(
      BuildContext context, CollectionEntity collection) {
    if (collection.id != null) {
      context.go('/collections/${collection.id}');
    }
  }

  void _navigateToMultipleInvoices(
      BuildContext context, List<dynamic> invoices) {
    // Navigate to a page showing a list of invoices
    // Example route: /invoices?ids=[...]
    final ids = invoices.map((inv) => inv.id).join(',');
    context.go('/invoices?ids=$ids');

    // Optionally dispatch event for each invoice
    for (final inv in invoices) {
      if (inv.id != null) {
        context
            .read<InvoiceDataBloc>()
            .add(GetInvoiceDataByIdEvent(inv.id!));
      }
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Filter Collections'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Collection Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'From Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'To Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min Amount',
                          border: OutlineInputBorder(),
                          prefixText: '₱ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Max Amount',
                          border: OutlineInputBorder(),
                          prefixText: '₱ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Clear'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Apply'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filters applied')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
