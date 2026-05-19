import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'amount_field.dart';
import 'bank_fields.dart';
import 'cheque_fields.dart';
import 'customers_dashboard_trx.dart';
import 'ewallet_fields.dart';
import 'payment_mode_dropdown.dart';

class TransactionForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final DeliveryDataEntity deliveryData;
  final String? selectedPaymentMode;
  final ValueChanged<String?> onPaymentModeChanged;
  final bool showCashField;
  final bool showStcCashField;
  final bool showBankNameField;
  final bool showChequeNumberField;
  final bool showStcChequeField;
  final bool showEWalletFields;
  final String? selectedBankName;
  final ValueChanged<String?> onBankNameChanged;
  final String? selectedEWalletType;
  final ValueChanged<String?> onEWalletTypeChanged;
  final TextEditingController amountController;
  final TextEditingController chequeNumberController;
  final TextEditingController referenceNumberController;

  const TransactionForm({
    super.key,
    required this.formKey,
    required this.deliveryData,
    required this.selectedPaymentMode,
    required this.onPaymentModeChanged,
    required this.showCashField,
    required this.showStcCashField,
    required this.showBankNameField,
    required this.showChequeNumberField,
    required this.showStcChequeField,
    required this.showEWalletFields,
    required this.selectedBankName,
    required this.onBankNameChanged,
    required this.selectedEWalletType,
    required this.onEWalletTypeChanged,
    required this.amountController,
    required this.chequeNumberController,
    required this.referenceNumberController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                CustomersDashboardTrx(deliveryData: deliveryData),
                const SizedBox(height: 20),
                PaymentModeDropdown(
                  selectedPaymentMode: selectedPaymentMode,
                  onChanged: onPaymentModeChanged,
                ),
                const SizedBox(height: 12),
                AmountField(controller: amountController),
                if (showBankNameField) ...[
                  const SizedBox(height: 12),
                  BankFields(
                    selectedBankName: selectedBankName,
                    onBankNameChanged: onBankNameChanged,
                    referenceNumberController: referenceNumberController,
                  ),
                ],
                if (showChequeNumberField || showStcChequeField) ...[
                  const SizedBox(height: 12),
                  ChequeFields(
                    chequeNumberController: chequeNumberController,
                    referenceNumberController: referenceNumberController,
                  ),
                ],
                if (showEWalletFields) ...[
                  const SizedBox(height: 12),
                  EWalletFields(
                    selectedEWalletType: selectedEWalletType,
                    onEWalletTypeChanged: onEWalletTypeChanged,
                    referenceNumberController: referenceNumberController,
                  ),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
