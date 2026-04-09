import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/common/app/features/otp/intransit_otp/presentation/bloc/otp_bloc.dart';
import '../../../../core/common/app/features/otp/intransit_otp/presentation/bloc/otp_event.dart';
import '../../../../core/utils/route_utils.dart';

class ConfirmButtonOtp extends StatelessWidget {
  final String enteredOtp;
  final String generatedOtp;
  final String odometerReading;
  final String tripId;
  final String otpId;
  final bool noOdometer;
  final bool isLoading;

  const ConfirmButtonOtp({
    super.key,
    required this.enteredOtp,
    required this.generatedOtp,
    required this.odometerReading,
    required this.tripId,
    required this.otpId,
    this.noOdometer = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  RouteUtils.clearSavedRoute();
                  if (enteredOtp.isNotEmpty &&
                      (noOdometer || odometerReading.isNotEmpty)) {
                    context.read<OtpBloc>().add(
                      VerifyInTransitOtpEvent(
                        enteredOtp: enteredOtp,
                        generatedOtp: generatedOtp,
                        tripId: tripId,
                        otpId: otpId,
                        odometerReading: odometerReading,
                        noOdometer: noOdometer,
                      ),
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
            disabledBackgroundColor: colorScheme.primary.withAlpha(150),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Row(
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
}
