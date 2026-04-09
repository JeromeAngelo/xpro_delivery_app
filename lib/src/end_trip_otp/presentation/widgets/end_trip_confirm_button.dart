import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/presentation/bloc/end_trip_otp_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';

class EndTripConfirmButton extends StatelessWidget {
  final String enteredOtp;
  final String generatedOtp;
  final String tripId;
  final String otpId;
  final String odometerReading;
  final bool noOdometer;

  const EndTripConfirmButton({
    super.key,
    required this.enteredOtp,
    required this.generatedOtp,
    required this.tripId,
    required this.otpId,
    required this.odometerReading,
    this.noOdometer = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        debugPrint('🔄 Auth State: $state');

        if (state is UserTripLoaded) {
          debugPrint('🎫 Trip ID for calculation: ${state.trip.id}');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (odometerReading.isNotEmpty || noOdometer) {
                    context.read<EndTripOtpBloc>().add(
                      VerifyEndTripOtpEvent(
                        enteredOtp: enteredOtp,
                        generatedOtp: generatedOtp,
                        tripId: state.trip.id!,
                        otpId: otpId,
                        odometerReading: noOdometer ? '' : odometerReading,
                        noOdometer: noOdometer,
                      ),
                    );

                    context.read<TripBloc>().add(
                      CalculateTripDistanceEvent(state.trip.id!),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 4,
                  shadowColor: colorScheme.primary.withAlpha(100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        debugPrint('⏳ Waiting for trip data...');
        return const SizedBox.shrink();
      },
    );
  }
}
