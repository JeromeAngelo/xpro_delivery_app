import 'package:flutter/material.dart';

class PaymentModeDropdown extends StatelessWidget {
  final String? selectedPaymentMode;
  final ValueChanged<String?> onChanged;

  const PaymentModeDropdown({
    super.key,
    required this.selectedPaymentMode,
    required this.onChanged,
  });

  static const List<String> _paymentModes = [
    'Bank Transfer',
    'DTC - COD',
    'DTC - CHK',
    'E-Wallet',
    'STC-Cash',
    'STC-CHK',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        labelText: 'Mode of Payment',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: selectedPaymentMode,
      items:
          _paymentModes
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Required' : null,
    );
  }
}
