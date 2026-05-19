import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'camera_button.dart';
import 'confirm_payment_button.dart';
import 'customer_name_field.dart';
import 'image_gallery.dart';
import 'payment_confirmation_header.dart';
import 'payment_summary.dart';
import 'pdf_options_bar.dart';
import 'pdf_viewer_section.dart';
import 'signature_pad_section.dart';

class ConfirmationPaymentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final DeliveryDataEntity deliveryData;
  final Uint8List generatedPdf;
  final double amount;
  final TextEditingController nameController;
  final GlobalKey<SfSignaturePadState> signaturePadKey;
  final PdfViewerController pdfViewerController;
  final PdfPageFormat selectedPageFormat;
  final bool isLandscape;
  final List<String> capturedImages;
  final Future<Uint8List> Function() onGeneratePdf;
  final ValueChanged<PdfPageFormat?> onPageFormatChanged;
  final ValueChanged<bool> onOrientationChanged;
  final VoidCallback onResetSignature;
  final VoidCallback onTakePicture;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onConfirmPayment;

  const ConfirmationPaymentForm({
    super.key,
    required this.formKey,
    required this.deliveryData,
    required this.generatedPdf,
    required this.amount,
    required this.nameController,
    required this.signaturePadKey,
    required this.pdfViewerController,
    required this.selectedPageFormat,
    required this.isLandscape,
    required this.capturedImages,
    required this.onGeneratePdf,
    required this.onPageFormatChanged,
    required this.onOrientationChanged,
    required this.onResetSignature,
    required this.onTakePicture,
    required this.onRemoveImage,
    required this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 15,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaymentConfirmationHeader(),
              PdfViewerSection(
                generatedPdf: generatedPdf,
                controller: pdfViewerController,
                isLandscape: isLandscape,
              ),
              PdfOptionsBar(
                selectedPageFormat: selectedPageFormat,
                isLandscape: isLandscape,
                onGeneratePdf: onGeneratePdf,
                onPageFormatChanged: onPageFormatChanged,
                onOrientationChanged: onOrientationChanged,
              ),
              PaymentSummary(amount: amount),
              SignaturePadSection(
                signaturePadKey: signaturePadKey,
                onReset: onResetSignature,
              ),
              const SizedBox(height: 15),
              CustomerNameField(controller: nameController),
              const SizedBox(height: 15),
              CameraButton(onPressed: onTakePicture),
              const SizedBox(height: 15),
              ImageGallery(
                capturedImages: capturedImages,
                onRemoveImage: onRemoveImage,
              ),
              const SizedBox(height: 15),
              ConfirmPaymentButton(
                deliveryData: deliveryData,
                onConfirm: onConfirmPayment,
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
