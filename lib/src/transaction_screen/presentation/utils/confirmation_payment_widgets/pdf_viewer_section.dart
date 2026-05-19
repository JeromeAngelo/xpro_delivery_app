import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerSection extends StatelessWidget {
  final Uint8List generatedPdf;
  final PdfViewerController controller;
  final bool isLandscape;

  const PdfViewerSection({
    super.key,
    required this.generatedPdf,
    required this.controller,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450,
      child: SfPdfViewer.memory(
        generatedPdf,
        controller: controller,
        enableDoubleTapZooming: true,
        canShowPageLoadingIndicator: true,
        canShowScrollHead: true,
        enableTextSelection: false,
        canShowPaginationDialog: false,
        enableDocumentLinkAnnotation: false,
        pageLayoutMode:
            isLandscape
                ? PdfPageLayoutMode.single
                : PdfPageLayoutMode.continuous,
      ),
    );
  }
}
