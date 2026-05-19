import 'package:flutter/material.dart';
import 'reference_number_field.dart';

class EWalletFields extends StatelessWidget {
  final String? selectedEWalletType;
  final ValueChanged<String?> onEWalletTypeChanged;
  final TextEditingController referenceNumberController;

  const EWalletFields({
    super.key,
    required this.selectedEWalletType,
    required this.onEWalletTypeChanged,
    required this.referenceNumberController,
  });

  static const List<String> _eWalletTypes = ['GCash', 'Maya'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'E-Wallet Type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: selectedEWalletType,
          items:
              _eWalletTypes
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: onEWalletTypeChanged,
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        if (selectedEWalletType == 'GCash') ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/g-cash-payment.jpg',
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
        if (selectedEWalletType == 'Maya') ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Image.asset('assets/images/paymaya-qr.png')),
          ),
        ],
        const SizedBox(height: 12),
        ReferenceNumberField(controller: referenceNumberController),
      ],
    );
  }
}
