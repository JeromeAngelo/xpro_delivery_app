import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/common/app/features/trip_ticket/trip/domain/entity/trip_entity.dart';
import '../../../../core/common/app/features/users/auth/domain/entity/users_entity.dart';
class HomepageDashboard extends StatelessWidget {
  final LocalUser user;
  final TripEntity trip;

  const HomepageDashboard({
    super.key,
    required this.user,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('📝 HomepageDashboard build called');
    debugPrint('User Trip: ${trip.name}, DeliveryTeam: ${trip.deliveryTeam.target?.id}');
    debugPrint('Vehicle: ${trip.deliveryVehicle.target?.name}');

    final dateFormat = DateFormat("MMM dd, yyyy");

    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildDashboardContent(context, dateFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name ?? 'User Name',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Trip Number: ${user.tripNumberId ?? 'No Trip Number'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          'Route Name: ${trip.name}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, DateFormat dateFormat) {
    final team = trip.deliveryTeam.target;
    final vehicle = trip.deliveryVehicle.target;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 22,
      ),
      children: [
        _buildInfoItem(
          context,
          Icons.numbers,
          vehicle?.name ?? 'Not Assigned',
          'Plate Number',
        ),
        _buildInfoItem(
          context,
          Icons.local_shipping,
          vehicle != null
              ? '${vehicle.make ?? ''} '.trim()
              : 'Not Assigned',
          'Vehicle',
        ),
        _buildInfoItem(
          context,
          Icons.pending_actions,
          '${team?.activeDeliveries ?? 0}',
          'Active Deliveries',
        ),
        _buildInfoItem(
          context,
          Icons.done_all,
          '${team?.totalDelivered ?? 0}',
          'Total Delivered',
        ),
        _buildInfoItem(
          context,
          Icons.route,
          '${team?.totalDistanceTravelled ?? 0} km',
          'Distance Travelled',
        ),
        _buildInfoItem(
          context,
          Icons.warning_amber,
          '${team?.undeliveredCustomers ?? 0}',
          'Undelivered',
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
