import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class TripDetailsDialog extends StatefulWidget {
  const TripDetailsDialog({super.key});

  @override
  State<TripDetailsDialog> createState() => _TripDetailsDialogState();
}

class _TripDetailsDialogState extends State<TripDetailsDialog> {
  bool _isDataLoaded = false;

  void _loadDeliveryTeamData() {
    if (_isDataLoaded) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is UserTripLoaded && authState.trip.id != null) {
      debugPrint('🚛 Loading delivery team for trip: ${authState.trip.id}');
      context.read<DeliveryTeamBloc>().add(
        LoadDeliveryTeamEvent(authState.trip.id!),
      );
      setState(() => _isDataLoaded = true);
    } else {
      debugPrint('⚠️ No trip data available to load delivery team');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load delivery team data when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeliveryTeamData();
    });
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trip Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trip Information
            _buildTripInfoSection(context),
            const SizedBox(height: 20),

            // Delivery Team Information
            _buildDeliveryTeamSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoSection(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is UserTripLoaded) {
          final trip = state.trip;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.confirmation_number,
                'Trip Number',
                trip.tripNumberId ?? 'Not Assigned',
              ),
              const SizedBox(height: 8),
            ],
          );
        }

        return Column(
          children: [
            Text(
              'Trip Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  Widget _buildDeliveryTeamSection(BuildContext context) {
    return BlocBuilder<DeliveryTeamBloc, DeliveryTeamState>(
      builder: (context, state) {
        if (state is DeliveryTeamLoaded) {
          final team = state.deliveryTeam;
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Team',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Vehicle Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vehicle',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        Icons.numbers,
                        'Plate Number',
                        team.deliveryVehicle.target?.name ?? 'Not Assigned',
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        context,
                        Icons.directions_car,
                        'Make & Model',
                        team.deliveryVehicle.target != null
                            ? '${team.deliveryVehicle.target!.make ?? ''} ${team.deliveryVehicle.target!.name ?? ''}'
                                    .trim()
                                    .isEmpty
                                ? team.deliveryVehicle.target!.name ??
                                    'Not Assigned'
                                : '${team.deliveryVehicle.target!.make ?? ''} ${team.deliveryVehicle.target!.name ?? ''}'
                                    .trim()
                            : 'Not Assigned',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Personnel Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Team Members',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (team.personels.isNotEmpty)
                        ...team.personels.map((personnel) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _buildInfoRow(
                              context,
                              Icons.person,
                              personnel.role?.name ?? 'Team Member',
                              personnel.name ?? 'Unknown',
                            ),
                          );
                        })
                      else
                        _buildInfoRow(
                          context,
                          Icons.person_off,
                          'Team Members',
                          'No members assigned',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (state is DeliveryTeamError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Team',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load delivery team data',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _isDataLoaded = false);
                        _loadDeliveryTeamData();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Team',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
