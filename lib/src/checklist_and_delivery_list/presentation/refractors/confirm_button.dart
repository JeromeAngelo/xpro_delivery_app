import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/presentation/bloc/checklist_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';


class ConfirmButton extends StatelessWidget {
  const ConfirmButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistBloc, ChecklistState>(
      builder: (context, state) {
        if (state is ChecklistLoaded) {
          final allChecked =
              state.checklist.every((item) => item.isChecked ?? false);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: RoundedButton(
              label: 'Confirm',
              onPressed: () {
                if (allChecked) {
                  context.pushReplacement('/first-otp');
                } else {
                  CoreUtils.showSnackBar(
                    context,
                    'Please complete all checklist items before proceeding',
                  );
                }
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

