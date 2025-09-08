import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/app_textfield.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_title.dart';
import 'package:flutter/material.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'personnel_selection_dialog.dart';
import 'team_leader_selection_dialog.dart';

class PersonnelForm extends StatelessWidget {
  final List<PersonelModel> availablePersonnel;
  final PersonelModel? selectedTeamLeader;
  final List<PersonelModel> selectedHelpers;
  final Function(PersonelModel?) onTeamLeaderChanged;
  final Function(List<PersonelModel>) onHelpersChanged;

  const PersonnelForm({
    super.key,
    required this.availablePersonnel,
    this.selectedTeamLeader,
    required this.selectedHelpers,
    required this.onTeamLeaderChanged,
    required this.onHelpersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionTitle(title: 'Assign Personnel'),
        
        // Team Leader and Helpers sections in one row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Leader section (left half)
            Expanded(
              child: _buildTeamLeaderDropdown(context),
            ),
            
            const SizedBox(width: 24),
            
            // Helpers section (right half)
            Expanded(
              child: _buildHelpersDropdown(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showTeamLeaderSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TeamLeaderSelectionDialog(
        availablePersonnel: availablePersonnel.where((p) => 
          p.role?.name.toLowerCase().contains('leader') ?? false
        ).toList(),
        selectedTeamLeader: selectedTeamLeader,
        onTeamLeaderChanged: onTeamLeaderChanged,
      ),
    );
  }

  void _showHelpersSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PersonnelSelectionDialog(
        availablePersonnel: availablePersonnel.where((p) => 
          !(p.role?.name.toLowerCase().contains('leader') ?? false)
        ).toList(),
        selectedPersonnel: selectedHelpers,
        onPersonnelChanged: onHelpersChanged,
      ),
    );
  }

  Widget _buildTeamLeaderDropdown(BuildContext context) {
    final teamLeaders = availablePersonnel.where((p) => 
      p.role?.name.toLowerCase().contains('leader') ?? false
    ).toList();

    if (teamLeaders.isEmpty) {
      return const AppTextField(
        label: 'Team Leader',
        initialValue: 'No Team Leader Available',
        readOnly: true,
        helperText: 'No team leaders available to select',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Leader selection button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Leader label
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: RichText(
                  text: TextSpan(
                    text: 'Team Leader',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Custom dropdown button that shows dialog
            Expanded(
              child: InkWell(
                onTap: () => _showTeamLeaderSelectionDialog(context),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedTeamLeader == null
                              ? 'Select Team Leader'
                              : selectedTeamLeader!.name ?? 'Unknown',
                          style: TextStyle(
                            color: selectedTeamLeader == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Display selected team leader
        if (selectedTeamLeader != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Team Leader:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  label: Text(
                    '${selectedTeamLeader!.name} (${selectedTeamLeader!.role?.name ?? 'Unknown'})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    onTeamLeaderChanged(null);
                  },
                ),
              ],
            ),
          ),

        // Helper text
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Select one team leader for this trip',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpersDropdown(BuildContext context) {
    final helpers = availablePersonnel.where((p) => 
      !(p.role?.name.toLowerCase().contains('leader') ?? false)
    ).toList();
    
    if (helpers.isEmpty) {
      return const AppTextField(
        label: 'Helpers',
        initialValue: 'No Helpers Available',
        readOnly: true,
        helperText: 'No helpers available to select',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Helpers selection button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Helpers label
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: RichText(
                  text: TextSpan(
                    text: 'Helpers',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Custom dropdown button that shows dialog
            Expanded(
              child: InkWell(
                onTap: () => _showHelpersSelectionDialog(context),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedHelpers.isEmpty
                              ? 'Select Helpers'
                              : '${selectedHelpers.length} helpers selected',
                          style: TextStyle(
                            color: selectedHelpers.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Display selected helpers
        if (selectedHelpers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Helpers:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedHelpers.map((personnel) {
                    final assignmentStatus =
                        (personnel.isAssigned ?? false) ? 'Trip Assigned' : 'Available';
                    final statusColor =
                        (personnel.isAssigned ?? false) ? Colors.orange : Colors.green;

                    return Chip(
                      avatar: Icon(
                        (personnel.isAssigned ?? false)
                            ? Icons.assignment_turned_in
                            : Icons.person_outline,
                        size: 16,
                        color: statusColor,
                      ),
                      label: Text(
                        '${personnel.name} (${personnel.role?.name ?? 'Unknown'}) - $assignmentStatus',
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        final updatedList = List<PersonelModel>.from(selectedHelpers);
                        updatedList.remove(personnel);
                        onHelpersChanged(updatedList);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Helper text
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Select helpers for this trip. 🟢 Available | 🟠 Trip Assigned',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
