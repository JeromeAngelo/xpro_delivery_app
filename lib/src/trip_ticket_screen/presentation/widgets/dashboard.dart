import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_state.dart';

class TripTicketDashBoard extends StatelessWidget {
  const TripTicketDashBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, tripState) {
        if (tripState is! TripLoaded) {
          return const SizedBox();
        }

        return Padding(
          padding: const EdgeInsets.all(8),
          child: _buildDashboardContent(context, tripState),
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, TripLoaded tripState) {
    final tripNumber = tripState.trip.tripNumberId;
    final tripName = tripState.trip.name;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        // Trip Number
        _buildInfoItem(
          context,
          Icons.confirmation_number,
          tripNumber ?? 'N/A',
          'Trip Number',
          isAvailable: tripNumber != null,
        ),
        // Trip Name
        _buildInfoItem(
          context,
          Icons.route,
          tripName ?? 'N/A',
          'Trip Name',
          isAvailable: tripName != null,
        ),
        // Plate Number
        _buildInfoItem(
          context,
          Icons.numbers,
          tripState.trip.deliveryVehicle.target!.name ?? 'Not Assigned',
          'Plate Number',
        ),
        // Vehicle
        _buildInfoItem(
          context,
          Icons.local_shipping,
          tripState.trip.deliveryVehicle.target!.make ?? 'Not Assigned',
          'Vehicle',
        ),
        // Team Members
        _buildInfoItem(
          context,
          Icons.people,
          tripState.trip.personels.isEmpty
              ? 'No Helpers'
              : '${tripState.trip.personels.length} Helpers',
          'Team Members',
          isError: tripState.trip.personels.isEmpty,
        ),
        // Vehicle Type
        _buildInfoItem(
          context,
          Icons.type_specimen_outlined,
          tripState.trip.deliveryVehicle.target!.type ?? 'Not Assigned',
          'Vehicle Type',
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String value,
    String label, {
    bool isError = false,
    bool isAvailable = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),

              child: Icon(
                icon,
                color:
                    isError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color:
                            !isAvailable
                                ? Theme.of(context).colorScheme.error
                                : isError
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
