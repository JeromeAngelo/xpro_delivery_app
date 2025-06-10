import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';

class DeliveryTeamStats extends StatelessWidget {
  const DeliveryTeamStats({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryTeamBloc, DeliveryTeamState>(
      builder: (context, state) {
        if (state is DeliveryTeamLoaded) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Statistics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem(
                      context,
                      'Active Deliveries',
                      state.deliveryTeam.activeDeliveries?.toString() ?? '0',
                      Icons.local_shipping,
                    ),
                    _buildStatItem(
                      context,
                      'Total Delivered',
                      state.deliveryTeam.totalDelivered?.toString() ?? '0',
                      Icons.done_all,
                    ),
                    _buildStatItem(
                      context,
                      'Distance Travelled',
                      '${state.deliveryTeam.totalDistanceTravelled ?? 0} KM',
                      Icons.speed,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
