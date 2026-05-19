import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_state.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/utils/transaction_view_widgets/confirm_payment_btn.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/utils/transaction_view_widgets/transaction_form.dart';

class TransactionView extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final Uint8List? generatedPdf;

  const TransactionView({
    super.key,
    required this.deliveryData,
    this.generatedPdf,
  });

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _chequeNumberController = TextEditingController();
  final _eWalletAccountController = TextEditingController();
  final _referenceNumberController = TextEditingController();

  String? _selectedPaymentMode;
  String? _selectedEWalletType;
  String? _selectedBankName;
  bool _showChequeNumberField = false;
  bool _showEWalletFields = false;
  bool _showBankNameField = false;
  bool _showCashField = false;
  bool _showStcCashField = false;
  bool _showStcChequeField = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo(
      '💰 Transaction screen initialized for customer: ${widget.deliveryData.storeName ?? 'Unknown'}',
      details: 'Delivery ID: ${widget.deliveryData.id}',
    );
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.deliveryData.paymentSelection != null) {
      _selectedPaymentMode = _formatPaymentMode(
        widget.deliveryData.paymentSelection.toString(),
      );
      _updateFieldVisibility(_selectedPaymentMode);
    }

    final totalAmount = widget.deliveryData.totalAmount ?? 0.0;
    _amountController.text = totalAmount.toStringAsFixed(2);

    debugPrint(
      '💰 Transaction amount initialized from deliveryData.totalAmount: ₱${totalAmount.toStringAsFixed(2)}',
    );
  }

  String _formatPaymentMode(String paymentSelection) {
    return paymentSelection
        .split('.')
        .last
        .split(RegExp(r'(?=[A-Z])'))
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
        )
        .join(' ')
        .replaceAll('E Wallet', 'E-Wallet');
  }

  void _updateFieldVisibility(String? paymentMode) {
    _showCashField = paymentMode == 'DTC - COD';
    _showEWalletFields = paymentMode == 'E-Wallet';
    _showBankNameField = paymentMode == 'Bank Transfer';
    _showChequeNumberField = paymentMode == 'DTC - CHK';
    _showStcCashField = paymentMode == 'STC-Cash';
    _showStcChequeField = paymentMode == 'STC-CHK';
  }

  void _handlePaymentModeChange(String? newValue) async {
    AppDebugLogger.instance.logInfo(
      '💳 Payment mode selected: ${newValue ?? 'None'}',
      details: 'Customer: ${widget.deliveryData.storeName}',
    );

    setState(() {
      _isLoading = true;
      _selectedPaymentMode = newValue;
      _updateFieldVisibility(newValue);
      _selectedEWalletType = null;
      _selectedBankName = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  ModeOfPayment _getModeOfPaymentEnum(String? mode) {
    switch (mode) {
      case 'Bank Transfer':
        return ModeOfPayment.bankTransfer;
      case 'DTC - COD':
        return ModeOfPayment.cashOnDelivery;
      case 'DTC - CHK':
        return ModeOfPayment.dtcCheque;
      case 'E-Wallet':
        return ModeOfPayment.eWallet;
      case 'STC-Cash':
        return ModeOfPayment.stcCash;
      case 'STC-CHK':
        return ModeOfPayment.stcCheque;
      default:
        return ModeOfPayment.cashOnDelivery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return BlocListener<DeliveryReceiptBloc, DeliveryReceiptState>(
      listener: (context, state) {
        if (state is DeliveryReceiptCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery receipt created successfully'),
            ),
          );
        } else if (state is DeliveryReceiptError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is DeliveryReceiptLoaded) {
          debugPrint('✅ Existing delivery receipt loaded');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Transaction'), centerTitle: true),
        body: Stack(
          children: [
            TransactionForm(
              formKey: _formKey,
              deliveryData: widget.deliveryData,
              selectedPaymentMode: _selectedPaymentMode,
              onPaymentModeChanged: _handlePaymentModeChange,
              showCashField: _showCashField,
              showStcCashField: _showStcCashField,
              showBankNameField: _showBankNameField,
              showChequeNumberField: _showChequeNumberField,
              showStcChequeField: _showStcChequeField,
              showEWalletFields: _showEWalletFields,
              selectedBankName: _selectedBankName,
              onBankNameChanged:
                  (value) => setState(() => _selectedBankName = value),
              selectedEWalletType: _selectedEWalletType,
              onEWalletTypeChanged:
                  (value) => setState(() => _selectedEWalletType = value),
              amountController: _amountController,
              chequeNumberController: _chequeNumberController,
              referenceNumberController: _referenceNumberController,
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
            if (!isKeyboardVisible)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ConfirmPaymentBtn(
                  deliveryData: widget.deliveryData,
                  generatedPdf: widget.generatedPdf!,
                  amount: double.tryParse(_amountController.text) ?? 0.0,
                  referenceNumber: _referenceNumberController.text.trim(),
                  modeOfPayment: _getModeOfPaymentEnum(_selectedPaymentMode),
                  chequeNumber:
                      _chequeNumberController.text.trim().isEmpty
                          ? null
                          : _chequeNumberController.text.trim(),
                  eWalletType: _selectedEWalletType,
                  eWalletAccount:
                      _eWalletAccountController.text.trim().isEmpty
                          ? null
                          : _eWalletAccountController.text.trim(),
                  bankName: _selectedBankName,
                  formKey: _formKey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _chequeNumberController.dispose();
    _eWalletAccountController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }
}
