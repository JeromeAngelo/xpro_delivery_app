import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceProductsDataTable extends StatefulWidget {
  final List<InvoiceItemsEntity> products;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback? onAddProduct;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const InvoiceProductsDataTable({
    super.key,
    required this.products,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onAddProduct,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<InvoiceProductsDataTable> createState() =>
      _InvoiceProductsDataTableState();
}

class _InvoiceProductsDataTableState extends State<InvoiceProductsDataTable> {
  @override
  Widget build(BuildContext context) {
    return DataTableLayout(
      title: 'Invoice Products',
      searchBar: TextField(
        controller: widget.searchController,
        decoration: InputDecoration(
          hintText: 'Search products by name or description...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              widget.searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.searchController.clear();
                      widget.onSearchChanged('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: widget.onSearchChanged,
      ),
      onCreatePressed: widget.onAddProduct,
      createButtonText: 'Add Product',
      columns: const [
        DataColumn(label: Text('ID')),

        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Quantity')),
        //    DataColumn(label: Text('Unit Price')),
        DataColumn(label: Text('Total Amount')),
        DataColumn(label: Text('Actions')),
      ],
      rows:
          widget.products.map((product) {
            return DataRow(
              cells: [
                DataCell(Text(product.id ?? 'N/A')),
                DataCell(Text(product.brand ?? 'N/A')),
                DataCell(Text(product.name ?? 'N/A')),
                DataCell(Text(product.quantity.toString())),
                //     DataCell(Text(_formatUnitPrice(product))),
                DataCell(Text(_formatAmount(product.totalAmount))),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {
                          // View product details
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('View product details coming soon'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () {
                          // Edit product
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit product feature coming soon'),
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
      currentPage: widget.currentPage,
      totalPages: widget.totalPages,
      onPageChanged: widget.onPageChanged,
      isLoading: widget.isLoading,
      errorMessage: widget.errorMessage,
      onRetry: widget.onRetry,
     dataLength: '', onDeleted: () {  },
    );
  }

 

  // String _formatUnitPrice(ProductEntity product) {
  //   List<String> prices = [];

  //   if (product.pricePerCase != null && product.pricePerCase! > 0) {
  //     prices.add('₱${product.pricePerCase!.toStringAsFixed(2)}/Case');
  //   }
  //   if (product.pricePerPc != null && product.pricePerPc! > 0) {
  //     prices.add('₱${product.pricePerPc!.toStringAsFixed(2)}/Pc');
  //   }

  //   return prices.isEmpty ? 'N/A' : prices.join(', ');
  // }

  String _formatAmount(double? amount) {
    if (amount == null) return 'N/A';
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return formatter.format(amount);
  }

  
}
