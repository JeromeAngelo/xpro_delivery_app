import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';

class ConfirmPaymentButton extends StatelessWidget {
  final DeliveryDataEntity deliveryData;
  final VoidCallback onConfirm;

  const ConfirmPaymentButton({
    super.key,
    required this.deliveryData,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: RoundedButton(
        onPressed: onConfirm,
        label: 'Confirm Payment',
        buttonColour: Theme.of(context).colorScheme.primary,
        labelColour: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
