import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_event.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
class EndTripConfirmButton extends StatelessWidget {
  final String enteredOtp;
  final String generatedOtp;
  final String tripId;
  final String otpId;
  final String odometerReading;

  const EndTripConfirmButton({
    super.key,
    required this.enteredOtp,
    required this.generatedOtp,
    required this.tripId,
    required this.otpId,
    required this.odometerReading,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        debugPrint('🔄 Auth State: $state');
        
        if (state is UserTripLoaded) {
          debugPrint('🎫 Trip ID for calculation: ${state.trip.id}');
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: RoundedButton(
              label: 'Confirm',
              onPressed: () {
                if (odometerReading.isNotEmpty) {
                  context.read<EndTripOtpBloc>().add(
                    VerifyEndTripOtpEvent(
                      enteredOtp: enteredOtp,
                      generatedOtp: generatedOtp,
                      tripId: state.trip.id!,
                      otpId: otpId,
                      odometerReading: odometerReading,
                    ),
                  );

                  context.read<TripBloc>().add(
                    CalculateTripDistanceEvent(state.trip.id!),
                  );
                }
              },
            ),
          );
        }
        
        debugPrint('⏳ Waiting for trip data...');
        return const SizedBox.shrink();
      },
    );
  }
}
