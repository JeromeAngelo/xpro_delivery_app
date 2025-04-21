import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class EndTripOtpInput extends StatelessWidget {
  final Function(String) onOtpChanged;

  const EndTripOtpInput({
    super.key,
    required this.onOtpChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Pinput(
      length: 6,
      showCursor: true,
      onCompleted: onOtpChanged,
      onChanged: onOtpChanged,
      defaultPinTheme: PinTheme(
        width: 50,
        height: 50,
        textStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
