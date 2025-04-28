import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/entity/end_checklist_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class EndTripChecklistTile extends StatelessWidget {
  final EndChecklistEntity checklist;
  final Function(bool?) onChanged;
  final bool isChecked;

  const EndTripChecklistTile({
    super.key,
    required this.checklist,
    required this.onChanged,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: CommonListTiles(
          title: checklist.objectName ?? '',
          leading: Icon(
            Icons.checklist_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          trailing: Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: isChecked,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: isChecked ? TextDecoration.lineThrough : null,
            color:
                isChecked
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                    : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 1,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
