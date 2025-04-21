import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/src/transcation_screeen/presentation/view/confirmation_payment_view.dart';
class ConfirmPaymentBtn extends StatelessWidget {
  final VoidCallback? onPressed;
  final TransactionModel transaction;
  final CustomerEntity customer;
final Uint8List generatedPdf;
  const ConfirmPaymentBtn({
    super.key,
    this.onPressed,
    required this.transaction,
    required this.customer,
    required this.generatedPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: RoundedButton(
        label: 'Confirm Payment',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            enableDrag: true,
            useSafeArea: true,
            builder: (context) => ConfirmationPaymentView(
              transaction: transaction,
              customer: customer,
              generatedPdf: generatedPdf,
            ),
          );
          if (onPressed != null) {
            onPressed!();
          }
        },
      ),
    );
  }
}

