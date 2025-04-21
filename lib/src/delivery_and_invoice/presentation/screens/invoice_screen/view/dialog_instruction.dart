import 'package:flutter/material.dart';

class DeliveryInstructionsDialog extends StatelessWidget {
  const DeliveryInstructionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Delivery Instructions',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionItem(
              '1. Click the location icon on the map',
              'to view the customer\'s destination',
            ),
             _buildInstructionItem(
              '2. For Unreacahable Customers',
              'set the delivery status to "Mark as Undeliverable" ',
            ),
            _buildInstructionItem(
              '3. Update the Delivery Status to "Arrived" ',
              'When you arrive at the customer\'s location',
            ),
           _buildInstructionItem(
              '4. Update the Delivery Status to "Unloading" first ',
              'before unloading the products'
            ),
            _buildInstructionItem(
              '5. Complete delivery',
              'Update the delivery status to "End Delivery" only after successful handover',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    );
  }
}
