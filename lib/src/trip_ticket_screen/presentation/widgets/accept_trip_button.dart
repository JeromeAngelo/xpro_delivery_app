import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';

class AcceptTripButton extends StatelessWidget {
  final String tripId;

  const AcceptTripButton({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripAccepted) {
          

          // Start location tracking for the accepted trip
          context.read<TripBloc>().add(StartLocationTrackingEvent(
                tripId: state.tripId,
                // Optional: customize update interval and distance filter
                // updateInterval: const Duration(minutes: 3),
                // distanceFilter: 500.0, // 500 meters
              ));

          debugPrint('✅ Trip successfully accepted');
          debugPrint('📦 Trip ID: ${state.tripId}');
          debugPrint('📦 Personnel count: ${state.trip.personels.length}');
          debugPrint('🔄 Starting location tracking for trip');
          CoreUtils.showSnackBar(context,
              'Trip successfully accepted. Location tracking started.');
        }

        if (state is TripError) {
          debugPrint('❌ Error accepting trip: ${state.message}');
          CoreUtils.showSnackBar(context, state.message);
        }

        // Handle location tracking states
        if (state is LocationTrackingStarted) {
          debugPrint('✅ Location tracking started for trip: ${state.tripId}');
          CoreUtils.showSnackBar(context, 'Location tracking started');
        }

        if (state is LocationTrackingError) {
          debugPrint('❌ Error with location tracking: ${state.message}');
          CoreUtils.showSnackBar(
              context, 'Location tracking error: ${state.message}');
        }
      },
      builder: (context, state) {
        // Show loading indicator when accepting trip or starting location tracking
        final bool isLoading =
            state is TripAccepting || state is TripLocationUpdating;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RoundedButton(
                  label: 'Accept Trip',
                  onPressed: () {
                    debugPrint('🔘 Accept button pressed for trip: $tripId');
                    context.read<TripBloc>().add(AcceptTripEvent(tripId));

                    context.read<TripBloc>().add(StartLocationTrackingEvent(
                          tripId: tripId,
                          // Optional: customize update interval and distance filter
                          // updateInterval: const Duration(minutes: 3),
                          // distanceFilter: 500.0, // 500 meters
                        ));
                  },
                ),
        );
      },
    );
  }
}
