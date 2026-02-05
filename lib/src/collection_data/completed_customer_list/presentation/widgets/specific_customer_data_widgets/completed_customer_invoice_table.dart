import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';

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
    // ✅ flatten collections -> invoice rows (toMany)
    final List<_InvoiceRow> rows = _buildInvoiceRows(collections);

    return DataTableLayout(
      title: 'Collection Invoices',
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Document Date')),
        DataColumn(label: Text('Total Amount')),
        DataColumn(label: Text('Delivery Number')),
        DataColumn(label: Text('Collection Date')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows:
          rows.map((row) {
            final inv = row.invoice;
            final collection = row.collection;

            return DataRow(
              cells: [
                DataCell(
                  Text(inv.name ?? 'N/A'),
                  onTap:
                      () => _navigateToCollectionDetails(context, collection),
                ),
                DataCell(
                  Text(_formatDate(inv.documentDate)),
                  onTap:
                      () => _navigateToCollectionDetails(context, collection),
                ),
                DataCell(
                  Text(_formatAmount(inv.totalAmount)),
                  onTap:
                      () => _navigateToCollectionDetails(context, collection),
                ),
                DataCell(
                  Text(collection.deliveryData?.deliveryNumber ?? 'N/A'),
                  onTap:
                      () => _navigateToCollectionDetails(context, collection),
                ),
                DataCell(
                  Text(_formatDate(collection.created)),
                  onTap:
                      () => _navigateToCollectionDetails(context, collection),
                ),
                DataCell(Text(collection.status ?? 'Completed')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Collection Details',
                        onPressed:
                            () => _navigateToCollectionDetails(
                              context,
                              collection,
                            ),
                      ),

                      // ✅ optional: go to a single invoice view if you have it
                      if (inv.id != null && inv.id!.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.receipt_long,
                            color: Colors.green,
                          ),
                          tooltip: 'View Invoice',
                          onPressed:
                              () => _navigateToSingleInvoice(context, inv),
                        ),

                      // IconButton(
                      //   icon: const Icon(
                      //     Icons.picture_as_pdf,
                      //     color: Colors.red,
                      //   ),
                      //   tooltip: 'View PDF',
                      //   onPressed: () {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       SnackBar(
                      //         content: Text(
                      //           'PDF viewer for ${collection.collectionName ?? 'collection'} coming soon',
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
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
      onFiltered: () => _showFilterDialog(context),
      dataLength: '${rows.length}', // ✅ now invoice rows count
      onDeleted: () {},
    );
  }

  // ✅ Builds row-per-invoice from toMany invoices
  List<_InvoiceRow> _buildInvoiceRows(List<CollectionEntity> collections) {
    final List<_InvoiceRow> rows = [];

    for (final c in collections) {
      final invoices = c.invoices ?? const <InvoiceDataEntity>[];

      // If no invoices, you can choose to skip or show a placeholder row.
      // Here: skip empty collections
      if (invoices.isEmpty) continue;

      for (final inv in invoices) {
        rows.add(_InvoiceRow(collection: c, invoice: inv));
      }
    }

    return rows;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return 'Invalid Date';
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return 'N/A';
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return formatter.format(amount);
  }

  void _navigateToCollectionDetails(
    BuildContext context,
    CollectionEntity collection,
  ) {
    if (collection.id != null && collection.id!.isNotEmpty) {
      context.go('/collections/${collection.id}');
    }
  }

  void _navigateToSingleInvoice(BuildContext context, InvoiceDataEntity inv) {
    if (inv.id == null || inv.id!.isEmpty) return;

    // ✅ adjust to your real route if different
    context.go('/invoice/${inv.id}');

    // Optional: dispatch fetch for this invoice
    context.read<InvoiceDataBloc>().add(GetInvoiceDataByIdEvent(inv.id!));
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

// ✅ internal helper row: keeps both invoice + its parent collection
class _InvoiceRow {
  final CollectionEntity collection;
  final InvoiceDataEntity invoice;

  const _InvoiceRow({required this.collection, required this.invoice});
}
