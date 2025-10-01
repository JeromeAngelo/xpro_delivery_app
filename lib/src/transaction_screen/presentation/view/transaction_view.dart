import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_state.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/utils/confirm_payment_btn.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/utils/customers_dashboard_trx.dart';

// Update the constructor to make generatedPdf optional:

class TransactionView extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final Uint8List? generatedPdf; // Make this optional

  const TransactionView({
    super.key,
    required this.deliveryData,
    this.generatedPdf, // Remove required
  });

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
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

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo(
      '💰 Transaction screen initialized for customer: ${widget.deliveryData.storeName ?? 'Unknown'}',
      details: 'Delivery ID: ${widget.deliveryData.id}',
    );
    _initializeFields();
    // _loadExistingReceipt();
  }

  void _initializeFields() {
    // Initialize payment mode from delivery data
    if (widget.deliveryData.paymentSelection != null) {
      _selectedPaymentMode = widget.deliveryData.paymentSelection
          .toString()
          .split('.')
          .last
          .split(RegExp(r'(?=[A-Z])'))
          .map((word) => StringExtension(word).capitalize())
          .join(' ')
          .replaceAll('E Wallet', 'E-Wallet');

      // Set initial field visibility based on payment selection
      _showCashField = _selectedPaymentMode == 'Cash On Delivery';
      _showEWalletFields = _selectedPaymentMode == 'E-Wallet';
      _showBankNameField = _selectedPaymentMode == 'Bank Transfer';
      _showChequeNumberField = _selectedPaymentMode == 'Cheque';
    }

    // Initialize amount from total of all invoices
    final invoices = widget.deliveryData.invoices;
    double totalAmount = 0.0;

    if (invoices.isNotEmpty) {
      for (var invoice in invoices) {
        totalAmount += invoice.totalAmount ?? 0.0;
      }
      _amountController.text = totalAmount.toStringAsFixed(2);

      debugPrint('💰 Transaction amount initialized:');
      debugPrint('   📊 Number of invoices: ${invoices.length}');
      debugPrint(
        '   💵 Total amount from all invoices: ₱${totalAmount.toStringAsFixed(2)}',
      );
    } else {
      debugPrint('⚠️ No invoices found in delivery data');
      _amountController.text = '0.00';
    }
  }


  void _handlePaymentModeChange(String? newValue) async {
    AppDebugLogger.instance.logInfo(
      '💳 Payment mode selected: ${newValue ?? 'None'}',
      details: 'Customer: ${widget.deliveryData.storeName}',
    );
    
    setState(() {
      _isLoading = true;
      _selectedPaymentMode = newValue;
      _showChequeNumberField = newValue == 'Cheque';
      _showEWalletFields = newValue == 'E-Wallet';
      _showBankNameField = newValue == 'Bank Transfer';
      _showCashField = newValue == 'Cash On Delivery';
      _selectedEWalletType = null;
      _selectedBankName = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildPaymentModeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        labelText: 'Mode of Payment',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedPaymentMode,
      items:
          ['Bank Transfer', 'Cash On Delivery', 'Cheque', 'E-Wallet']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
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
          onTap: () {
            _amountController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _amountController.text.length,
            );
          },
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            label: const Text('₱'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildBankFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Bank Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: _selectedBankName,
          items:
              ['BDO', 'Metrobank', 'Security Bank']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: _selectedEWalletType,
          items:
              ['GCash', 'Maya']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged:
              (value) => setState(() {
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
            child: Center(child: Image.asset('assets/images/paymaya-qr.png')),
          ),
        ],
        const SizedBox(height: 12),
        _buildAmountField(),
        const SizedBox(height: 12),
        _buildReferenceNumberField(),
      ],
    );
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
          // You can pre-populate fields if needed
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Transaction'), centerTitle: true),
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
                        CustomersDashboardTrx(
                          deliveryData: widget.deliveryData,
                        ),
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
                child: const Center(child: CircularProgressIndicator()),
              ),

            // Update the button section (lines 417-464) in the existing file:
            if (!isKeyboardVisible)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ConfirmPaymentBtn(
                  deliveryData: widget.deliveryData,
                  generatedPdf: widget.generatedPdf!,
                  amount: double.tryParse(_amountController.text) ?? 0.0,
                  referenceNumber: '',
                  modeOfPayment: ModeOfPayment.cashOnDelivery,
                  chequeNumber: '',
                  eWalletType: '',
                  eWalletAccount: '',
                  bankName: '',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // In the _showConfirmationModal method, update to handle missing PDF:

  // void _showConfirmationModal() {
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }

  //   final amount = double.tryParse(_amountController.text) ?? 0.0;
  //   final referenceNumber = _referenceNumberController.text.trim();
  //   final modeOfPayment = _getModeOfPayment(_selectedPaymentMode);

  //   // Generate PDF if not provided
  //   if (widget.generatedPdf == null) {
  //     // Generate PDF using the delivery receipt BLoC
  //     context.read<DeliveryReceiptBloc>().add(
  //       GenerateDeliveryReceiptPdfEvent(widget.deliveryData),
  //     );

  //     // Listen for PDF generation completion
  //     _showModalAfterPdfGeneration(amount, referenceNumber, modeOfPayment);
  //   } else {
  //     // Use existing PDF
  //     _showModal(amount, referenceNumber, modeOfPayment, widget.generatedPdf!);
  //   }
  // }

  // void _showModalAfterPdfGeneration(
  //   double amount,
  //   String referenceNumber,
  //   ModeOfPayment modeOfPayment,
  // ) {
  //   // Add a BlocListener to wait for PDF generation
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder:
  //         (context) => BlocListener<DeliveryReceiptBloc, DeliveryReceiptState>(
  //           listener: (context, state) {
  //             if (state is DeliveryReceiptPdfGenerated) {
  //               Navigator.of(context).pop(); // Close loading dialog
  //               _showModal(
  //                 amount,
  //                 referenceNumber,
  //                 modeOfPayment,
  //                 state.pdfBytes,
  //               );
  //             } else if (state is DeliveryReceiptError) {
  //               Navigator.of(context).pop(); // Close loading dialog
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text('PDF Generation Error: ${state.message}'),
  //                 ),
  //               );
  //             }
  //           },
  //           child: const Center(child: CircularProgressIndicator()),
  //         ),
  //   );
  // }

  // void _showModal(
  //   double amount,
  //   String referenceNumber,
  //   ModeOfPayment modeOfPayment,
  //   Uint8List pdfBytes,
  // ) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder:
  //         (context) => Container(
  //           height: MediaQuery.of(context).size.height * 0.9,
  //           decoration: BoxDecoration(
  //             color: Theme.of(context).colorScheme.surface,
  //             borderRadius: const BorderRadius.vertical(
  //               top: Radius.circular(20),
  //             ),
  //           ),
  //           child: BlocProvider.value(
  //             value: context.read<DeliveryReceiptBloc>(),
  //             child: ConfirmationPaymentView(
  //               deliveryData: widget.deliveryData,
  //               generatedPdf: pdfBytes,
  //               amount: amount,
  //               referenceNumber: referenceNumber,
  //               modeOfPayment: modeOfPayment,
  //               chequeNumber:
  //                   _chequeNumberController.text.trim().isEmpty
  //                       ? null
  //                       : _chequeNumberController.text.trim(),
  //               eWalletType: _selectedEWalletType,
  //               eWalletAccount:
  //                   _eWalletAccountController.text.trim().isEmpty
  //                       ? null
  //                       : _eWalletAccountController.text.trim(),
  //               bankName: _selectedBankName,
  //             ),
  //           ),
  //         ),
  //   );
  // }

  // Replace the existing _handleConfirmPayment method with:
  // void _handleConfirmPayment() {
  //   if (_validateFields()) {
  //     _showConfirmationModal();
  //   }
  // }

  @override
  void dispose() {
    _amountController.dispose();
    _chequeNumberController.dispose();
    _eWalletAccountController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }
}
