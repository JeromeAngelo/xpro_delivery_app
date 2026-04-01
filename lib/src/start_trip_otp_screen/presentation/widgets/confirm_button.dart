import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: RoundedButton(
        label: 'Confirm',
        isLoading: isLoading,
        onPressed: () {
           RouteUtils.clearSavedRoute(); // Clear saved route on trip end
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
      ),
    );
  }
}
