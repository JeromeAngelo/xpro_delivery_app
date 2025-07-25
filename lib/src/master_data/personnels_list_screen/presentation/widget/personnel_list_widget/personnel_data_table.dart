import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_role.dart';
import 'package:xpro_delivery_admin_app/src/master_data/personnels_list_screen/presentation/widget/personnel_list_widget/personnel_role_chip.dart';
import 'package:xpro_delivery_admin_app/src/master_data/personnels_list_screen/presentation/widget/personnel_list_widget/personnel_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PersonnelDataTable extends StatelessWidget {
  final List<PersonelEntity> personnel;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const PersonnelDataTable({
    super.key,
    required this.personnel,
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
      title: 'Personnel',
      searchBar: PersonnelSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create personnel screen
        _showCreatePersonnelDialog(context);
      },
      createButtonText: 'Add Personnel',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Role')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Actions')),
      ],
      rows: personnel.map((person) {
        return DataRow(
          onSelectChanged: (selected) {
            if (person.id != null) {
              context.go('/personnel/${person.id}');
            }
          },
          cells: [
            DataCell(Text(person.id ?? 'N/A')),
            DataCell(Text(person.name ?? 'N/A')),
            DataCell(PersonnelRoleChip(role: person.role)),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (person.isAssigned == true) ? Colors.red[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (person.isAssigned == true) ? Colors.red : Colors.green,
                    width: 1,
                  ),
                ),
                child: Text(
                  (person.isAssigned == true) ? 'Assigned' : 'Unassigned',
                  style: TextStyle(
                    color: (person.isAssigned == true) ? Colors.red[800] : Colors.green[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(Text(_formatDate(person.created))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Details',
                  onPressed: () {
                    // View personnel details
                    if (person.id != null) {
                      // Navigate to personnel details screen
                      context.go('/personnel/${person.id}');
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit',
                  onPressed: () {
                    // Edit personnel
                    _showEditPersonnelDialog(context, person);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () {
                    // Show confirmation dialog before deleting
                    _showDeleteConfirmationDialog(context, person);
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
      isLoading: isLoading,
      onFiltered: () {
        // Show filter options
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filter options coming soon')),
        );
      }, dataLength: '${personnel.length}', onDeleted: () {  },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<void> _showCreatePersonnelDialog(BuildContext context) async {
    final nameController = TextEditingController();
    UserRole selectedRole = UserRole.helper;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Personnel'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter personnel name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                      ),
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(role == UserRole.teamLeader ? 'Team Leader' : 'Helper'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRole = value;
                          });
                        }
                      },
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
                    if (nameController.text.isNotEmpty) {
                      context.read<PersonelBloc>().add(
                        CreatePersonelEvent(
                          name: nameController.text,
                          role: selectedRole,
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name')),
                      );
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    ).then((_) {
      // Dispose controllers
      nameController.dispose();
    });
  }

  Future<void> _showEditPersonnelDialog(BuildContext context, PersonelEntity person) async {
    final nameController = TextEditingController(text: person.name);
    UserRole selectedRole = person.role ?? UserRole.helper;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Personnel'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter personnel name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                      ),
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(role == UserRole.teamLeader ? 'Team Leader' : 'Helper'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRole = value;
                          });
                        }
                      },
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
                    if (person.id != null && nameController.text.isNotEmpty) {
                      context.read<PersonelBloc>().add(
                        UpdatePersonelEvent(
                          personelId: person.id!,
                          name: nameController.text,
                          role: selectedRole,
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name')),
                      );
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    ).then((_) {
      // Dispose controllers
      nameController.dispose();
    });
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, PersonelEntity person) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${person.name}"?'),
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
                if (person.id != null) {
                  context.read<PersonelBloc>().add(DeletePersonelEvent(person.id!));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
