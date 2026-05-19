// ignore_for_file: depend_on_referenced_packages, unused_local_variable

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
class DeliveryOrdersPDF {
  static Future<Uint8List> generatePDF({
    required DeliveryDataEntity deliveryData,
    required PdfColor themeColor,
  }) async {
    final pdf = pw.Document();

    final regularFont = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    final contentStyle = pw.TextStyle(font: regularFont, fontSize: 11);
    final subHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 13);

    final customer = deliveryData.customer.target;
    final invoices = deliveryData.invoices;
    final invoiceItems = deliveryData.invoiceItems;

    if (customer == null) throw Exception('Customer required');
    if (invoices.isEmpty) throw Exception('Invoice required');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),

        build: (context) => [
          /// 🔷 HEADER
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DELIVERY RECEIPT',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 20,
                        color: themeColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'X-Pro Delivery Admin',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date: ${_formatDate(DateTime.now())}',
                      style: contentStyle,
                    ),
                    pw.Text(
                      'Ref #: ${deliveryData.deliveryNumber ?? '-'}',
                      style: contentStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          /// 🔷 DELIVERY + CUSTOMER
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _infoBlock(
                  'Delivery Info',
                  [
                    'Delivery #: ${deliveryData.deliveryNumber ?? 'N/A'}',
                    'Payment: ${deliveryData.paymentMode ?? 'N/A'}',
                    'Date: ${deliveryData.created != null ? _formatDate(deliveryData.created!) : 'N/A'}',
                  ],
                  regularFont,
                  boldFont,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _infoBlock(
                  'Customer',
                  [
                    'Name: ${customer.name ?? 'N/A'}',
                    'Address: ${customer.province ?? 'N/A'}',
                  ],
                  regularFont,
                  boldFont,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          /// 🔷 INVOICE LIST
          pw.Text('Invoices', style: subHeaderStyle),
          pw.SizedBox(height: 8),
          ...invoices.map((invoice) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(invoice.refId ?? invoice.name ?? 'N/A',
                    style: contentStyle),
                pw.Text(
                  invoice.totalAmount != null
                      ? '₱${invoice.totalAmount!.toStringAsFixed(2)}'
                      : '₱0.00',
                  style: contentStyle,
                ),
              ],
            );
          }),

          pw.SizedBox(height: 20),

          /// 🔷 TABLE
          if (invoiceItems.isNotEmpty) ...[
            pw.Text('Invoice Items', style: subHeaderStyle),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              headerDecoration: pw.BoxDecoration(color: themeColor),
              headerStyle: pw.TextStyle(
                font: boldFont,
                color: PdfColors.white,
              ),
              cellStyle: contentStyle,
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headers: [
                'Item',
                'Brand',
                'UOM',
                'Qty',
                'Price',
                'Total',
              ],
              data: invoiceItems.map((item) {
                return [
                  item.name ?? 'N/A',
                  item.brand ?? 'N/A',
                  item.uom ?? 'N/A',
                  item.quantity?.toStringAsFixed(2) ?? '0',
                  item.uomPrice != null
                      ? '₱${item.uomPrice!.toStringAsFixed(2)}'
                      : '₱0.00',
                  item.totalAmount != null
                      ? '₱${item.totalAmount!.toStringAsFixed(2)}'
                      : '₱0.00',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          /// 🔷 SUMMARY
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(width: 1.5, color: themeColor),
              ),
            ),
            child: pw.Column(
              children: [
                _summaryRow(
                  'Total Items',
                  '${invoiceItems.length}',
                  regularFont,
                ),
                _summaryRow(
                  'Total Invoices',
                  '${invoices.length}',
                  regularFont,
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(font: boldFont, fontSize: 14),
                    ),
                    pw.Text(
                      '₱${invoiceItems.fold<double>(0.0, (sum, item) => sum + (item.totalAmount ?? 0.0)).toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 40),

          /// 🔷 SIGNATURES
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signatureBlock('Customer'),
              _signatureBlock('Delivery Personnel'),
            ],
          ),

          pw.SizedBox(height: 20),

          /// 🔷 FOOTER
          pw.Center(
            child: pw.Column(
              children: [
                pw.Divider(),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: themeColor,
                  ),
                ),
                pw.Text(
                  'Generated: ${_formatDateTime(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// 🔷 HELPERS

  static pw.Widget _infoBlock(
    String title,
    List<String> lines,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        ...lines.map((e) => pw.Text(e, style: pw.TextStyle(font: regular))),
      ],
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value,
    pw.Font font,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(value),
      ],
    );
  }

  static pw.Widget _signatureBlock(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 150,
          height: 50,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(width: 150, child: pw.Divider()),
        pw.Text(label),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour}:${dateTime.minute}';
  }
}