import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_event.dart';

import '../../../../core/utils/core_utils.dart';
class ConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripEnded) {
          // Refresh auth to clear trip
          context.read<AuthBloc>().add(const RefreshUserEvent());

          Navigator.of(context).pop();
          context.go('/');
        }

        if (state is TripError) {
          CoreUtils.showSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is TripEnding;

        return AlertDialog(
          title: Text(
            'End Trip',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to end this trip? This action cannot be undone.',
              ),
              if (isLoading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Ending trip, please wait...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(
                'No',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () {
                      onConfirm(); // triggers TripEnding
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
