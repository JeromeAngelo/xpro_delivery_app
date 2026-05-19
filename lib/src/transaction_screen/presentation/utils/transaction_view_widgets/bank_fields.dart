import 'package:flutter/material.dart';
import 'reference_number_field.dart';

class BankFields extends StatelessWidget {
  final String? selectedBankName;
  final ValueChanged<String?> onBankNameChanged;
  final TextEditingController referenceNumberController;

  const BankFields({
    super.key,
    required this.selectedBankName,
    required this.onBankNameChanged,
    required this.referenceNumberController,
  });

  static const List<String> _bankNames = ['BDO', 'Metrobank', 'Security Bank'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Bank Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: selectedBankName,
          items:
              _bankNames
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: onBankNameChanged,
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        ReferenceNumberField(controller: referenceNumberController),
      ],
    );
  }
}
