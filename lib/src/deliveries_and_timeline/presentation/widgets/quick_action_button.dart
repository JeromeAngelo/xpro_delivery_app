import 'package:flutter/material.dart';

class QuickActionButton extends StatelessWidget {
  final VoidCallback? onBulkUpdate;
  final VoidCallback? onCancel;
  final bool bulkEnabled;

  const QuickActionButton({
    super.key,
    this.onBulkUpdate,
    this.onCancel,
    this.bulkEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.playlist_add_check,
                color: Theme.of(context).colorScheme.surface,
              ),
              label: Text(
                "Set Bulk Update",
                style: TextStyle(color: Theme.of(context).colorScheme.surface),
              ),
              onPressed: bulkEnabled ? onBulkUpdate : null, // 🔑 enable/disable
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: onCancel,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
              child: Text(
                "Cancel",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
