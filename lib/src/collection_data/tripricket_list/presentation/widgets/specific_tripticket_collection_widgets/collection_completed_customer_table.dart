// ignore_for_file: unused_local_variable

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/core/enums/mode_of_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_state.dart';

class CollectionCompletedCustomersTable extends StatefulWidget {
  final String tripId;
  final List<CollectionEntity> completedCustomers;
  final bool isLoading;

  const CollectionCompletedCustomersTable({
    super.key,
    required this.tripId,
    required this.completedCustomers,
    required this.isLoading,
  });

  @override
  State<CollectionCompletedCustomersTable> createState() =>
      _CollectionCompletedCustomersTableState();
}

class _CollectionCompletedCustomersTableState
    extends State<CollectionCompletedCustomersTable> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionsBloc, CollectionsState>(
      builder: (context, state) {
        // Filter customers based on search query
        List<CollectionEntity> collections = [];
        bool loading = widget.isLoading;
        String? errorMessage;

        if (state is CollectionsLoading) {
          loading = true;
        } else if (state is CollectionLoadedByTrip &&
            state.tripId == widget.tripId) {
          collections = state.collections;
          loading = false;
        } else if (state is CollectionsError) {
          errorMessage = state.message;
          loading = false;
        }

        // Format currency
        final currencyFormatter = NumberFormat.currency(
          symbol: '₱',
          decimalDigits: 2,
        );
        return DataTableLayout(
          title: 'Completed Customers',
          searchBar: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by store name, delivery number, or owner...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          onCreatePressed: null, // No create button for collections view
          columns: const [
            //  DataColumn(label: Text('Delivery #')),
            DataColumn(label: Text('Store Name')),
            DataColumn(label: Text('Owner')),
            DataColumn(label: Text('Invoices')), // ✅ added
         //   DataColumn(label: Text('Mode of Payment')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Completed At')),
            DataColumn(label: Text('Actions')),
          ],
          rows:
              collections.map((customer) {
                final deliveryData = customer.deliveryData;
              //  final customerData = customer.customer;

                return DataRow(
                  cells: [
                    DataCell(
                      Text(deliveryData!.deliveryNumber ?? 'N/A'),
                      onTap: () => _navigateToCustomerData(context, customer),
                    ),
                    DataCell(
                      Text(deliveryData.customer!.name ?? 'N/A'),
                      onTap: () => _navigateToCustomerData(context, customer),
                    ),
                    DataCell(
                      Text(_formatInvoiceNumbers(customer)), // ✅ added
                      onTap: () => _navigateToCustomerData(context, customer),
                    ),

                    //DataCell(_buildModeOfPaymentChip(customer. ?? 'N/A')),
                    DataCell(
                      Text(
                        customer.totalAmount != null
                            ? currencyFormatter.format(customer.totalAmount)
                            : 'N/A',
                      ),
                      onTap: () => _navigateToCustomerData(context, customer),
                    ),
                    DataCell(
                      Text(
                        customer.created != null
                            ? DateFormat(
                              'MMM dd, yyyy hh:mm a',
                            ).format(customer.created!)
                            : 'N/A',
                      ),
                      onTap: () => _navigateToCustomerData(context, customer),
                    ),
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
                              // View customer details
                              _showCustomerDetailsDialog(context, customer);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.print, color: Colors.green),
                            tooltip: 'Print Receipt',
                            onPressed: () {
                              // Print receipt
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Printing receipt...'),
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
          currentPage: _currentPage,
          totalPages: _totalPages,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          isLoading: widget.isLoading,
          dataLength: '${collections.length}',
          onDeleted: () {},
        );
      },
    );
  }

  String _formatInvoiceNumbers(CollectionEntity collections) {
    if (collections.invoices != null && collections.invoices!.isNotEmpty) {
      if (collections.invoices!.length == 1) {
        return collections.invoices!.first.name ?? 'N/A';
      } else {
        return '${collections.invoices!.length} invoices';
      }
    } else if (collections.invoice?.name != null) {
      return collections.invoice!.name!;
    }
    return 'N/A';
  }

  // Format mode of payment from enum to readable text
  String _formatModeOfPayment(String? modeOfPaymentStr) {
    if (modeOfPaymentStr == null) return 'N/A';

    try {
      // Try to parse the string to the enum
      ModeOfPayment? modeOfPayment;

      // Handle both enum name and raw string cases
      if (modeOfPaymentStr == 'cashOnDelivery' ||
          modeOfPaymentStr == 'Cash On Delivery') {
        modeOfPayment = ModeOfPayment.cashOnDelivery;
      } else if (modeOfPaymentStr == 'bankTransfer' ||
          modeOfPaymentStr == 'Bank Transfer') {
        modeOfPayment = ModeOfPayment.bankTransfer;
      } else if (modeOfPaymentStr == 'cheque' || modeOfPaymentStr == 'Cheque') {
        modeOfPayment = ModeOfPayment.cheque;
      } else if (modeOfPaymentStr == 'eWallet' ||
          modeOfPaymentStr == 'E-Wallet') {
        modeOfPayment = ModeOfPayment.eWallet;
      }

      if (modeOfPayment != null) {
        switch (modeOfPayment) {
          case ModeOfPayment.cashOnDelivery:
            return 'Cash On Delivery';
          case ModeOfPayment.bankTransfer:
            return 'Bank Transfer';
          case ModeOfPayment.cheque:
            return 'Cheque';
          case ModeOfPayment.eWallet:
            return 'E-Wallet';
        }
      }

      // If we couldn't parse it as an enum, format the string directly
      return modeOfPaymentStr
          .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
          .replaceAllMapped(
            RegExp(r'^([a-z])'),
            (match) => match.group(0)!.toUpperCase(),
          );
    } catch (e) {
      // If any error occurs, return the original string
      return modeOfPaymentStr;
    }
  }

  void _showCustomerDetailsDialog(
    BuildContext context,
    CollectionEntity customer,
  ) {
    // Format currency
    final currencyFormatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(customer.customer!.name ?? 'Customer Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'Delivery Number',
                    customer.deliveryData!.deliveryNumber ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Owner Name',
                    customer.customer!.name ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Contact',
                    customer.customer!.contactNumber ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Address',
                    customer.customer!.province ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Municipality',
                    customer.customer!.municipality ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Province',
                    customer.customer!.province ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Mode of Payment',
                    _formatModeOfPayment(customer.customer!.paymentMode),
                  ),
                  _buildDetailRow(
                    'Completed At',
                    customer.created != null
                        ? DateFormat(
                          'MMM dd, yyyy hh:mm a',
                        ).format(customer.created!)
                        : 'N/A',
                  ),
                  _buildDetailRow(
                    'Total Amount',
                    customer.totalAmount != null
                        ? currencyFormatter.format(customer.totalAmount)
                        : 'N/A',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Printing receipt...')),
                  );
                },
                child: const Text('Print Receipt'),
              ),
            ],
          ),
    );
  }

  // Widget _buildModeOfPaymentChip(String? modeOfPaymentStr) {
  //   // Default values
  //   Color backgroundColor = Colors.grey[100]!;
  //   Color textColor = Colors.grey[800]!;
  //   String label = 'N/A';
  //   IconData icon = Icons.help_outline;

  //   if (modeOfPaymentStr != null) {
  //     String paymentMode = _formatModeOfPayment(modeOfPaymentStr);

  //     switch (paymentMode) {
  //       case 'Cash On Delivery':
  //         backgroundColor = Colors.green[100]!;
  //         textColor = Colors.green[800]!;
  //         label = 'COD';
  //         icon = Icons.payments;
  //         break;
  //       case 'Bank Transfer':
  //         backgroundColor = Colors.blue[100]!;
  //         textColor = Colors.blue[800]!;
  //         label = 'Bank';
  //         icon = Icons.account_balance;
  //         break;
  //       case 'Cheque':
  //         backgroundColor = Colors.purple[100]!;
  //         textColor = Colors.purple[800]!;
  //         label = 'Cheque';
  //         icon = Icons.money;
  //         break;
  //       case 'E-Wallet':
  //         backgroundColor = Colors.orange[100]!;
  //         textColor = Colors.orange[800]!;
  //         label = 'E-Wallet';
  //         icon = Icons.account_balance_wallet;
  //         break;
  //       default:
  //         label = paymentMode;
  //     }
  //   }

  //   return Chip(
  //     avatar: Icon(icon, size: 16, color: textColor),
  //     label: Text(
  //       label,
  //       style: TextStyle(
  //         color: textColor,
  //         fontSize: 12,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //     backgroundColor: backgroundColor,
  //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
  //     visualDensity: VisualDensity.compact,
  //     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //   );
  // }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _navigateToCustomerData(
    BuildContext context,
    CollectionEntity customer,
  ) {
    if (customer.id != null) {
      context.read<CollectionsBloc>().add(GetCollectionByIdEvent(customer.id!));

      context.go('/completed-customers/:{$customer.id}');
    }
  }
}
