import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfOptionsBar extends StatelessWidget {
  final PdfPageFormat selectedPageFormat;
  final bool isLandscape;
  final Future<Uint8List> Function() onGeneratePdf;
  final ValueChanged<PdfPageFormat?> onPageFormatChanged;
  final ValueChanged<bool> onOrientationChanged;

  const PdfOptionsBar({
    super.key,
    required this.selectedPageFormat,
    required this.isLandscape,
    required this.onGeneratePdf,
    required this.onPageFormatChanged,
    required this.onOrientationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () async {
              await Printing.layoutPdf(onLayout: (_) => onGeneratePdf());
            },
            icon: Icon(
              Icons.print,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          IconButton(
            onPressed: () async {
              final bytes = await onGeneratePdf();
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
            value: selectedPageFormat,
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
            onChanged: onPageFormatChanged,
          ),
          IconButton(
            color:
                !isLandscape
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.outlineVariant,
            icon: const Icon(Icons.stay_current_portrait),
            onPressed: () => onOrientationChanged(false),
          ),
          IconButton(
            color:
                isLandscape
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.outlineVariant,
            icon: const Icon(Icons.stay_current_landscape),
            onPressed: () => onOrientationChanged(true),
          ),
        ],
      ),
    );
  }
}
