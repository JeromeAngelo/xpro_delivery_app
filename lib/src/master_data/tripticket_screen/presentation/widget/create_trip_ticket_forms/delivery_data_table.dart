import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/dynamic_table.dart';

class DeliveryDataTable extends StatefulWidget {
  final List<DeliveryDataModel> selectedDeliveries;
  final Function(List<DeliveryDataModel>) onDeliveriesChanged;

  const DeliveryDataTable({
    super.key,
    required this.selectedDeliveries,
    required this.onDeliveriesChanged,
  });

  @override
  State<DeliveryDataTable> createState() => _DeliveryDataTableState();
}

class _DeliveryDataTableState extends State<DeliveryDataTable> {
  List<DeliveryDataModel> _allDeliveries = [];
  Set<String> _selectedDeliveryIds = {};

  @override
  void initState() {
    super.initState();
    // Initialize selected deliveries from props
    _selectedDeliveryIds =
        widget.selectedDeliveries.map((d) => d.id ?? '').toSet();
    // Load all delivery data
    _refreshDeliveryData();
  }

  void _refreshDeliveryData() {
    context.read<DeliveryDataBloc>().add(const GetAllDeliveryDataEvent());
  }

  @override
  void didUpdateWidget(DeliveryDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDeliveries != widget.selectedDeliveries) {
      _selectedDeliveryIds =
          widget.selectedDeliveries.map((d) => d.id ?? '').toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black, // or any color you prefer
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Deliveries',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshDeliveryData,
              tooltip: 'Refresh delivery data',
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 500, // Fixed height for the table container
          child: BlocConsumer<DeliveryDataBloc, DeliveryDataState>(
            listener: (context, state) {
              if (state is AllDeliveryDataLoaded) {
                setState(() {
                  _allDeliveries =
                      state.deliveryData
                          .map((delivery) => delivery as DeliveryDataModel)
                          .toList();

                  // Update selected deliveries to parent
                  final selectedDeliveries =
                      _allDeliveries
                          .where(
                            (d) =>
                                d.id != null &&
                                _selectedDeliveryIds.contains(d.id),
                          )
                          .toList();
                  widget.onDeliveriesChanged(selectedDeliveries);
                });
              }
            },
            builder: (context, state) {
              // Define the table columns once to reuse
              final columns = [
                DataColumn(label: Text('Select', style: headerStyle)),
                DataColumn(label: Text('Customer', style: headerStyle)),
                DataColumn(label: Text('Invoices', style: headerStyle)),
                DataColumn(label: Text('Total Amount', style: headerStyle)),
                DataColumn(label: Text('Document Date', style: headerStyle)),
                DataColumn(label: Text('Reference ID', style: headerStyle)),
              ];

              if (state is DeliveryDataLoading) {
                return _buildShimmerLoadingTable(columns);
              }

              if (state is DeliveryDataError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshDeliveryData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Show empty table with message if no data
              if (_allDeliveries.isEmpty) {
                return _buildEmptyTable(columns);
              }

              // Show table with data
              return DynamicDataTable<DeliveryDataModel>(
                data: _allDeliveries,

                columnBuilder: (context) => columns,
                rowBuilder: (delivery, index) {
                  final isSelected =
                      delivery.id != null &&
                      _selectedDeliveryIds.contains(delivery.id);

                  return DataRow(
                    selected: isSelected,
                    cells: [
                      DataCell(
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (delivery.id != null) {
                                if (value == true) {
                                  _selectedDeliveryIds.add(delivery.id!);
                                } else {
                                  _selectedDeliveryIds.remove(delivery.id!);
                                }

                                // Update selected deliveries to parent
                                final selectedDeliveries =
                                    _allDeliveries
                                        .where(
                                          (d) =>
                                              d.id != null &&
                                              _selectedDeliveryIds.contains(
                                                d.id,
                                              ),
                                        )
                                        .toList();
                                widget.onDeliveriesChanged(selectedDeliveries);
                              }
                            });
                          },
                        ),
                      ),
                      DataCell(Text(delivery.customer?.name ?? 'N/A')),
                      DataCell(
                        SizedBox(
                          width: 150,
                          height: 40, // Fixed height for the cell
                          child:
                              delivery.invoices != null &&
                                      delivery.invoices!.isNotEmpty
                                  ? delivery.invoices!.length > 1
                                      ? SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children:
                                              delivery.invoices!.map((invoice) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 2.0,
                                                      ),
                                                  child: Text(
                                                    invoice.name ?? 'N/A',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      )
                                      : Text(
                                        delivery.invoices!.first.name ?? 'N/A',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                  : delivery.invoice != null
                                  ? Text(
                                    delivery.invoice!.name ?? 'N/A',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                  : const Text('N/A'),
                        ),
                      ),
                      DataCell(
                        Text(
                          delivery.invoices != null &&
                                  delivery.invoices!.isNotEmpty
                              ? '₱${delivery.invoices!.fold<double>(0.0, (sum, invoice) => sum + (invoice.totalAmount ?? 0.0)).toStringAsFixed(2)}'
                              : delivery.invoice?.totalAmount != null
                              ? '₱${delivery.invoice!.totalAmount!.toStringAsFixed(2)}'
                              : 'N/A',
                        ),
                      ),
                      DataCell(
                        Text(
                          delivery.invoices != null &&
                                  delivery.invoices!.isNotEmpty
                              ? _formatDate(
                                delivery.invoices!
                                    .map((invoice) => invoice.documentDate)
                                    .where((date) => date != null)
                                    .fold<DateTime?>(
                                      null,
                                      (latest, date) =>
                                          latest == null ||
                                                  date!.isAfter(latest)
                                              ? date
                                              : latest,
                                    ),
                              )
                              : _formatDate(delivery.invoice?.documentDate),
                        ),
                      ),
                      DataCell(Text(delivery.refID ?? 'N/A')),
                    ],
                  );
                },
                isLoading: false,
                emptyMessage: 'No delivery data available',
                buttonPlaceholder: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total amount display - always visible
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calculate,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total Amount: ${_calculateSelectedDeliveriesTotal()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Remove button - only show when items are selected
                    if (_selectedDeliveryIds.isNotEmpty)
                      ElevatedButton.icon(
                        // In the remove delivery data button's onPressed callback:
                        onPressed: () {
                          // Show confirmation dialog before deleting
                          showDialog(
                            context: context,
                            builder:
                                (dialogContext) => AlertDialog(
                                  title: const Text('Confirm Deletion'),
                                  content: const Text(
                                    'Are you sure you want to delete the selected delivery data? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(dialogContext).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();

                                        // Get the IDs of selected delivery data
                                        final selectedIds =
                                            _selectedDeliveryIds.toList();

                                        // Delete each selected delivery data
                                        for (final id in selectedIds) {
                                          context.read<DeliveryDataBloc>().add(
                                            DeleteDeliveryDataEvent(id),
                                          );
                                        }

                                        // Clear selection after deletion
                                        setState(() {
                                          _selectedDeliveryIds.clear();
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                          );
                        },

                        icon: const Icon(Icons.delete),
                        label: Text(
                          'Remove ${_selectedDeliveryIds.length} Selected',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Build an empty table with headers and a message
  Widget _buildEmptyTable(List<DataColumn> columns) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          // Table headers
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: const [], // No rows
              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            ),
          ),

          // Empty state message
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No delivery data available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add preset groups to create deliveries',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshDeliveryData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a shimmer loading effect table
  Widget _buildShimmerLoadingTable(List<DataColumn> columns) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          // Table headers
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: const [], // No rows while loading
              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            ),
          ),

          // Shimmer loading effect for rows
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                itemCount: 5, // Show 5 shimmer rows
                itemBuilder:
                    (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          // Checkbox placeholder
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Customer name placeholder
                          Container(
                            width: 120,
                            height: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 32),
                          // Invoice placeholder
                          Container(
                            width: 100,
                            height: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 32),
                          // Amount placeholder
                          Container(width: 80, height: 20, color: Colors.white),
                          const SizedBox(width: 32),
                          // Date placeholder
                          Container(
                            width: 120,
                            height: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calculate total amount for all deliveries
  String _calculateSelectedDeliveriesTotal() {
    double totalAmount = 0.0;

    // Calculate total from all deliveries (not just selected ones)
    for (final delivery in _allDeliveries) {
      if (delivery.invoices != null && delivery.invoices!.isNotEmpty) {
        // Sum all invoices in the delivery
        totalAmount += delivery.invoices!.fold<double>(
          0.0,
          (sum, invoice) => sum + (invoice.totalAmount ?? 0.0),
        );
      } else if (delivery.invoice?.totalAmount != null) {
        // Fallback to single invoice
        totalAmount += delivery.invoice!.totalAmount!;
      }
    }

    // Format with commas and currency symbol
    final formatter = NumberFormat('#,##0.00');
    return '₱${formatter.format(totalAmount)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      // Change the format from "MMM dd, yyyy hh:mm a" to "MM/dd/yyyy hh:mm a"
      return DateFormat('MM/dd/yyyy hh:mm a').format(date);
    } catch (e) {
      debugPrint('❌ Error formatting date: $e');
      return 'Invalid Date';
    }
  }
}
