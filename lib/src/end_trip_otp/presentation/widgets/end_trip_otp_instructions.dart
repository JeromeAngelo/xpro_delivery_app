import 'package:flutter/material.dart';

class EndTripOtpInstructions extends StatelessWidget {
  const EndTripOtpInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Guard instructions......",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          "Enter the OTP code sent to your phone",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
