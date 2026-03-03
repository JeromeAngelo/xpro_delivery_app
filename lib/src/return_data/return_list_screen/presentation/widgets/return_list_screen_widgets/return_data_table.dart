import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/return_data/return_list_screen/presentation/widgets/return_list_screen_widgets/return_search_bar.dart';
import 'package:xpro_delivery_admin_app/src/return_data/return_list_screen/presentation/widgets/return_list_screen_widgets/return_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReturnDataTable extends StatelessWidget {
  final List<ReturnEntity> returns;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const ReturnDataTable({
    super.key,
    required this.returns,
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
    return DataTableLayout(
      title: 'Product Returns',
      searchBar: ReturnSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create return screen
        context.go('/returns/create');
      },
      createButtonText: 'Create Return',
      columns: const [
        DataColumn(label: Text('Product Name')),
        DataColumn(label: Text('Reason')),
        DataColumn(label: Text('Return Date')),
        DataColumn(label: Text('Trip')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Actions')),
      ],
      rows: returns.map((returnItem) {
        return DataRow(
          cells: [
            DataCell(Text(returnItem.productName ?? 'N/A')),
            DataCell(ReturnStatusChip(returnItem: returnItem)),
            DataCell(Text(
              returnItem.returnDate != null
                  ? DateFormat('MMM dd, yyyy').format(returnItem.returnDate!)
                  : 'N/A',
            )),
          
            DataCell(
              returnItem.trip != null
                  ? InkWell(
                      onTap: () {
                        if (returnItem.trip?.id != null) {
                          context.go('/tripticket/${returnItem.trip!.id}');
                        }
                      },
                      child: Text(
                        returnItem.trip?.tripNumberId ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : const Text('N/A'),
            ),
            DataCell(_buildQuantityText(returnItem)),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Details',
                  onPressed: () {
                    // View return details
                    if (returnItem.id != null) {
                      context.go('/returns/${returnItem.id}');
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit',
                  onPressed: () {
                    // Edit return
                    if (returnItem.id != null) {
                      context.go('/returns/edit/${returnItem.id}');
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () {
                    // Show confirmation dialog before deleting
                    _showDeleteConfirmationDialog(context, returnItem);
                  },
                ),
              ],
            )),
          ],
        );
      }).toList(),
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: onPageChanged,
      isLoading: isLoading,  dataLength: '${returns.length}', onDeleted: () {  },
    );
  }

  Widget _buildQuantityText(ReturnEntity returnItem) {
    List<String> quantities = [];
    
    if (returnItem.isCase == true && returnItem.productQuantityCase != null && returnItem.productQuantityCase! > 0) {
      quantities.add('${returnItem.productQuantityCase} Case');
    }
    
    if (returnItem.isPcs == true && returnItem.productQuantityPcs != null && returnItem.productQuantityPcs! > 0) {
      quantities.add('${returnItem.productQuantityPcs} Pcs');
    }
    
    if (returnItem.isBox == true && returnItem.productQuantityBox != null && returnItem.productQuantityBox! > 0) {
      quantities.add('${returnItem.productQuantityBox} Box');
    }
    
    if (returnItem.isPack == true && returnItem.productQuantityPack != null && returnItem.productQuantityPack! > 0) {
      quantities.add('${returnItem.productQuantityPack} Pack');
    }
    
    return Text(quantities.isNotEmpty ? quantities.join(', ') : 'N/A');
  }

  void _showDeleteConfirmationDialog(BuildContext context, ReturnEntity returnItem) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete the return for ${returnItem.productName}?'),
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
                if (returnItem.id != null) {
                  context.read<ReturnBloc>().add(DeleteReturnEvent(returnItem.id!));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
