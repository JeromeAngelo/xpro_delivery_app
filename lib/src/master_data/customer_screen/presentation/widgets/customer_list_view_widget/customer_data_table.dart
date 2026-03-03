import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CustomerDataTable extends StatelessWidget {
  final List<CustomerDataEntity> customers;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const CustomerDataTable({
    super.key,
    required this.customers,
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
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return DataTableLayout(
      title: 'Customers',
      searchBar: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, province, or municipality...',
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create customer screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create customer feature coming soon')),
        );
      },
      createButtonText: 'Create Customer',
      columns: [
        DataColumn(label: Text('ID', style: headerStyle)),
        DataColumn(label: Text('Name', style: headerStyle)),
        DataColumn(label: Text('Reference ID', style: headerStyle)),
        DataColumn(label: Text('Location', style: headerStyle)),
        DataColumn(label: Text('Has Coordinates', style: headerStyle)),
        DataColumn(label: Text('Actions', style: headerStyle)),
      ],
      rows:
          customers.map((customer) {
            return DataRow(
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
                  Text(_formatAddress(customer)),
                  onTap: () => _navigateToCustomerDetails(context, customer),
                ),
                DataCell(
                  _buildLocationStatusChip(customer),
                  onTap: () => _navigateToCustomerDetails(context, customer),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {
                          // View customer details
                          _navigateToCustomerDetails(context, customer);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () {
                          // Edit customer
                          _showEditCustomerDialog(context, customer);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () {
                          // Delete customer
                          _showDeleteConfirmationDialog(context, customer);
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
      
      dataLength: '${customers.length}', 
      onDeleted: () {},
    );
  }

  String _formatAddress(CustomerDataEntity customer) {
    final parts = [
      customer.barangay,
      customer.municipality,
      customer.province,
    ].where((part) => part != null && part.isNotEmpty).toList();

    return parts.join(', ');
  }

  Widget _buildLocationStatusChip(CustomerDataEntity customer) {
    final hasLocation = customer.latitude != null && customer.longitude != null;
    
    return Chip(
      avatar: Icon(
        hasLocation ? Icons.check_circle : Icons.cancel,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        hasLocation ? 'Yes' : 'No',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: hasLocation ? Colors.green : Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showEditCustomerDialog(BuildContext context, CustomerDataEntity customer) {
    // This would be implemented to show a dialog for editing customer
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit customer: ${customer.name}'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    CustomerDataEntity customer,
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
                Text('Are you sure you want to delete ${customer.name}?'),
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
                if (customer.id != null) {
                  context.read<CustomerDataBloc>().add(
                    DeleteCustomerDataEvent(customer.id!),
                  );
                  // Refresh the list after deletion
                  context.read<CustomerDataBloc>().add(
                    const GetAllCustomerDataEvent(),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToCustomerDetails(
    BuildContext context,
    CustomerDataEntity customer,
  ) {
    if (customer.id != null) {
      context.go('/customer/${customer.id}');
    }
  }
}
