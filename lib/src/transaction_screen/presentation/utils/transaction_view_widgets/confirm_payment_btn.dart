import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_event.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/view/confirmation_payment_view.dart';

class ConfirmPaymentBtn extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final Uint8List generatedPdf;
  final double amount;
  final String referenceNumber;
  final ModeOfPayment modeOfPayment;
  final String? chequeNumber;
  final String? eWalletType;
  final String? eWalletAccount;
  final String? bankName;
  final GlobalKey<FormState>? formKey;

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
    this.formKey,
  });

  @override
  State<ConfirmPaymentBtn> createState() => _ConfirmPaymentBtnState();
}

class _ConfirmPaymentBtnState extends State<ConfirmPaymentBtn> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  final List<String> _capturedImages = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _resetSignature() {
    _signaturePadKey.currentState?.clear();
  }

  Future<void> _takePicture() async {
    AppDebugLogger.instance.logInfo('📷 Camera opened for delivery photo');

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _capturedImages.add(image.path);
        });
        AppDebugLogger.instance.logSuccess(
          '📸 Photo captured successfully',
          details: 'Total photos: ${_capturedImages.length}',
        );
      }
    } catch (e) {
      AppDebugLogger.instance.logError('❌ Camera error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  Future<void> _executeConfirmPayment() async {
    try {
      final signatureImage = await _signaturePadKey.currentState?.toImage();
      String? signaturePath;

      if (signatureImage != null) {
        final byteData = await signatureImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        final bytes = byteData!.buffer.asUint8List();

        final directory = await getTemporaryDirectory();
        final signatureFile = File(
          '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await signatureFile.writeAsBytes(bytes);
        signaturePath = signatureFile.path;
      }

      final directory = await getApplicationDocumentsDirectory();
      final receiptFile = File(
        '${directory.path}/receipt_${widget.deliveryData.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await receiptFile.writeAsBytes(widget.generatedPdf);

      if (mounted) {
        context.read<DeliveryReceiptBloc>().add(
          CreateDeliveryReceiptEvent(
            deliveryDataId: widget.deliveryData.id!,
            status: 'completed',
            dateTimeCompleted: DateTime.now(),
            amount: widget.amount,
            customerImages: _capturedImages,
            customerSignature: signaturePath,
            receiptFile: receiptFile.path,
            referenceNumber: widget.referenceNumber,
            modeOfPayment: widget.modeOfPayment.name,
            chequeNumber: widget.chequeNumber,
            eWalletType: widget.eWalletType,
            bankName: widget.bankName,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error confirming payment: $e')));
      }
    }
  }

  void _showConfirmationModal(BuildContext context) {
    debugPrint('🔄 Showing payment confirmation modal');

    // Validate the form fields (amount, payment mode, etc.)
    if (widget.formKey != null && !widget.formKey!.currentState!.validate()) {
      return;
    }

    if (widget.amount <= 0) {
      CoreUtils.showSnackBar(
        context,
        'Total amount cannot be zero or negative',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder:
          (context) => Container(
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
                deliveryData: widget.deliveryData,
                generatedPdf: widget.generatedPdf,
                amount: widget.amount,
                referenceNumber: widget.referenceNumber,
                modeOfPayment: widget.modeOfPayment,
                chequeNumber: widget.chequeNumber,
                eWalletType: widget.eWalletType,
                eWalletAccount: widget.eWalletAccount,
                bankName: widget.bankName,
                signaturePadKey: _signaturePadKey,
                nameController: _nameController,
                capturedImages: _capturedImages,
                onTakePicture: _takePicture,
                onRemoveImage: _removeImage,
                onResetSignature: _resetSignature,
                onConfirmPayment: () {
                  Navigator.of(context).pop();
                  _executeConfirmPayment();
                },
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryReceiptBloc, DeliveryReceiptState>(
      listener: (context, state) {
        if (state is DeliveryReceiptCreated) {
          AppDebugLogger.instance.logSuccess(
            '✅ Payment confirmation completed',
            details:
                'Customer: ${widget.deliveryData.storeName}, Amount: ₱${widget.amount.toStringAsFixed(2)}',
          );

          debugPrint(
            '🔄 Triggering end delivery for ${widget.deliveryData.id}',
          );
          context.read<DeliveryStatusChoicesBloc>().add(
            SetEndDeliveryEvent(deliveryData: widget.deliveryData),
          );

          debugPrint('🔄 Invalidating cached delivery data to force refresh');
          debugPrint('🚀 Navigating to target screen with cache invalidation');

          if (context.mounted) {
            final deliveryBloc = context.read<DeliveryDataBloc>();
            deliveryBloc.add(GetDeliveryDataByIdEvent(widget.deliveryData.id!));
            deliveryBloc.add(
              GetLocalDeliveryDataByIdEvent(widget.deliveryData.id!),
            );
          }

          debugPrint(
            '🔄 Navigating to delivery and invoice view for customer: ${widget.deliveryData.id}',
          );
          context.go(
            '/delivery-and-invoice/${widget.deliveryData.id}?showSummary=true',
            extra: widget.deliveryData,
          );

          debugPrint('✅ Navigation completed with forced refresh');
        } else if (state is DeliveryReceiptError) {
          debugPrint('❌ Delivery receipt creation failed: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error: ${state.message}')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: SizedBox(
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
      ),
    );
  }
}
