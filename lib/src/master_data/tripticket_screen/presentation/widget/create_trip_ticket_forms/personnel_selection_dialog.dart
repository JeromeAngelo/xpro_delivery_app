import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';

class PersonnelSelectionDialog extends StatefulWidget {
  final List<PersonelModel> availablePersonnel;
  final List<PersonelModel> selectedPersonnel;
  final Function(List<PersonelModel>) onPersonnelChanged;

  const PersonnelSelectionDialog({
    super.key,
    required this.availablePersonnel,
    required this.selectedPersonnel,
    required this.onPersonnelChanged,
  });

  @override
  State<PersonnelSelectionDialog> createState() =>
      _PersonnelSelectionDialogState();
}

class _PersonnelSelectionDialogState extends State<PersonnelSelectionDialog> {
  late List<PersonelModel> _tempSelectedPersonnel;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelectedPersonnel = List.from(widget.selectedPersonnel);
  }

  List<PersonelModel> get filteredPersonnel {
    if (_searchQuery.isEmpty) {
      return widget.availablePersonnel;
    }
    return widget.availablePersonnel.where((personnel) {
      final name = personnel.name?.toLowerCase() ?? '';
      final role = personnel.role?.name.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || role.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Personnel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                ),
                hintText: 'Search personnel...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: TextStyle(color: Colors.black),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Personnel list
            Expanded(
              child:
                  filteredPersonnel.isEmpty
                      ? const Center(
                        child: Text(
                          'No personnel found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredPersonnel.length,
                        itemBuilder: (context, index) {
                          final personnel = filteredPersonnel[index];
                          final isSelected = _tempSelectedPersonnel.contains(
                            personnel,
                          );
                          final assignmentStatus =
                              (personnel.isAssigned ?? false)
                                  ? 'Trip Assigned'
                                  : 'Available';
                          final statusColor =
                              (personnel.isAssigned ?? false)
                                  ? Colors.orange
                                  : Colors.green;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    if (!_tempSelectedPersonnel.contains(
                                      personnel,
                                    )) {
                                      _tempSelectedPersonnel.add(personnel);
                                    }
                                  } else {
                                    _tempSelectedPersonnel.remove(personnel);
                                  }
                                });
                              },
                              title: Text(
                                personnel.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Role: ${personnel.role?.name ?? 'Unknown'}',
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        (personnel.isAssigned ?? false)
                                            ? Icons.assignment_turned_in
                                            : Icons.person_outline,
                                        size: 16,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        assignmentStatus,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: statusColor.withOpacity(0.1),
                                child: Icon(Icons.person, color: statusColor),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onPersonnelChanged(_tempSelectedPersonnel);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Select ${_tempSelectedPersonnel.length} Personnel',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
