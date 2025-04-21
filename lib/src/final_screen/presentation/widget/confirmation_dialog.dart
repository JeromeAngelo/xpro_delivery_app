import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';

class ConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripEnded) {
          // Force refresh auth state to clear trip data
          context.read<AuthBloc>().add(const RefreshUserEvent());
          
          // Close dialog and navigate
          Navigator.of(context).pop();
          context.go('/');
        }
      },
      child: AlertDialog(
        title: Text(
          'End Trip',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: const Text(
          'Are you sure you want to end this trip? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'No',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              // Don't navigate here, let the BlocListener handle it
              onConfirm();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
