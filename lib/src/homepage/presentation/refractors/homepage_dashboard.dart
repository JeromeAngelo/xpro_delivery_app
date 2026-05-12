import 'package:flutter/material.dart';

import '../../../../core/common/app/features/trip_ticket/trip/domain/entity/trip_entity.dart';
import '../../../../core/common/app/features/users/auth/domain/entity/users_entity.dart';

class HomepageDashboard extends StatelessWidget {
  final LocalUser user;
  final TripEntity trip;

  const HomepageDashboard({super.key, required this.user, required this.trip});

  @override
  Widget build(BuildContext context) {
    debugPrint('📝 HomepageDashboard build called');
    debugPrint(
      'User Trip: ${trip.name}, DeliveryTeam: ${trip.deliveryTeam.target?.id}',
    );
    debugPrint('Vehicle: ${trip.deliveryVehicle.target?.name}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 12),
        _buildDashboardCards(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WELCOME BACK',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.name ?? 'User Name',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Trip: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                user.trip.target?.name ?? 'No Trip assigned',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards(BuildContext context) {
    final team = trip.deliveryTeam.target;
    final vehicle = trip.deliveryVehicle.target;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Trip Number ID and Plate Number
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard(
                  context,
                  Icons.confirmation_number_outlined,
                  'Trip Number ID',
                  user.tripNumberId ?? 'N/A',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDashboardCard(
                  context,
                  Icons.local_shipping_outlined,
                  'Plate Number',
                  vehicle?.name ?? 'Not Assigned',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Vehicle Make and Active Deliveries
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard(
                  context,
                  Icons.directions_car_outlined,
                  'Vehicle Make',
                  vehicle?.make ?? 'Not Assigned',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDashboardCard(
                  context,
                  Icons.pending_actions_outlined,
                  'Active Deliveries',
                  '${team?.activeDeliveries ?? 0}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Third row: Total Delivered and Undelivered
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard(
                  context,
                  Icons.done_all_outlined,
                  'Total Delivered',
                  '${team?.totalDelivered ?? 0}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDashboardCard(
                  context,
                  Icons.warning_amber_outlined,
                  'Undelivered',
                  '${team?.undeliveredCustomers ?? 0}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
