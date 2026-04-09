import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/widgets/custom_digital_clock.dart';

class DigitalClocks extends StatelessWidget {
  const DigitalClocks({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          'CURRENT VERIFICATION TIME',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CustomDigitalClock(
          digitAnimationStyle: Curves.easeInOut,
          showSecondsDigit: false,
          areaAligment: AlignmentDirectional.center,
          areaWidth: double.infinity,
          areaHeight: 60,
          is24HourTimeFormat: false,
          hourMinuteDigitTextStyle: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          secondDigitTextStyle: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          amPmDigitTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
          colon: Text(
            ':',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
