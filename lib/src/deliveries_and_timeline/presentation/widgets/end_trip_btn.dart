import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';

import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class EndTripButton extends StatelessWidget {
  const EndTripButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<EndTripChecklistBloc, EndTripChecklistState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: RoundedButton(
                label: 'End Trip',
                onPressed: () {
                  if (authState is UserTripLoaded &&
                      authState.trip.id != null) {
                    debugPrint(
                      '🎫 Generating checklist for trip: ${authState.trip.id}',
                    );
                    context.read<InvoiceBloc>().add(
                      SetAllInvoicesCompletedEvent(authState.trip.id!),
                    );
                    context.read<EndTripChecklistBloc>().add(
                      GenerateEndTripChecklistEvent(authState.trip.id!),
                    );
                    // Navigate only when button is clicked
                    context.go('/finalize-deliveries');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
