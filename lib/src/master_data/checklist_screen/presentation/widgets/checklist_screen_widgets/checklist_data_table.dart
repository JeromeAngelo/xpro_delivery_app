import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/domain/entity/checklist_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/presentation/bloc/checklist_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/master_data/checklist_screen/presentation/widgets/checklist_screen_widgets/checklist_search_bar.dart'
    show ChecklistSearchBar;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChecklistDataTable extends StatelessWidget {
  final List<ChecklistEntity> checklists;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const ChecklistDataTable({
    super.key,
    required this.checklists,
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
      title: 'Checklists',
      searchBar: ChecklistSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create checklist screen
        _showCreateChecklistDialog(context);
      },
      createButtonText: 'Add Checklist Item',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Object Name')),
        // DataColumn(label: Text('Status')),
        DataColumn(label: Text('Checked')),
        DataColumn(label: Text('Trip')),
        DataColumn(label: Text('Completed At')),
        DataColumn(label: Text('Actions')),
      ],
      rows:
          checklists.map((checklist) {
            return DataRow(
              cells: [
                DataCell(Text(checklist.id)),
                DataCell(Text(checklist.objectName ?? 'N/A')),
                // DataCell(Text(checklist.status ?? 'N/A')),
                DataCell(
                  checklist.isChecked == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
                ),
                DataCell(Text(checklist.trip?.tripNumberId ?? 'Unassigned')),
                DataCell(Text(_formatDate(checklist.timeCompleted))),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {
                          // View checklist details
                          context.go('/checklist/${checklist.id}');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () {
                          // Edit checklist
                          _showEditChecklistDialog(context, checklist);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () {
                          // Show confirmation dialog before deleting
                          _showDeleteConfirmationDialog(context, checklist);
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
     dataLength: '${checklists.length}', onDeleted: () {  },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  Future<void> _showCreateChecklistDialog(BuildContext context) async {
    final objectNameController = TextEditingController();
    final statusController = TextEditingController();
    bool isChecked = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Checklist Item'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: objectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Object Name',
                        hintText: 'Enter object name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: statusController,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        hintText: 'Enter status',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Checked:'),
                        const SizedBox(width: 8),
                        Switch(
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              isChecked = value;
                            });
                          },
                        ),
                      ],
                    ),
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
                  child: const Text('Create'),
                  onPressed: () {
                    if (objectNameController.text.isNotEmpty) {
                      context.read<ChecklistBloc>().add(
                        CreateChecklistItemEvent(
                          objectName: objectNameController.text,
                          isChecked: isChecked,
                          status:
                              statusController.text.isNotEmpty
                                  ? statusController.text
                                  : null,
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an object name'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Dispose controllers
      objectNameController.dispose();
      statusController.dispose();
    });
  }

  Future<void> _showEditChecklistDialog(
    BuildContext context,
    ChecklistEntity checklist,
  ) async {
    final objectNameController = TextEditingController(
      text: checklist.objectName,
    );
    final statusController = TextEditingController(text: checklist.status);
    bool isChecked = checklist.isChecked ?? false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Checklist Item'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: objectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Object Name',
                        hintText: 'Enter object name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: statusController,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        hintText: 'Enter status',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Checked:'),
                        const SizedBox(width: 8),
                        Switch(
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              isChecked = value;
                            });
                          },
                        ),
                      ],
                    ),
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
                  child: const Text('Update'),
                  onPressed: () {
                    if (objectNameController.text.isNotEmpty) {
                      context.read<ChecklistBloc>().add(
                        UpdateChecklistItemEvent(
                          id: checklist.id,
                          objectName: objectNameController.text,
                          isChecked: isChecked,
                          status:
                              statusController.text.isNotEmpty
                                  ? statusController.text
                                  : null,
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an object name'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Dispose controllers
      objectNameController.dispose();
      statusController.dispose();
    });
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    ChecklistEntity checklist,
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
                  'Are you sure you want to delete "${checklist.objectName}"?',
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
                context.read<ChecklistBloc>().add(
                  DeleteChecklistItemEvent(checklist.id),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
