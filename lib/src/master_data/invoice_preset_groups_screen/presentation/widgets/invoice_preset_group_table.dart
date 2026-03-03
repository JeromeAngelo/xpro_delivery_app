import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/entity/invoice_preset_group_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/master_data/invoice_preset_groups_screen/presentation/widgets/invoice_preset_group_search_bar.dart';

class InvoicePresetGroupTable extends StatelessWidget {
  final List<InvoicePresetGroupEntity> presetGroups;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const InvoicePresetGroupTable({
    super.key,
    required this.presetGroups,
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
      title: 'Invoice Preset Groups',
      searchBar: InvoicePresetGroupSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create invoice preset group screen
        context.go('/invoice-preset-group/create');
      },
      createButtonText: 'Create Preset Group',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Reference ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Invoices Count')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Updated')),
        DataColumn(label: Text('Actions')),
      ],
      rows: presetGroups.map((group) {
        return DataRow(
          cells: [
            DataCell(
              Text(group.id?.substring(0, 8) ?? 'N/A'),
              onTap: () => _navigateToGroupDetails(context, group),
            ),
            DataCell(
              Text(group.refId ?? 'N/A'),
              onTap: () => _navigateToGroupDetails(context, group),
            ),
            DataCell(
              Text(group.name ?? 'N/A'),
              onTap: () => _navigateToGroupDetails(context, group),
            ),
            DataCell(
              Text(group.invoices.length.toString()),
              onTap: () => _navigateToGroupDetails(context, group),
            ),
            DataCell(
              Text(_formatDate(group.created)),
              onTap: () => _navigateToGroupDetails(context, group),
            ),
            DataCell(
              Text(_formatDate(group.updated)),
              onTap: () => _navigateToGroupDetails(context, group),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    tooltip: 'View Details',
                    onPressed: () => _navigateToGroupDetails(context, group),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    tooltip: 'Edit',
                    onPressed: () {
                      if (group.id != null) {
                        context.go('/invoice-preset-group/edit/${group.id}');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () {
                      _showDeleteConfirmationDialog(context, group);
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
    
      dataLength: '${presetGroups.length}',
      onDeleted: () {},
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _navigateToGroupDetails(
    BuildContext context,
    InvoicePresetGroupEntity group,
  ) {
    if (group.id != null) {
      // First, dispatch the event to load the group data
      // context.read<InvoicePresetGroupBloc>().add(
      //       GetInvoicePresetGroupByIdEvent(group.id!),
      //     );

      // // Then navigate to the specific group screen
      // context.go('/invoice-preset-group/${group.id}');
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    InvoicePresetGroupEntity group,
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
                  'Are you sure you want to delete preset group "${group.name}"?',
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
                if (group.id != null) {
                  // context.read<InvoicePresetGroupBloc>().add(
                  //       DeleteInvoicePresetGroupEvent(group.id!),
                  //     );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
