import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/presentation/bloc/delivery_receipt_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/presentation/bloc/delivery_receipt_state.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/src/transaction_screen/presentation/utils/delivery_orders_pdf.dart';

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

  const ConfirmationPaymentView({
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
  State<ConfirmationPaymentView> createState() =>
      _ConfirmationPaymentViewState();
}

class _ConfirmationPaymentViewState extends State<ConfirmationPaymentView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfPageFormat _selectedPageFormat = PdfPageFormat.a4;
  bool _isLandscape = false;
  List<String> capturedImages = [];

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
    // Pre-populate customer name if available
    final customer = widget.deliveryData.customer.target;
    if (customer?.name != null) {
      _nameController.text = customer!.name!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    if (_signaturePadKey.currentState?.clear == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please provide signature')));
      return false;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return false;
    }

    if (capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take at least one picture')),
      );
      return false;
    }

    return true;
  }

  void _changeOrientation(bool isLandscape) {
    setState(() {
      _isLandscape = isLandscape;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
              _buildHeader(context),
              _buildPdfViewer(),
              _buildPdfOptions(),
              // _buildPaymentSummary(context),
              const SizedBox(height: 15),

              _buildSignaturePad(context),
              const SizedBox(height: 15),

              _buildNameField(context),
              const SizedBox(height: 15),
              _buildCameraButton(context),
              const SizedBox(height: 15),
              _buildImageGallery(context),
              const SizedBox(height: 15),
              _buildConfirmButton(context),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Text(
            'Payment Confirmation',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review and confirm your payment details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return SizedBox(
      height: 450,
      //  margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SfPdfViewer.memory(
        widget.generatedPdf,
        controller: _pdfViewerController,
        enableDoubleTapZooming: true,
        canShowPageLoadingIndicator: true,
        canShowScrollHead: true,
        enableTextSelection: false,
        canShowPaginationDialog: false,
        enableDocumentLinkAnnotation: false,
        pageLayoutMode:
            _isLandscape
                ? PdfPageLayoutMode.single
                : PdfPageLayoutMode.continuous,
      ),
    );
  }

  Widget _buildPdfOptions() {
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16),
      // padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        //  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () async {
              await Printing.layoutPdf(onLayout: (_) => _generatePdf());
            },
            icon: Icon(
              Icons.print,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          IconButton(
            onPressed: () async {
              final bytes = await _generatePdf();
              final file = XFile.fromData(bytes, name: 'delivery_order.pdf');
              await Share.shareXFiles([file], text: 'Delivery Order');
            },
            icon: Icon(
              Icons.share,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          DropdownButton<PdfPageFormat>(
            dropdownColor: Theme.of(context).colorScheme.onSurface,
            iconEnabledColor: Theme.of(context).colorScheme.surface,
            value: _selectedPageFormat,
            items:
                [PdfPageFormat.a4, PdfPageFormat.letter].map((format) {
                  return DropdownMenuItem<PdfPageFormat>(
                    value: format,
                    child: Text(
                      format == PdfPageFormat.a4 ? 'A4' : 'Letter',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPageFormat = value!;
              });
            },
          ),
          IconButton(
            color:
                !_isLandscape
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.outlineVariant,
            icon: const Icon(Icons.stay_current_portrait),
            onPressed: () => _changeOrientation(false),
          ),
          IconButton(
            color:
                _isLandscape
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.outlineVariant,
            icon: const Icon(Icons.stay_current_landscape),
            onPressed: () => _changeOrientation(true),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturePad(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 200,

          child: SfSignaturePad(
            key: _signaturePadKey,
            backgroundColor: const Color.fromARGB(40, 199, 199, 199),
            onDrawEnd: () {},
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Text(
            'Customer Signature',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Positioned(
          bottom: 3,
          right: 8,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.cancel_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _resetSignature,
              ),
              Text(
                'Reset',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        onTap: () {
          _nameController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _nameController.text.length,
          );
        },
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Customer Name',
          labelStyle: Theme.of(context).textTheme.bodyMedium,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          filled: true,
          fillColor: const Color.fromARGB(40, 199, 199, 199),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter customer name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCameraButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _takePicture,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Take Picture'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    if (capturedImages.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No images captured yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: capturedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(capturedImages[index]),
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return BlocConsumer<DeliveryReceiptBloc, DeliveryReceiptState>(
      listener: (context, state) {
        if (state is DeliveryReceiptCreated) {
          debugPrint('🔄 Processing delivery receipt creation success');

          // Show immediate feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Payment confirmed successfully!'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: Duration(seconds: 2),
            ),
          );

          // 🔄 FORCE CACHE INVALIDATION: Clear cached data to force fresh load
          debugPrint('🔄 Invalidating cached delivery data to force refresh');
          
          // Navigate immediately after local creation
          debugPrint(
            '🚀 Navigating to target screen with cache invalidation',
          );
          Navigator.of(context).pop(); // Close modal

          // Force immediate data refresh before navigation
          if (context.mounted) {
            final deliveryBloc = context.read<DeliveryDataBloc>();
            
            // Invalidate cache by loading fresh data immediately
            deliveryBloc.add(GetDeliveryDataByIdEvent(widget.deliveryData.id!));
            deliveryBloc.add(GetLocalDeliveryDataByIdEvent(widget.deliveryData.id!));
          }

          // Navigate to delivery and invoice view with customer ID
          debugPrint('🔄 Navigating to delivery and invoice view for customer: ${widget.deliveryData.id}');
          context.go(
            '/delivery-and-invoice/${widget.deliveryData.id}',
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
      builder: (context, state) {
        final isLoading = state is DeliveryReceiptLoading;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: RoundedButton(
            onPressed: isLoading ? null : () => _confirmPayment(),
            label: isLoading ? 'Processing...' : 'Confirm Payment',
            isLoading: isLoading,
            buttonColour: Theme.of(context).colorScheme.primary,
            labelColour: Theme.of(context).colorScheme.onPrimary,
          ),
        );
      },
    );
  }

  void _resetSignature() {
    _signaturePadKey.currentState?.clear();
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          capturedImages.add(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      capturedImages.removeAt(index);
    });
  }

  // Update the _confirmPayment method to be synchronous:
  void _confirmPayment() {
    if (!_validateFields()) return;

    // Show immediate feedback that processing has started
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Saving payment confirmation...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );

    // Execute async operation without await in the callback
    _executeConfirmPayment();
  }

  Future<void> _executeConfirmPayment() async {
    try {
      // Get signature as image
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

      // Save receipt file
      final directory = await getApplicationDocumentsDirectory();
      final receiptFile = File(
        '${directory.path}/receipt_${widget.deliveryData.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await receiptFile.writeAsBytes(widget.generatedPdf);

      // Create delivery receipt
      if (mounted) {
        context.read<DeliveryReceiptBloc>().add(
          CreateDeliveryReceiptEvent(
            deliveryDataId: widget.deliveryData.id!,
            status: 'completed',
            dateTimeCompleted: DateTime.now(),
            amount: widget.amount,
            customerImages: capturedImages,
            customerSignature: signaturePath,
            receiptFile: receiptFile.path,
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
}
