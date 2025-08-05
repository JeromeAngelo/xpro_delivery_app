import 'package:flutter/material.dart';

class OTPInstructions extends StatelessWidget {
  const OTPInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          " Input current vehicle odometer reading.",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          "Hand the device to the guard so they can enter the OTP code.",
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
