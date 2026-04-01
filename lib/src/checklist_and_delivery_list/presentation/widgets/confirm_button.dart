import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/domain/entity/checklist_entity.dart';

import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';

class ConfirmButton extends StatelessWidget {
  final List<ChecklistEntity> checklists;
  final bool enabled;
  const ConfirmButton({
    super.key,
    required this.checklists,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    //final allChecked = checklists.every((item) => item.isChecked ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: RoundedButton(
        label: 'Confirm',
        onPressed: () {
          context.pushReplacement('/first-otp');
        },
        buttonColour: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
