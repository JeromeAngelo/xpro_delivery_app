import 'package:flutter/material.dart';

class EndTripOtpInfoCard extends StatelessWidget {
  const EndTripOtpInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield, color: colorScheme.onPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hand the device to the guard so they can enter the OTP code.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
