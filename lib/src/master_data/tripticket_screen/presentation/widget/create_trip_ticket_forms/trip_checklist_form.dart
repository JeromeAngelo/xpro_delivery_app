import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/app_drop_down_fields.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/app_textfield.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_title.dart';
import 'package:flutter/material.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/model/checklist_model.dart';

class ChecklistForm extends StatelessWidget {
  final List<ChecklistModel> availableChecklists;
  final List<ChecklistModel> selectedChecklists;
  final Function(List<ChecklistModel>) onChecklistsChanged;

  const ChecklistForm({
    super.key,
    required this.availableChecklists,
    required this.selectedChecklists,
    required this.onChecklistsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionTitle(title: 'Add Checklist'),

        // Checklists dropdown
        _buildChecklistsDropdown(context),
      ],
    );
  }

  Widget _buildChecklistsDropdown(BuildContext context) {
    if (availableChecklists.isEmpty) {
      return const AppTextField(
        label: 'Checklists',
        initialValue: 'No Checklists',
        readOnly: true,
        //      helperText: 'No checklists available to select',
      );
    }

    // Display selected checklists with remove option
    Widget selectedChecklistsWidget = const SizedBox.shrink();
    if (selectedChecklists.isNotEmpty) {
      selectedChecklistsWidget = Padding(
        padding: const EdgeInsets.only(
          left: 200.0,
          bottom: 8.0,
        ), // Align with dropdown
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              selectedChecklists.map((checklist) {
                return Chip(
                  label: Text(
                    checklist.objectName ?? 'Checklist ${checklist.id}',
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    final updatedList = List<ChecklistModel>.from(
                      selectedChecklists,
                    );
                    updatedList.remove(checklist);
                    onChecklistsChanged(updatedList);
                  },
                );
              }).toList(),
        ),
      );
    }

    // Convert checklists to dropdown items
    final checklistItems =
        availableChecklists
            .where((checklist) => !selectedChecklists.contains(checklist))
            .map((checklist) {
              return DropdownItem<ChecklistModel>(
                value: checklist,
                label: checklist.objectName ?? 'Checklist ${checklist.id}',
                icon: const Icon(Icons.check_circle_outline, size: 16),
                uniqueId:
                    checklist.id, // Use the checklist ID as a unique identifier
              );
            })
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show selected checklists chips

        // Dropdown to add more checklists
        AppDropdownField<ChecklistModel>(
          label: 'Checklists',
          hintText: 'Select Checklist',
          items: checklistItems,
          onChanged: (value) {
            if (value != null && !selectedChecklists.contains(value)) {
              final updatedList = List<ChecklistModel>.from(selectedChecklists);
              updatedList.add(value);
              onChecklistsChanged(updatedList);
            }
          },
          //    helperText: 'Select checklists for this trip',
        ),

        selectedChecklistsWidget,
      ],
    );
  }
}
