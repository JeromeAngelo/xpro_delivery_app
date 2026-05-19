import 'package:flutter/material.dart';
import 'reference_number_field.dart';

class ChequeFields extends StatelessWidget {
  final TextEditingController chequeNumberController;
  final TextEditingController referenceNumberController;

  const ChequeFields({
    super.key,
    required this.chequeNumberController,
    required this.referenceNumberController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Cheque Number',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: chequeNumberController,
          decoration: InputDecoration(
            label: const Text('Cheque Number'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        ReferenceNumberField(controller: referenceNumberController),
      ],
    );
  }
}
