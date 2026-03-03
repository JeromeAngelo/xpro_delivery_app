import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/status_icons.dart';

class TripCustomersTable extends StatelessWidget {
  final String tripId;
  final VoidCallback? onAttachCustomer;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const TripCustomersTable({
    super.key,
    required this.tripId,
    this.onAttachCustomer,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      builder: (context, state) {
        List<DeliveryDataEntity> deliveries = [];
        bool loading = isLoading;
        String? errorMessage;

        if (state is DeliveryDataLoading) {
          loading = true;
        } else if (state is DeliveryDataByTripLoaded &&
            state.tripId == tripId) {
          deliveries = state.deliveryData;
          loading = false;
        } else if (state is DeliveryDataError) {
          loading = false;
          errorMessage = state.message;
        }

        // Filter deliveries based on search query if needed
        if (searchQuery.isNotEmpty) {
          deliveries =
              deliveries.where((delivery) {
                final customerName =
                    delivery.customer?.name?.toLowerCase() ?? '';
                final invoiceNumber =
                    delivery.invoice?.name?.toLowerCase() ?? '';
                final query = searchQuery.toLowerCase();

                return customerName.contains(query) ||
                    invoiceNumber.contains(query);
              }).toList();
        }

        return DataTableLayout(
          title: 'Deliveries',
          searchBar: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by customer name or invoice number...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: onSearchChanged,
          ),
          onCreatePressed: onAttachCustomer,
          createButtonText: 'Attach Delivery',
          columns: const [
           // DataColumn(label: Text('ID')),
            DataColumn(label: Text('Customer Name')),
            DataColumn(label: Text('Invoice Number')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Total Amount')),
            DataColumn(label: Text('Actions')),
          ],
          rows:
              deliveries.map((delivery) {
                return DataRow(
                  cells: [
                    // ID
                    // DataCell(
                    //   Text(delivery.id ?? 'N/A'),
                    //   onTap:
                    //       () => _navigateToDeliveryDetails(context, delivery),
                    // ),

                    // Customer Name
                    DataCell(
                      Text(delivery.customer?.name ?? 'N/A'),
                      onTap:
                          () => _navigateToDeliveryDetails(context, delivery),
                    ),

                    // Invoice Number
                    DataCell(
                      Text(_formatInvoiceNumbers(delivery)),
                      onTap:
                          () => _navigateToDeliveryDetails(context, delivery),
                    ),

                    // Status
                    DataCell(
                      _buildDeliveryStatusChip(delivery),
                      onTap:
                          () => _navigateToDeliveryDetails(context, delivery),
                    ),

                    // Total Amount
                    DataCell(
                      Text(_formatCurrency(delivery)),
                      onTap:
                          () => _navigateToDeliveryDetails(context, delivery),
                    ),

                    // Actions
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              color: Colors.blue,
                            ),
                            tooltip: 'View Details',
                            onPressed: () {
                              _navigateToDeliveryDetails(context, delivery);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Edit',
                            onPressed: () {
                              // Navigate to edit delivery screen
                              context.go('/delivery/edit/${delivery.id}');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () {
                              _showDeleteDeliveryDialog(context, delivery);
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
          isLoading: loading,
          errorMessage: errorMessage,
          onRetry:
              errorMessage != null
                  ? () => context.read<DeliveryDataBloc>().add(
                    GetDeliveryDataByTripIdEvent(tripId),
                  )
                  : null,
          
          dataLength: '${deliveries.length}',
          onDeleted: () {},
        );
      },
    );
  }

  Widget _buildDeliveryStatusChip(DeliveryDataEntity delivery) {
    // Get the latest status from delivery updates
    String status = "No Status";

    if (delivery.deliveryUpdates.isNotEmpty) {
      // Get the last (most recent) status update
      final latestUpdate = delivery.deliveryUpdates.last;
      status = latestUpdate.title?.toString().split('.').last ?? "No Status";
    }

    // Map status to color
    Color color;
    switch (status.toLowerCase()) {
      case 'arrived':
        color = Colors.blue;
        break;
      case 'unloading':
        color = Colors.amber;
        break;
      case 'undelivered':
      case 'mark as undelivered':
        color = Colors.red;
        break;
      case 'in transit':
        color = Colors.indigo;
        break;
         case 'waiting for customer':
        color = Colors.yellow;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'received':
      case 'mark as received':
        color = Colors.teal;
        break;
      case 'completed':
      case 'end delivery':
        color = Colors.green.shade800;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        break;
    }

    // Get the corresponding icon from StatusIcons
    final IconData statusIcon = StatusIcons.getStatusIcon(status);

    return Chip(
      avatar: Icon(statusIcon, size: 16, color: Colors.white),
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatInvoiceNumbers(DeliveryDataEntity delivery) {
    if (delivery.invoices != null && delivery.invoices!.isNotEmpty) {
      if (delivery.invoices!.length == 1) {
        return delivery.invoices!.first.name ?? 'N/A';
      } else {
        return '${delivery.invoices!.length} invoices';
      }
    } else if (delivery.invoice?.name != null) {
      return delivery.invoice!.name!;
    }
    return 'N/A';
  }

  String _formatCurrency(DeliveryDataEntity delivery) {
    double totalAmount = 0.0;
    
    // Calculate total from all invoices if available
    if (delivery.invoices != null && delivery.invoices!.isNotEmpty) {
      totalAmount = delivery.invoices!.fold<double>(
        0.0, 
        (sum, invoice) => sum + (invoice.totalAmount ?? 0.0),
      );
    } else if (delivery.invoice?.totalAmount != null) {
      // Fallback to single invoice
      totalAmount = delivery.invoice!.totalAmount!;
    } else {
      return 'N/A';
    }
    
    // Format with commas and currency symbol
    final formatter = NumberFormat('#,##0.00');
    return '₱${formatter.format(totalAmount)}';
  }

  void _showDeleteDeliveryDialog(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to remove ${delivery.customer?.name ?? 'this delivery'} from this trip?',
                ),
                const SizedBox(height: 10),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Implement delete functionality
                // This would need a delete event in the DeliveryDataBloc
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete functionality not implemented yet'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToDeliveryDetails(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    if (delivery.id != null) {
      // Navigate to delivery details page
      context.go('/delivery-details/${delivery.id}');
    }
  }

}
