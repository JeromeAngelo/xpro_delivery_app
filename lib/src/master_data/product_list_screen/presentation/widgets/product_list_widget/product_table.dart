import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/master_data/product_list_screen/presentation/widgets/product_list_widget/product_search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProductDataTable extends StatelessWidget {
  final List<InvoiceItemsEntity> products;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ProductDataTable({
    super.key,
    required this.products,
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
      title: 'Products',
      searchBar: ProductSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create product screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create product feature coming soon')),
        );
      },
      createButtonText: 'Create Product',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Brand')),
        DataColumn(label: Text('Reference ID')),
        DataColumn(label: Text('UOM')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('UOM Price')),
        DataColumn(label: Text('Total Amount')),
        DataColumn(label: Text('Actions')),
      ],
      rows: products.map((product) {
        return DataRow(
          cells: [
            DataCell(
              Text(product.id?.substring(0, 8) ?? 'N/A'),
            ),
            DataCell(
              Text(product.name ?? 'N/A'),
            ),
            DataCell(
              Text(product.brand ?? 'N/A'),
            ),
            DataCell(
              Text(product.refId ?? 'N/A'),
            ),
            DataCell(
              Text(product.uom ?? 'N/A'),
            ),
            DataCell(
              Text(_formatQuantity(product.quantity)),
            ),
            DataCell(
              Text(_formatCurrency(product.uomPrice)),
            ),
            DataCell(
              Text(_formatCurrency(product.totalAmount)),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    tooltip: 'View Details',
                    onPressed: () {
                      
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    tooltip: 'Edit',
                    onPressed: () {
                      // Edit product
                      if (product.id != null) {
                        // Navigate to edit screen with product data
                        context.go('/product/edit/${product.id}');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () {
                      // Show confirmation dialog before deleting
                      _showDeleteConfirmationDialog(context, product);
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
     
      dataLength: '${products.length}',
      onDeleted: () {},
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';

    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    if (amount is double) {
      return formatter.format(amount);
    } else if (amount is int) {
      return formatter.format(amount.toDouble());
    } else if (amount is String) {
      try {
        return formatter.format(double.parse(amount));
      } catch (_) {
        return amount;
      }
    }
    return amount.toString();
  }

  String _formatQuantity(dynamic quantity) {
    if (quantity == null) return 'N/A';
    
    if (quantity is double) {
      return quantity.toStringAsFixed(2);
    } else if (quantity is int) {
      return quantity.toString();
    } else if (quantity is String) {
      try {
        return double.parse(quantity).toStringAsFixed(2);
      } catch (_) {
        return quantity;
      }
    }
    return quantity.toString();
  }

  // void _navigateToProductDetails(BuildContext context, InvoiceItemsEntity product) {
  //   if (product.id != null) {
  //     // First, dispatch the event to load the product data
  //     context.read<InvoiceItemsBloc>().add(GetInvoiceItemsByInvoiceDataId(product.));

  //     // Then navigate to the specific product screen
  //     context.go('/product/${product.id}');
  //   }
  // }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    InvoiceItemsEntity product,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete product "${product.name}"?',
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
                
              },
            ),
          ],
        );
      },
    );
  }
}
