import 'package:flutter/material.dart';

class OTPInstructions extends StatelessWidget {
  const OTPInstructions({super.key});

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
        const SizedBox(height: 8),
        Text(
          'Input current vehicle odometer reading',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}
