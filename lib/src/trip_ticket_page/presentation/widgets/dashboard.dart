import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';

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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _buildHeader(context, tripState),
                  const SizedBox(height: 30),
                  _buildDashboardContent(context, tripState),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TripLoaded tripState) {
    //  final userName = context.read<UserProvider>().user?.name;
    final tripNumber = tripState.trip.tripNumberId;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   userName ?? 'Driver Not Assigned',
              //   style: Theme.of(context).textTheme.titleLarge!.copyWith(
              //         color: userName != null
              //             ? Theme.of(context).colorScheme.onSurface
              //             : Theme.of(context).colorScheme.error,
              //       ),
              // ),
              const SizedBox(height: 10),
              Text(
                tripNumber != null
                    ? 'Trip: $tripNumber'
                    : 'Trip Number Not Available',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      tripNumber != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, TripLoaded tripState) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      crossAxisSpacing: 5,
      mainAxisSpacing: 22,
      children: [
        _buildInfoItem(
          context,
          Icons.numbers,
          tripState.trip.vehicle.first.vehiclePlateNumber ?? 'Not Assigned',
          'Plate Number',
        ),
        _buildInfoItem(
          context,
          Icons.local_shipping,
          tripState.trip.vehicle.first.vehicleName ?? 'Not Assigned',
          'Vehicle',
        ),
        _buildInfoItem(
          context,
          Icons.people,
          tripState.trip.personels.isEmpty
              ? 'No Helpers'
              : '${tripState.trip.personels.length} Helpers',
          'Team Members',
          isError: tripState.trip.personels.isEmpty,
        ),
        _buildInfoItem(
          context,
          Icons.type_specimen_outlined,
          tripState.trip.vehicle.first.vehicleType ?? 'Not Assigned',
          'Vehicle Type',
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    bool isError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isError
                  ? Theme.of(context).colorScheme.error.withOpacity(0.5)
                  : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Icon(
              icon,
              color:
                  isError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
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
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color:
                          isError
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurface,
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
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
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
