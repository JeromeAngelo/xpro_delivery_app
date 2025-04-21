import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/entity/end_checklist_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
class EndTripSummaryButton extends StatelessWidget {
  final List<EndChecklistEntity> checklists;
  final bool enabled;

  const EndTripSummaryButton({
    super.key,
    required this.checklists,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final allChecked = checklists.every((item) => item.isChecked ?? false);

    return RoundedButton(
      label: 'End trip',
      onPressed: allChecked 
          ? () {
              debugPrint('✅ All checklist items completed');
              context.push('/end-trip-otp');
            }
          : () {
              debugPrint('⚠️ Some checklist items are not completed');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please complete all checklist items before ending trip'),
                  backgroundColor: Colors.red,
                ),
              );
            },
      buttonColour: allChecked 
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceVariant,
      labelColour: allChecked 
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
