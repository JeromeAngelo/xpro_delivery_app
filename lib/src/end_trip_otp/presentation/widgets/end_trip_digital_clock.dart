import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/widgets/custom_digital_clock.dart';

class EndTripDigitalClock extends StatelessWidget {
  const EndTripDigitalClock({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomDigitalClock(
      digitAnimationStyle: Curves.bounceInOut,
      showSecondsDigit: false,
      areaAligment: AlignmentDirectional.center,
      areaWidth: double.infinity,
      areaHeight: 100,
      is24HourTimeFormat: false,
      hourMinuteDigitTextStyle: _getTextStyle(context, large: true),
      secondDigitTextStyle: _getTextStyle(context, large: true),
      amPmDigitTextStyle: _getTextStyle(context, large: false),
      colon: Text(":", style: _getTextStyle(context, large: true)),
    );
  }

  TextStyle _getTextStyle(BuildContext context, {required bool large}) {
    final baseStyle = large
        ? Theme.of(context).textTheme.headlineLarge!
        : Theme.of(context).textTheme.headlineSmall!;

    return baseStyle.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: large ? FontWeight.bold : FontWeight.normal,
    );
  }
}
