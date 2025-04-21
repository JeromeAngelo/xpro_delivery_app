import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_state.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/enums/transaction_status.dart';
import 'package:x_pro_delivery_app/src/transcation_screeen/presentation/utils/confirm_payment_btn.dart';
import 'package:x_pro_delivery_app/src/transcation_screeen/presentation/utils/customers_dashboard_trx.dart';
import 'package:x_pro_delivery_app/src/transcation_screeen/presentation/view/confirmation_payment_view.dart';

class TransactionView extends StatefulWidget {
  final CustomerEntity customer;
  final List<InvoiceEntity> selectedInvoices;
  final Uint8List generatedPdf;

  const TransactionView({
    super.key,
    required this.customer,
    required this.selectedInvoices,
    required this.generatedPdf,
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
  bool _isLoading = false;
  late TransactionModel _currentTransaction;

  @override
  void initState() {
    super.initState();
    _initializeTransaction();
    context
        .read<CustomerBloc>()
        .add(LoadLocalCustomerLocationEvent(widget.customer.id ?? ''));
  }

 void _initializeTransaction() {
  _currentTransaction = TransactionModel(
    customerModel: widget.customer as CustomerModel,  // Cast the entity to model
    customerName: widget.customer.storeName ?? '',
    deliveryNumber: widget.selectedInvoices.first.invoiceNumber,
    invoices: widget.selectedInvoices.cast<InvoiceModel>().toList(),
    transactionStatus: TransactionStatus.pending,
    transactionDate: DateTime.now(),
    totalAmount: widget.customer.totalAmount.toString(),
    modeOfPayment: ModeOfPayment.cashOnDelivery,
    isCompleted: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}



  bool _validateFields() {
    if (_selectedPaymentMode == null) {
      _showErrorSnackBar('Please select mode of payment');
      return false;
    }

    if (_amountController.text.isEmpty) {
      _showErrorSnackBar('Please enter amount');
      return false;
    }

    if (_showChequeNumberField && _chequeNumberController.text.isEmpty) {
      _showErrorSnackBar('Please enter cheque number');
      return false;
    }

    if (_showEWalletFields) {
      if (_selectedEWalletType == null) {
        _showErrorSnackBar('Please select E-Wallet type');
        return false;
      }
      if (_eWalletAccountController.text.isEmpty) {
        _showErrorSnackBar('Please enter E-Wallet account');
        return false;
      }
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  ModeOfPayment _getModeOfPayment(String? mode) {
    switch (mode) {
      case 'Bank Transfer':
        return ModeOfPayment.bankTransfer;
      case 'Cash ':
        return ModeOfPayment.cashOnDelivery;
      case 'Cheque':
        return ModeOfPayment.cheque;
      case 'E-Wallet':
        return ModeOfPayment.eWallet;
      default:
        return ModeOfPayment.cashOnDelivery;
    }
  }

  void _handlePaymentModeChange(String? newValue) async {
    setState(() {
      _isLoading = true;
      _selectedPaymentMode = newValue;
      _showChequeNumberField = newValue == 'Cheque';
      _showEWalletFields = newValue == 'E-Wallet';
      _showBankNameField = newValue == 'Bank Transfer';
      _showCashField = newValue == 'Cash On Delivery'; // Updated condition
      _selectedEWalletType = null;
      _selectedBankName = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentTransaction = _currentTransaction.copyWith(
        modeOfPayment: _getModeOfPayment(newValue),
        refNumber: _referenceNumberController.text,
      );
      _isLoading = false;
    });
  }

  void _handleAmountChange(String value) {
    _currentTransaction = _currentTransaction.copyWith(
      totalAmount: value,
    );
  }

  Widget _buildPaymentModeDropdown() {
    // Initialize payment mode and fields on first build
    if (_selectedPaymentMode == null) {
      _selectedPaymentMode = widget.customer.paymentSelection
          .toString()
          .split('.')
          .last
          .split(RegExp(r'(?=[A-Z])'))
          .map((word) => word.capitalize())
          .join(' ')
          .replaceAll('E Wallet', 'E-Wallet');

      // Set initial field visibility based on customer's payment selection
      _showCashField = _selectedPaymentMode == 'Cash On Delivery';
      _showEWalletFields = _selectedPaymentMode == 'E-Wallet';
      _showBankNameField = _selectedPaymentMode == 'Bank Transfer';
      _showChequeNumberField = _selectedPaymentMode == 'Cheque';
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        labelText: 'Mode of Payment',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      value: _selectedPaymentMode,
      items: ['Bank Transfer', 'Cash On Delivery', 'Cheque', 'E-Wallet']
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: _handlePaymentModeChange,
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter total amount collected',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            label: const Text('₱'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onChanged: _handleAmountChange,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction details saved')),
          );
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaction'),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        CustomersDashboardTrx(customer: widget.customer),
                        const SizedBox(height: 20),
                        _buildPaymentModeDropdown(),
                        if (_showCashField) ...[
                          const SizedBox(height: 12),
                          _buildAmountField(),
                        ],
                        if (_showBankNameField) ...[
                          const SizedBox(height: 12),
                          _buildBankFields(),
                        ],
                        if (_showChequeNumberField) ...[
                          const SizedBox(height: 12),
                          _buildChequeFields(),
                        ],
                        if (_showEWalletFields) ...[
                          const SizedBox(height: 12),
                          _buildEWalletFields(),
                        ],
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!isKeyboardVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ConfirmPaymentBtn(
                    transaction: _currentTransaction,
                    customer: widget.customer,
                    generatedPdf: widget.generatedPdf,
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          _validateFields()) {
                        _currentTransaction = _currentTransaction.copyWith(
                          refNumber: _referenceNumberController.text,
                        );
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          enableDrag: true,
                          useSafeArea: true,
                          builder: (context) => ConfirmationPaymentView(
                            transaction: _currentTransaction,
                            customer: widget.customer,
                            generatedPdf: widget.generatedPdf,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Bank Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          value: _selectedBankName,
          items: ['BDO', 'Metrobank', 'RCBC', 'LandBank', 'Others']
              .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) => setState(() => _selectedBankName = value),
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _buildAmountField(),
        const SizedBox(height: 12),
        _buildReferenceNumberField(),
      ],
    );
  }

  Widget _buildChequeFields() {
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
          controller: _chequeNumberController,
          decoration: InputDecoration(
            label: const Text('Cheque Number'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _buildAmountField(),
        const SizedBox(height: 12),
        _buildReferenceNumberField(),
      ],
    );
  }

  Widget _buildEWalletFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'E-Wallet Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          value: _selectedEWalletType,
          items: ['GCash', 'Maya']
              .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) => setState(() {
            _selectedEWalletType = value;
          }),
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        if (_selectedEWalletType == 'GCash') ...[
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
        if (_selectedEWalletType == 'Maya') ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset('assets/images/paymaya-qr.png'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildAmountField(),
        const SizedBox(height: 12),
        _buildReferenceNumberField(),
      ],
    );
  }

  Widget _buildReferenceNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Reference Number',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _referenceNumberController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
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
