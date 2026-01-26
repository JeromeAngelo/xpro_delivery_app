import 'package:flutter/material.dart';

import '../../../../core/common/app/features/checklists/intransit_checklist/domain/entity/checklist_entity.dart';

// ✅ ChecklistTile (X = false, Check = true)
// Tap only when false -> becomes true (optimistic) then dispatches bloc event.
// If already true, icon stays check and tap does nothing (or you can allow toggle back if you want).
class ChecklistTile extends StatelessWidget {
  final ChecklistEntity checklist;
  final ValueChanged<bool> onToggleToTrue;
  final bool isChecked;

  const ChecklistTile({
    super.key,
    required this.checklist,
    required this.onToggleToTrue,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ExpansionTile(
          maintainState: true, // ✅ important for release stability
          tilePadding: const EdgeInsets.all(16),
          leading: Checkbox(
            value: isChecked,
            onChanged: (value) {
              // ✅ Only allow unchecked → checked
              if (isChecked) {
                debugPrint(
                  'ℹ️ Checklist already checked: ${checklist.objectName}',
                );
                return;
              }

              debugPrint('✅ Checkbox toggled -> TRUE: ${checklist.objectName}');
              onToggleToTrue(true);
            },
          ),
          title: Text(
            checklist.objectName ?? 'No Name',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          children: [
            if (checklist.description != null &&
                checklist.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 16, bottom: 16),
                child: Text(
                  checklist.description!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
