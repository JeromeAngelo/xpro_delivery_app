import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CustomerInvoicesTable extends StatefulWidget {
  final CustomerDataEntity customer;
  final VoidCallback? onAddInvoice;

  const CustomerInvoicesTable({
    super.key,
    required this.customer,
    this.onAddInvoice,
  });

  @override
  State<CustomerInvoicesTable> createState() => _CustomerInvoicesTableState();
}

class _CustomerInvoicesTableState extends State<CustomerInvoicesTable> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _loadInvoices() {
    if (widget.customer.id != null) {
      context.read<InvoiceDataBloc>().add(
        GetInvoiceDataByCustomerIdEvent(widget.customer.id!),
      );
    }
  }

  @override
  void didUpdateWidget(CustomerInvoicesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer.id != widget.customer.id) {
      _loadInvoices();
    }
  }

  void _calculateTotalPages(int totalItems) {
    _totalPages = (totalItems / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceDataBloc, InvoiceDataState>(
      builder: (context, state) {
        if (state is InvoiceDataLoading) {
          return _buildLoadingTable();
        } else if (state is InvoiceDataError) {
          return _buildErrorTable(state.message);
        } else if (state is InvoiceDataByCustomerLoaded && 
                  state.customerId == widget.customer.id) {
          return _buildInvoicesTable(state.invoiceData);
        } else {
          // If we don't have the right state yet, trigger loading
          if (widget.customer.id != null && 
              !(state is InvoiceDataByCustomerLoaded && 
                state.customerId == widget.customer.id)) {
            _loadInvoices();
          }
          return _buildLoadingTable();
        }
      },
    );
  }

  Widget _buildLoadingTable() {
    return DataTableLayout(
      title: 'Customer Invoices',
      searchBar: _buildSearchBar(),
      onCreatePressed: widget.onAddInvoice,
      createButtonText: 'Add Invoice',
      columns: _buildTableColumns(),
      rows: const [],
      currentPage: _currentPage,
      totalPages: _totalPages,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      isLoading: true,
      dataLength: '0', 
      onDeleted: () {},
    );
  }

  Widget _buildErrorTable(String errorMessage) {
    return DataTableLayout(
      title: 'Customer Invoices',
      searchBar: _buildSearchBar(),
      onCreatePressed: widget.onAddInvoice,
      createButtonText: 'Add Invoice',
      columns: _buildTableColumns(),
      rows: const [],
      currentPage: _currentPage,
      totalPages: _totalPages,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      isLoading: false,
      errorMessage: errorMessage,
      onRetry: _loadInvoices,
      dataLength: '0', 
      onDeleted: () {},
    );
  }

  Widget _buildInvoicesTable(List<InvoiceDataEntity> invoices) {
    // Filter invoices based on search query
    List<InvoiceDataEntity> filteredInvoices = invoices;
    if (_searchQuery.isNotEmpty) {
      filteredInvoices = invoices.where((invoice) {
        final query = _searchQuery.toLowerCase();
        return (invoice.name?.toLowerCase().contains(query) ?? false) ||
               (invoice.refId?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Calculate total pages
    _calculateTotalPages(filteredInvoices.length);

    // Paginate invoices
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > filteredInvoices.length
        ? filteredInvoices.length
        : startIndex + _itemsPerPage;

    final paginatedInvoices = startIndex < filteredInvoices.length
        ? filteredInvoices.sublist(startIndex, endIndex)
        : [];

    return DataTableLayout(
      title: 'Customer Invoices',
      searchBar: _buildSearchBar(),
      onCreatePressed: widget.onAddInvoice,
      createButtonText: 'Add Invoice',
      columns: _buildTableColumns(),
      rows: paginatedInvoices.map((invoice) => _buildInvoiceRow(invoice)).toList(),
      currentPage: _currentPage,
      totalPages: _totalPages,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      isLoading: false,
      dataLength: '${filteredInvoices.length}', 
      onDeleted: () {},
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by invoice name or reference ID...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _currentPage = 1; // Reset to first page when searching
        });
      },
    );
  }

  List<DataColumn> _buildTableColumns() {
    return const [
      DataColumn(label: Text('ID')),
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Reference ID')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Total Amount')),
      DataColumn(label: Text('Volume')),
      DataColumn(label: Text('Weight')),
      DataColumn(label: Text('Actions')),
    ];
  }

  DataRow _buildInvoiceRow(InvoiceDataEntity invoice) {
    return DataRow(
      cells: [
        DataCell(
          Text(invoice.id ?? 'N/A'),
          onTap: () => _navigateToInvoice(context, invoice),
        ),
        DataCell(
          Text(invoice.name ?? 'N/A'),
          onTap: () => _navigateToInvoice(context, invoice),
        ),
        DataCell(
          Text(invoice.refId ?? 'N/A'),
          onTap: () => _navigateToInvoice(context, invoice),
        ),
        DataCell(
          Text(_formatDate(invoice.documentDate)),
          onTap: () => _navigateToInvoice(context, invoice),
        ),
        DataCell(
          Text(_formatAmount(invoice.totalAmount)),
          onTap: () => _navigateToInvoice(context, invoice),
        ),
        DataCell(
          Text(_formatVolume(invoice.volume)),
          onTap: () => _navigateToInvoice(context, invoice),
        ),
        DataCell(
          Text(_formatWeight(invoice.weight)),
          onTap: () => _navigateToInvoice(context, invoice),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                tooltip: 'View Details',
                onPressed: () {
                  _navigateToInvoice(context, invoice);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                tooltip: 'Edit',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit invoice feature coming soon'),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.green),
                tooltip: 'Print',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Print invoice feature coming soon',
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
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return 'N/A';

    if (amount is double) {
      return '₱${amount.toStringAsFixed(2)}';
    } else if (amount is String) {
      try {
        final numAmount = double.parse(amount);
        return '₱${numAmount.toStringAsFixed(2)}';
      } catch (_) {
        return '₱$amount';
      }
    }

    return '₱$amount';
  }

  String _formatVolume(dynamic volume) {
    if (volume == null) return 'N/A';

    if (volume is double) {
      return '${volume.toStringAsFixed(2)} m³';
    } else if (volume is String) {
      try {
        final numVolume = double.parse(volume);
        return '${numVolume.toStringAsFixed(2)} m³';
      } catch (_) {
        return '$volume m³';
      }
    }

    return '$volume m³';
  }

  String _formatWeight(dynamic weight) {
    if (weight == null) return 'N/A';

    if (weight is double) {
      return '${weight.toStringAsFixed(2)} kg';
    } else if (weight is String) {
      try {
        final numWeight = double.parse(weight);
        return '${numWeight.toStringAsFixed(2)} kg';
      } catch (_) {
        return '$weight kg';
      }
    }

    return '$weight kg';
  }

  void _navigateToInvoice(BuildContext context, InvoiceDataEntity invoice) {
    if (invoice.id != null) {
      // First, dispatch the event to load the invoice data
      context.read<InvoiceDataBloc>().add(GetInvoiceDataByIdEvent(invoice.id!));

      // Then navigate to the specific invoice screen with the actual ID
      context.go('/invoice/${invoice.id}');
    }
  }
}
