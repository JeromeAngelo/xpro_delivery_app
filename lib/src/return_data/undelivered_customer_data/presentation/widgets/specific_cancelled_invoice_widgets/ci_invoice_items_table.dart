import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';

class CancelledInvoiceItemsTable extends StatefulWidget {
  final String invoiceId;

  const CancelledInvoiceItemsTable({
    super.key,
    required this.invoiceId,
  });

  @override
  State<CancelledInvoiceItemsTable> createState() => _CancelledInvoiceItemsTableState();
}

class _CancelledInvoiceItemsTableState extends State<CancelledInvoiceItemsTable> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<InvoiceItemsEntity> _allItems = [];
  List<InvoiceItemsEntity> _displayedItems = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInvoiceItems();
  }

  void _loadInvoiceItems() {
    context.read<InvoiceItemsBloc>().add(
      GetInvoiceItemsByInvoiceDataIdEvent(widget.invoiceId),
    );
  }

  void _updateDisplayedItems() {
    var filteredItems = _allItems;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredItems = _allItems.where((item) {
        return (item.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (item.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (item.refId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply pagination
    final startIndex = (_currentPage - 1) * _itemsPerPage;
 //   final endIndex = startIndex + _itemsPerPage;
    
    _displayedItems = filteredItems.skip(startIndex).take(_itemsPerPage).toList();
  }

  int get _totalPages {
    var filteredCount = _allItems.length;
    if (_searchQuery.isNotEmpty) {
      filteredCount = _allItems.where((item) {
        return (item.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (item.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (item.refId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).length;
    }
    return (filteredCount / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceItemsBloc, InvoiceItemsState>(
      listener: (context, state) {
        if (state is InvoiceItemsByInvoiceDataIdLoaded) {
          setState(() {
            _allItems = state.invoiceItems;
            _currentPage = 1; // Reset to first page
            _updateDisplayedItems();
          });
        }
      },
      child: BlocBuilder<InvoiceItemsBloc, InvoiceItemsState>(
        builder: (context, state) {
          return DataTableLayout(
            title: 'Invoice Items',
            searchBar: _buildSearchBar(),
            columns: _buildColumns(),
            rows: _buildRows(),
            currentPage: _currentPage,
            totalPages: _totalPages > 0 ? _totalPages : 1,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
                _updateDisplayedItems();
              });
            },
            isLoading: state is InvoiceItemsLoading,
            errorMessage: state is InvoiceItemsError ? state.message : null,
            onRetry: _loadInvoiceItems,
            dataLength: _allItems.length.toString(),
           
            onDeleted: () {
              // Handle delete action
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search invoice items...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _currentPage = 1; // Reset to first page when searching
          _updateDisplayedItems();
        });
      },
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(
        label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Ref ID', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('UOM', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
        numeric: true,
      ),
      const DataColumn(
        label: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold)),
        numeric: true,
      ),
      const DataColumn(
        label: Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
        numeric: true,
      ),
    ];
  }

  List<DataRow> _buildRows() {
    return _displayedItems.map((item) {
      return DataRow(
        cells: [
          DataCell(
            Text(
              item.name ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          DataCell(Text(item.brand ?? 'N/A')),
          DataCell(Text(item.refId ?? 'N/A')),
          DataCell(Text(item.uom ?? 'N/A')),
          DataCell(
            Text(
              item.quantity?.toStringAsFixed(2) ?? '0.00',
              textAlign: TextAlign.right,
            ),
          ),
          DataCell(
            Text(
              '₱${item.uomPrice?.toStringAsFixed(2) ?? '0.00'}',
              textAlign: TextAlign.right,
            ),
          ),
          DataCell(
            Text(
              '₱${item.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }).toList();
  }
}
