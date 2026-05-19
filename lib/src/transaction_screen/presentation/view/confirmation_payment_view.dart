import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/utils/confirmation_payment_widgets/confirmation_payment_form.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/utils/confirmation_payment_widgets/delivery_orders_pdf.dart';

class ConfirmationPaymentView extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final Uint8List generatedPdf;
  final double amount;
  final String referenceNumber;
  final ModeOfPayment modeOfPayment;
  final String? chequeNumber;
  final String? eWalletType;
  final String? eWalletAccount;
  final String? bankName;
  final GlobalKey<SfSignaturePadState> signaturePadKey;
  final TextEditingController nameController;
  final List<String> capturedImages;
  final VoidCallback onTakePicture;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onResetSignature;
  final VoidCallback onConfirmPayment;

  const ConfirmationPaymentView({
    super.key,
    required this.deliveryData,
    required this.generatedPdf,
    required this.amount,
    required this.referenceNumber,
    required this.modeOfPayment,
    required this.signaturePadKey,
    required this.nameController,
    required this.capturedImages,
    required this.onTakePicture,
    required this.onRemoveImage,
    required this.onResetSignature,
    required this.onConfirmPayment,
    this.chequeNumber,
    this.eWalletType,
    this.eWalletAccount,
    this.bankName,
  });

  @override
  State<ConfirmationPaymentView> createState() =>
      _ConfirmationPaymentViewState();
}

class _ConfirmationPaymentViewState extends State<ConfirmationPaymentView> {
  final _formKey = GlobalKey<FormState>();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfPageFormat _selectedPageFormat = PdfPageFormat.a4;
  bool _isLandscape = false;

  Future<Uint8List> _generatePdf() async {
    final themeColor = PdfColor.fromHex(
      Theme.of(context).colorScheme.primary.value.toRadixString(16),
    );

    return DeliveryOrdersPDF.generatePDF(
      deliveryData: widget.deliveryData,
      themeColor: themeColor,
    );
  }

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo(
      '📝 Payment confirmation initialized',
      details:
          'Customer: ${widget.deliveryData.storeName}, Amount: ₱${widget.amount.toStringAsFixed(2)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationPaymentForm(
      formKey: _formKey,
      deliveryData: widget.deliveryData,
      generatedPdf: widget.generatedPdf,
      amount: widget.amount,
      nameController: widget.nameController,
      signaturePadKey: widget.signaturePadKey,
      pdfViewerController: _pdfViewerController,
      selectedPageFormat: _selectedPageFormat,
      isLandscape: _isLandscape,
      capturedImages: widget.capturedImages,
      onGeneratePdf: _generatePdf,
      onPageFormatChanged: (value) {
        if (value != null) {
          setState(() => _selectedPageFormat = value);
        }
      },
      onOrientationChanged: (isLandscape) {
        setState(() => _isLandscape = isLandscape);
      },
      onResetSignature: widget.onResetSignature,
      onTakePicture: widget.onTakePicture,
      onRemoveImage: widget.onRemoveImage,
      onConfirmPayment: widget.onConfirmPayment,
    );
  }
}
