import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';

class TeamLeaderSelectionDialog extends StatefulWidget {
  final List<PersonelModel> availablePersonnel;
  final PersonelModel? selectedTeamLeader;
  final Function(PersonelModel?) onTeamLeaderChanged;

  const TeamLeaderSelectionDialog({
    super.key,
    required this.availablePersonnel,
    this.selectedTeamLeader,
    required this.onTeamLeaderChanged,
  });

  @override
  State<TeamLeaderSelectionDialog> createState() =>
      _TeamLeaderSelectionDialogState();
}

class _TeamLeaderSelectionDialogState extends State<TeamLeaderSelectionDialog> {
  PersonelModel? _tempSelectedTeamLeader;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelectedTeamLeader = widget.selectedTeamLeader;
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
                  'Select Team Leader',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                hintText: 'Search team leaders...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Team Leader list
            Expanded(
              child:
                  filteredPersonnel.isEmpty
                      ? const Center(
                        child: Text(
                          'No team leaders found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredPersonnel.length,
                        itemBuilder: (context, index) {
                          final personnel = filteredPersonnel[index];
                          final isSelected = _tempSelectedTeamLeader?.id == personnel.id;
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
                            child: RadioListTile<PersonelModel>(
                              value: personnel,
                              groupValue: _tempSelectedTeamLeader,
                              onChanged: (PersonelModel? value) {
                                setState(() {
                                  _tempSelectedTeamLeader = value;
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
                              selected: isSelected,
                            ),
                          );
                        },
                      ),
            ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Clear selection button
                TextButton(
                  onPressed: () {
                    widget.onTeamLeaderChanged(null);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear Selection'),
                ),
                
                // Cancel and Confirm buttons
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onTeamLeaderChanged(_tempSelectedTeamLeader);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        _tempSelectedTeamLeader == null 
                            ? 'Confirm' 
                            : 'Select ${_tempSelectedTeamLeader!.name}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
