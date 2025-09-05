import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/view/confirmation_payment_view.dart';

class ConfirmPaymentBtn extends StatelessWidget {
  final DeliveryDataEntity deliveryData;
  final Uint8List generatedPdf;
  final double amount;
  final String referenceNumber;
  final ModeOfPayment? modeOfPayment;
  final String? chequeNumber;
  final String? eWalletType;
  final String? eWalletAccount;
  final String? bankName;

  const ConfirmPaymentBtn({
    super.key,
    required this.deliveryData,
    required this.generatedPdf,
    required this.amount,
    required this.referenceNumber,
    required this.modeOfPayment,
    this.chequeNumber,
    this.eWalletType,
    this.eWalletAccount,
    this.bankName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _showConfirmationModal(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment),
            const SizedBox(width: 8),
            Text(
              'Confirm Delivery',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

   void _showConfirmationModal(BuildContext context) {
    debugPrint('🔄 Showing payment confirmation modal');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: BlocProvider.value(
          value: context.read<DeliveryReceiptBloc>(),
          child: ConfirmationPaymentView(
            deliveryData: deliveryData,
            generatedPdf: generatedPdf,
            amount: amount,
            referenceNumber: referenceNumber,
            modeOfPayment: modeOfPayment!,
            chequeNumber: chequeNumber,
            eWalletType: eWalletType,
            eWalletAccount: eWalletAccount,
            bankName: bankName,
          ),
        ),
      ),
    );
  }

}
