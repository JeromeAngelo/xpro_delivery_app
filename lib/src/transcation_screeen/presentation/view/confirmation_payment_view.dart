import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

// ignore: depend_on_referenced_packages
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/src/transcation_screeen/presentation/utils/delivery_orders_pdf.dart';

class ConfirmationPaymentView extends StatefulWidget {
  final TransactionModel transaction;
  final CustomerEntity customer;
  final Uint8List generatedPdf; // Add this field

  const ConfirmationPaymentView({
    super.key,
    required this.transaction,
    required this.customer,
    required this.generatedPdf,
  });

  @override
  State<ConfirmationPaymentView> createState() =>
      _ConfirmationPaymentViewState();
}

class _ConfirmationPaymentViewState extends State<ConfirmationPaymentView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late TransactionModel currentTransaction;
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
      customer: widget.customer,
      invoices: widget.transaction.invoices.toList(),
      products:
          widget.transaction.invoices
              .map((invoice) => invoice.productList.toList())
              .expand((products) => products)
              .toList(),
      themeColor: themeColor,
    );
  }

  @override
  void initState() {
    super.initState();
    currentTransaction = widget.transaction;
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
              _buildPdfViewer(),
              _buildPdfOptions(),
              _buildSignaturePad(context),
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

  Widget _buildPdfViewer() {
    return SizedBox(
      height: 450,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        color: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }

  Widget _buildSignaturePad(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
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
            'Sign Here',
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
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Enter your name',
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        alignLabelWithHint: true,
        focusColor: Theme.of(context).colorScheme.primary,
        filled: true,
        fillColor: const Color.fromARGB(40, 199, 199, 199),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  void _resetSignature() {
    _signaturePadKey.currentState?.clear();
  }

  Widget _buildCameraButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: RoundedButton(
        onPressed: () => _takePicture(context),
        label: 'Take Picture',
        icon: const Icon(Icons.camera_alt_outlined),
      ),
    );
  }

  Future<void> _takePicture(BuildContext context) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        capturedImages.add(photo.path);
      });
    }
  }

  Widget _buildImageGallery(BuildContext context) {
    return capturedImages.isEmpty
        ? const SizedBox.shrink()
        : GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: capturedImages.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Center(
                  child: Image.file(
                    File(capturedImages[index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -5,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      setState(() {
                        capturedImages.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            );
          },
        );
  }

  Future<File> _convertSignatureToPdf() async {
    try {
      debugPrint('🖊️ Converting signature to PDF...');
      final signatureData = await _signaturePadKey.currentState?.toImage();
      if (signatureData == null) throw Exception('No signature data available');

      final bytes = await signatureData.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (bytes == null) {
        throw Exception('Failed to convert signature to bytes');
      }

      final tempDir = await getTemporaryDirectory();
      final signaturePdfPath = '${tempDir.path}/signature.pdf';
      final signaturePdf = File(signaturePdfPath);

      final pdf = pw.Document();
      final image = pw.MemoryImage(bytes.buffer.asUint8List());

      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Center(child: pw.Image(image));
          },
        ),
      );

      await signaturePdf.writeAsBytes(await pdf.save());
      debugPrint('✅ Signature PDF created successfully');
      return signaturePdf;
    } catch (e) {
      debugPrint('❌ Signature conversion failed: $e');
      rethrow;
    }
  }

  Widget _buildConfirmButton(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              textStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onPressed:
                state is TransactionLoading
                    ? null
                    : () async {
                      if (_formKey.currentState!.validate() &&
                          _validateFields()) {
                        try {
                          final signaturePdf = await _convertSignatureToPdf();
                          final bytes =
                              await _pdfViewerController.saveDocument();
                          final tempDir = await getTemporaryDirectory();
                          final pdfPath = '${tempDir.path}/receipt.pdf';
                          final pdfFile = File(pdfPath);
                          await pdfFile.writeAsBytes(bytes);

                          final updatedTransaction = currentTransaction
                              .copyWith(
                                signature: signaturePdf,
                                customerImage: capturedImages.join(','),
                                pdf: pdfFile,
                                refNumber: widget.transaction.refNumber,
                                totalAmount: widget.transaction.totalAmount,
                                customerName: _nameController.text,
                              );

                          // Update delivery status to Mark as Received
                          context.read<DeliveryUpdateBloc>().add(
                            UpdateDeliveryStatusEvent(
                              customerId: widget.customer.id ?? '',
                              statusId: 'nd6x1z4qrk33wkl',
                            ),
                          );
                          context.read<TransactionBloc>().add(
                            CreateTransactionEvent(
                              transaction: updatedTransaction,
                              customerId: widget.customer.id ?? '',
                              tripId:
                                  context.read<TripBloc>().state is TripLoaded
                                      ? (context.read<TripBloc>().state
                                              as TripLoaded)
                                          .trip
                                          .id!
                                      : '',
                            ),
                          );

                          // Pre-load data for target screen
                          final customerBloc = context.read<CustomerBloc>();

                          // Explicitly type the Future.wait
                          await Future.wait<void>([
                            customerBloc.stream.firstWhere(
                              (state) => state is CustomerLocationLoaded,
                            ),
                            Future(
                              () => customerBloc.add(
                                LoadLocalCustomerLocationEvent(
                                  widget.customer.id ?? '',
                                ),
                              ),
                            ),
                            Future(
                              () => customerBloc.add(
                                GetCustomerLocationEvent(
                                  widget.customer.id ?? '',
                                ),
                              ),
                            ),
                          ]);

                          // Navigate after data is refreshed
                          context.pushReplacement(
                            '/delivery-and-invoice/${widget.customer.id}',
                            extra: widget.customer,
                          );
                        } catch (e) {
                          debugPrint('❌ Error processing confirmation: $e');
                        }
                      }
                    },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state is TransactionLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                Text(
                  state is TransactionLoading ? 'Processing...' : 'Done',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
