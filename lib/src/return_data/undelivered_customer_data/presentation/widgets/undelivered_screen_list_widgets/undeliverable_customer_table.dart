import 'package:xpro_delivery_admin_app/src/return_data/undelivered_customer_data/presentation/widgets/undelivered_screen_list_widgets/undeliverable_customer_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/core/enums/undeliverable_reason.dart';
import 'package:intl/intl.dart';

class UndeliveredCustomerTable extends StatefulWidget {
  final List<CancelledInvoiceEntity> cancelledInvoices;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const UndeliveredCustomerTable({
    super.key,
    required this.cancelledInvoices,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  State<UndeliveredCustomerTable> createState() =>
      _UndeliveredCustomerTableState();
}

class _UndeliveredCustomerTableState extends State<UndeliveredCustomerTable> {
  // Track selected rows for bulk actions
  Set<String> _selectedRows = {};
  bool _selectAll = false;

  //try

  @override
  Widget build(BuildContext context) {
    // Debug the data
    for (var cancelledInvoice in widget.cancelledInvoices) {
      debugPrint(
        '📋 Cancelled Invoice: ${cancelledInvoice.customer?.name} | Reason: ${cancelledInvoice.reason?.name}',
      );
    }

    return BlocListener<CancelledInvoiceBloc, CancelledInvoiceState>(
      listener: (context, state) {
        if (state is CancelledInvoiceTripReassigned) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Successfully reassigned delivery: ${state.deliveryDataId}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          context.go('/tripticket-create');
        } else if (state is CancelledInvoiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Error: ${state.message}')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: DataTableLayout(
        title: 'Undeliverable Customers',
        searchBar: UndeliveredCustomerSearchBar(
          controller: widget.searchController,
          searchQuery: widget.searchQuery,
          onSearchChanged: widget.onSearchChanged,
        ),
        onCreatePressed: () {
          context.go('/undeliverable-customers/create');
        },
        createButtonText: 'Add Undeliverable Customer',
        columns: _buildColumns(),
        rows: _buildRows(),
        currentPage: widget.currentPage,
        totalPages: widget.totalPages,
        onPageChanged: widget.onPageChanged,
        isLoading: widget.isLoading,
        onFiltered: () {
          _showFilterDialog(context);
        },
        dataLength: '${widget.cancelledInvoices.length}',
        onDeleted: () {
          _showBulkDeleteDialog(context);
        },

        // Add this callback to sync selection states
        onRowsSelected: (selectedRowIndices) {
          setState(() {
            _selectedRows.clear();
            for (int index in selectedRowIndices) {
              if (index < widget.cancelledInvoices.length) {
                final invoice = widget.cancelledInvoices[index];
                if (invoice.id != null) {
                  _selectedRows.add(invoice.id!);
                }
              }
            }
            _selectAll =
                _selectedRows.length == widget.cancelledInvoices.length;
          });
        },

        // Custom action for bulk reassign
        showCustomAction: true,
        customActionIcon: Icons.assignment_return,
        customActionTooltip: 'Re-assign Selected to Trip',
        customActionColor: Colors.orange,
        onCustomAction: _handleBulkReassignFromTable,
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      // Select All Checkbox
      const DataColumn(label: Text('Store Name')),
      const DataColumn(label: Text('Delivery Number')),
      const DataColumn(label: Text('Address')),
      const DataColumn(label: Text('Reason')),
      const DataColumn(label: Text('Time')),
      const DataColumn(label: Text('Actions')),
    ];
  }

  List<DataRow> _buildRows() {
    return widget.cancelledInvoices.map((cancelledInvoice) {
      final isSelected = _selectedRows.contains(cancelledInvoice.id);

      return DataRow(
        selected: isSelected,
        onSelectChanged: (selected) {
          if (cancelledInvoice.id != null) {
            setState(() {
              if (selected == true) {
                _selectedRows.add(cancelledInvoice.id!);
              } else {
                _selectedRows.remove(cancelledInvoice.id!);
              }
              _selectAll =
                  _selectedRows.length == widget.cancelledInvoices.length;
            });
          }
        },
        cells: [
          // Checkbox Cell
          DataCell(
            Text(cancelledInvoice.customer?.name ?? 'N/A'),
            onTap:
                () => _onNavigateToSpecificCancelledInvoice(
                  cancelledInvoice,
                  context,
                ),
          ),
          DataCell(
            Text(cancelledInvoice.deliveryData?.deliveryNumber ?? 'N/A'),
            onTap:
                () => _onNavigateToSpecificCancelledInvoice(
                  cancelledInvoice,
                  context,
                ),
          ),
          DataCell(
            Text(_formatAddress(cancelledInvoice)),
            onTap:
                () => _onNavigateToSpecificCancelledInvoice(
                  cancelledInvoice,
                  context,
                ),
          ),
          DataCell(
            _buildReasonChip(cancelledInvoice.reason),
            onTap:
                () => _onNavigateToSpecificCancelledInvoice(
                  cancelledInvoice,
                  context,
                ),
          ),
          DataCell(
            Text(_formatDate(cancelledInvoice.created)),
            onTap:
                () => _onNavigateToSpecificCancelledInvoice(
                  cancelledInvoice,
                  context,
                ),
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Details',
                  onPressed: () {
                    // View cancelled invoice details
                    if (cancelledInvoice.id != null) {
                      context.go(
                        '/undeliverable-customers/${cancelledInvoice.id}',
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.assignment_return,
                    color: Colors.orange,
                  ),
                  tooltip: 'Re-assign to Trip',
                  onPressed: () {
                    _showSingleReassignDialog(context, cancelledInvoice);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit',
                  onPressed: () {
                    // Edit cancelled invoice
                    if (cancelledInvoice.id != null) {
                      context.go(
                        '/undeliverable-customers/edit/${cancelledInvoice.id}',
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () {
                    // Show confirmation dialog before deleting
                    _showDeleteConfirmationDialog(context, cancelledInvoice);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  // Add this method to handle bulk reassign from DataTableLayout's custom action
  void _handleBulkReassignFromTable() {
    if (_selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one invoice to re-assign'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedInvoices =
        widget.cancelledInvoices
            .where((invoice) => _selectedRows.contains(invoice.id))
            .toList();

    _showBulkReassignDialog(context, selectedInvoices);
  }

  // Update the existing _showBulkReassignDialog to accept selectedInvoices parameter
  void _showBulkReassignDialog(
    BuildContext context, [
    List<CancelledInvoiceEntity>? selectedInvoices,
  ]) {
    final invoicesToProcess =
        selectedInvoices ??
        widget.cancelledInvoices
            .where((invoice) => _selectedRows.contains(invoice.id))
            .toList();

    if (invoicesToProcess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one invoice to re-assign'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.assignment_return, color: Colors.orange),
              SizedBox(width: 8),
              Text('Re-assign to Trip'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to re-assign ${invoicesToProcess.length} cancelled invoice(s) back to their respective trips?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Selected Invoices (${invoicesToProcess.length}):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...invoicesToProcess
                          .take(5)
                          .map(
                            (invoice) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_right,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${invoice.customer?.name ?? 'Unknown'} - ${invoice.invoice?.name ?? 'N/A'}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (invoicesToProcess.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '... and ${invoicesToProcess.length - 5} more invoices',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue[700],
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will mark all selected invoices as "rescheduled" and make them available for delivery again.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performBulkReassign(context, invoicesToProcess);
              },
              icon: const Icon(Icons.assignment_return),
              label: Text('Re-assign ${invoicesToProcess.length} Invoice(s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Update the existing _performBulkReassign method
  void _performBulkReassign(
    BuildContext context,
    List<CancelledInvoiceEntity> invoices,
  ) {
    debugPrint('🔄 Starting bulk reassign for ${invoices.length} invoices');

    int successCount = 0;
    int errorCount = 0;

    for (var invoice in invoices) {
      if (invoice.deliveryData?.id != null) {
        debugPrint(
          '📋 Reassigning invoice: ${invoice.invoice?.name} (DeliveryData: ${invoice.deliveryData!.id})',
        );

        context.read<CancelledInvoiceBloc>().add(
          ReassignTripForCancelledInvoiceEvent(invoice.deliveryData!.id!),
        );
        successCount++;
      } else {
        debugPrint(
          '⚠️ Skipping invoice ${invoice.invoice?.name}: No delivery data ID',
        );
        errorCount++;
      }
    }

    // Show summary message
    if (errorCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Processing ${successCount} invoices. ${errorCount} invoices skipped (missing delivery data).',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Processing ${successCount} invoices for reassignment...',
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Clear selection after initiating bulk action
    setState(() {
      _selectedRows.clear();
      _selectAll = false;
    });
  }

  // NEW: Show single re-assign dialog
  void _showSingleReassignDialog(
    BuildContext context,
    CancelledInvoiceEntity cancelledInvoice,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Re-assign to Trip'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to re-assign this cancelled invoice back to the trip?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice: ${cancelledInvoice.invoice?.name ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Customer: ${cancelledInvoice.customer?.name ?? 'N/A'}',
                    ),
                    Text(
                      'Trip: ${cancelledInvoice.trip?.tripNumberId ?? 'N/A'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performSingleReassign(context, cancelledInvoice);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Re-assign'),
            ),
          ],
        );
      },
    );
  }

  // NEW: Perform single re-assign
  void _performSingleReassign(
    BuildContext context,
    CancelledInvoiceEntity cancelledInvoice,
  ) {
    if (cancelledInvoice.deliveryData?.id != null) {
      context.read<CancelledInvoiceBloc>().add(
        ReassignTripForCancelledInvoiceEvent(
          cancelledInvoice.deliveryData!.id!,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No delivery data ID found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBulkDeleteDialog(BuildContext context) {
    if (_selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item to delete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Selected Items'),
          content: Text(
            'Are you sure you want to delete ${_selectedRows.length} selected item(s)? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Perform bulk delete
                for (String id in _selectedRows) {
                  context.read<CancelledInvoiceBloc>().add(
                    DeleteCancelledInvoiceEvent(id),
                  );
                }
                setState(() {
                  _selectedRows.clear();
                  _selectAll = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add filter options here
              ListTile(
                title: const Text('Filter by Reason'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Implement reason filter
                },
              ),
              ListTile(
                title: const Text('Filter by Date Range'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Implement date range filter
                },
              ),
              ListTile(
                title: const Text('Filter by Trip'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Implement trip filter
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    CancelledInvoiceEntity cancelledInvoice,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Cancelled Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this cancelled invoice? This action cannot be undone.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: ${cancelledInvoice.customer?.name ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Delivery Number: ${cancelledInvoice.deliveryData?.deliveryNumber ?? 'N/A'}',
                    ),
                    Text('Reason: ${cancelledInvoice.reason?.name ?? 'N/A'}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (cancelledInvoice.id != null) {
                  context.read<CancelledInvoiceBloc>().add(
                    DeleteCancelledInvoiceEvent(cancelledInvoice.id!),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _onNavigateToSpecificCancelledInvoice(
    CancelledInvoiceEntity cancelledInvoice,
    BuildContext context,
  ) {
    if (cancelledInvoice.id != null) {
      context.go('/undeliverable-customers/${cancelledInvoice.id}');
    }
  }

  Widget _buildReasonChip(UndeliverableReason? reason) {
  if (reason == null) {
    return Chip(
      label: const Text('No Reason'),
      backgroundColor: Colors.grey[300],
    );
  }

  // Define chip color and readable label
  late Color chipColor;
  late String labelText;

  switch (reason) {
    case UndeliverableReason.customerNotAvailable:
      chipColor = Colors.orange;
      labelText = 'Customer Not Available';
      break;

    case UndeliverableReason.environmentalIssues:
      chipColor = Colors.red;
      labelText = 'Environmental Issues';
      break;

    case UndeliverableReason.none:
      chipColor = Colors.purple;
      labelText = 'No Specific Reason';
      break;

    case UndeliverableReason.storeClosed:
      chipColor = Colors.blue;
      labelText = 'Store Closed';
      break;

    case UndeliverableReason.rescheduled:
      chipColor = Colors.green;
      labelText = 'Rescheduled';
      break;

    case UndeliverableReason.wrongInvoice:
      chipColor = Colors.yellow[700] ?? Colors.yellow;
      labelText = 'Wrong Invoice';
      break;
  }

  return Chip(
    label: Text(
      labelText,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: chipColor,
  );
}


  String _formatAddress(CancelledInvoiceEntity cancelledInvoice) {
    final customer = cancelledInvoice.customer;
    if (customer == null) return 'N/A';

    final parts = <String>[];

    if (customer.municipality != null && customer.municipality!.isNotEmpty) {
      parts.add(customer.municipality!);
    }
    if (customer.province != null && customer.province!.isNotEmpty) {
      parts.add(customer.province!);
    }

    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  // Getter to check if any rows are selected (for DataTableLayout)
  bool get hasSelectedRows => _selectedRows.isNotEmpty;
}
