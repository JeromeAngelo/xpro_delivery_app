import 'package:flutter/material.dart';

import '../../../../core/common/app/features/checklist/domain/entity/checklist_entity.dart';

class ChecklistTile extends StatefulWidget {
  final ChecklistEntity checklist;
  final Function(bool?) onChanged;
  final bool isChecked;

  const ChecklistTile({
    super.key,
    required this.checklist,
    required this.onChanged,
    required this.isChecked,
  });

  @override
  State<ChecklistTile> createState() => _ChecklistTileState();
}

class _ChecklistTileState extends State<ChecklistTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          leading: Checkbox(
            value: widget.isChecked,
            onChanged: (value) {
              widget.onChanged(value);
            },
          ),
          title: Text(
            widget.checklist.objectName ?? 'No Name',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 20),
                  child: Text(
                    widget.checklist.description ?? 'No Description',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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
