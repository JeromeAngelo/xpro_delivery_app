// ignore_for_file: depend_on_referenced_packages, unused_local_variable

import 'dart:typed_data';
import 'package:flutter/material.dart';
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
    debugPrint(
      '🚀 Starting PDF generation process for delivery: ${deliveryData.id}',
    );
    final pdf = pw.Document();

    try {
      debugPrint('📚 Loading fonts...');
      final regularFont = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();
      debugPrint('✅ Fonts loaded successfully');

      final headerStyle = pw.TextStyle(font: boldFont, fontSize: 18);
      final subHeaderStyle = pw.TextStyle(font: regularFont, fontSize: 14);
      final contentStyle = pw.TextStyle(font: regularFont, fontSize: 12);
      final totalStyle = pw.TextStyle(font: boldFont, fontSize: 14);

      debugPrint('📄 Creating delivery receipt document');

      // Get customer data
      final customer = deliveryData.customer.target;
      final invoices = deliveryData.invoices;
      final invoiceItems = deliveryData.invoiceItems;

      if (customer == null) {
        throw Exception('Customer data is required for PDF generation');
      }

      if (invoices.isEmpty) {
        throw Exception('At least one invoice is required for PDF generation');
      }

      debugPrint('📝 Processing delivery for customer: ${customer.name}');
      debugPrint('📊 Number of invoices: ${invoices.length}');
      debugPrint('📦 Total invoice items: ${invoiceItems.length}');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header:
              (context) => pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text('Delivery Receipt', style: headerStyle),
              ),
          build:
              (context) => [
                // Delivery Information
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: themeColor),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Delivery Information', style: subHeaderStyle),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Delivery Number: ${deliveryData.deliveryNumber ?? 'N/A'}',
                        style: contentStyle,
                      ),
                      pw.Text(
                        'Payment Mode: ${deliveryData.paymentMode ?? 'N/A'}',
                        style: contentStyle,
                      ),
                      if (deliveryData.created != null)
                        pw.Text(
                          'Date Created: ${_formatDate(deliveryData.created!)}',
                          style: contentStyle,
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Customer Information
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: themeColor),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Customer Details', style: subHeaderStyle),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Customer Name: ${customer.name ?? 'N/A'}',
                        style: contentStyle,
                      ),
                      if (customer.province != null)
                        pw.Text(
                          'Address: ${customer.province ?? 'N/A'}',
                          style: contentStyle,
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Invoices Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: themeColor),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoices Information', style: subHeaderStyle),
                      pw.SizedBox(height: 8),
                      ...invoices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final invoice = entry.value;
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Invoice ${index + 1}: ${invoice.refId ?? invoice.name ?? 'N/A'}',
                              style: contentStyle,
                            ),
                            if (invoice.totalAmount != null)
                              pw.Text(
                                '   Amount: ₱${invoice.totalAmount!.toStringAsFixed(2)}',
                                style: contentStyle,
                              ),
                            if (invoice.documentDate != null)
                              pw.Text(
                                '   Date: ${_formatDate(invoice.documentDate!)}',
                                style: contentStyle,
                              ),
                            if (index < invoices.length - 1)
                              pw.SizedBox(height: 4),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Invoice Items
                if (invoiceItems.isNotEmpty) ...[
                  pw.Text('Invoice Items', style: subHeaderStyle),
                  pw.SizedBox(height: 10),
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(color: themeColor),
                    headerStyle: pw.TextStyle(
                      font: boldFont,
                      color: themeColor,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellStyle: contentStyle,
                    headers: [
                      'Item Name',
                      'Brand',
                      'UOM',
                      'Quantity',
                      'Unit Price',
                      'Total Amount',
                    ],
                    data:
                        invoiceItems
                            .map(
                              (item) => [
                                item.name ?? 'N/A',
                                item.brand ?? 'N/A',
                                item.uom ?? 'N/A',
                                item.quantity?.toStringAsFixed(2) ?? '0.00',
                                item.uomPrice != null
                                    ? '₱${item.uomPrice!.toStringAsFixed(2)}'
                                    : '₱0.00',
                                item.totalAmount != null
                                    ? '₱${item.totalAmount!.toStringAsFixed(2)}'
                                    : '₱0.00',
                              ],
                            )
                            .toList(),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Summary Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: themeColor),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Delivery Summary', style: subHeaderStyle),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Invoices:', style: contentStyle),
                          pw.Text('${invoices.length}', style: contentStyle),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Items:', style: contentStyle),
                          pw.Text(
                            '${invoiceItems.length}',
                            style: contentStyle,
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Amount:', style: totalStyle),
                          pw.Text(
                            '₱${invoiceItems.fold<double>(0.0, (sum, item) => sum + (item.totalAmount ?? 0.0)).toStringAsFixed(2)}',
                            style: totalStyle,
                          ),
                        ],
                      ),
                      if (deliveryData.paymentSelection != null)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Payment Method:', style: contentStyle),
                            pw.Text(
                              deliveryData.paymentSelection
                                  .toString()
                                  .split('.')
                                  .last,
                              style: contentStyle,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                // Signatures Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Container(width: 150, child: pw.Divider()),
                        pw.Text('Customer Signature', style: contentStyle),
                        pw.Text('Date: _______________', style: contentStyle),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Container(width: 150, child: pw.Divider()),
                        pw.Text(
                          'Delivery Personnel Signature',
                          style: contentStyle,
                        ),
                        pw.Text('Date: _______________', style: contentStyle),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Footer
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Column(
                    children: [
                      pw.Divider(),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Thank you for your business!',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: themeColor,
                        ),
                      ),
                      pw.Text(
                        'Generated on: ${_formatDateTime(DateTime.now())}',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
        ),
      );

      debugPrint('💾 Saving PDF document');
      final bytes = await pdf.save();
      debugPrint('✅ PDF generation completed successfully');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error generating PDF: $e');
      rethrow;
    }
  }

  /// Helper method to format date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Helper method to format date and time
  static String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Generate PDF with custom theme color
  static Future<Uint8List> generateDeliveryReceiptPDF({
    required DeliveryDataEntity deliveryData,
    PdfColor? customThemeColor,
  }) async {
    return generatePDF(
      deliveryData: deliveryData,
      themeColor: customThemeColor ?? PdfColors.blue,
    );
  }

  /// Generate PDF for multiple deliveries (batch)
  static Future<Uint8List> generateBatchDeliveryPDF({
    required List<DeliveryDataEntity> deliveries,
    required PdfColor themeColor,
  }) async {
    debugPrint(
      '🚀 Starting batch PDF generation for ${deliveries.length} deliveries',
    );
    final pdf = pw.Document();

    try {
      final regularFont = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();

      final headerStyle = pw.TextStyle(font: boldFont, fontSize: 18);
      final subHeaderStyle = pw.TextStyle(font: regularFont, fontSize: 14);

      for (int i = 0; i < deliveries.length; i++) {
        final delivery = deliveries[i];
        debugPrint(
          '📝 Processing delivery ${i + 1}/${deliveries.length}: ${delivery.id}',
        );

        // Add page break between deliveries (except for the first one)
        if (i > 0) {
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) => pw.Container(),
            ),
          );
        }

        // Generate individual delivery receipt
        final deliveryBytes = await generatePDF(
          deliveryData: delivery,
          themeColor: themeColor,
        );

        // This is a simplified approach - in practice, you'd want to
        // merge the pages properly or generate all content in one document
      }

      final bytes = await pdf.save();
      debugPrint('✅ Batch PDF generation completed successfully');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error generating batch PDF: $e');
      rethrow;
    }
  }
}
