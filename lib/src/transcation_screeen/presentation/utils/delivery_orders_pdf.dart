// ignore_for_file: depend_on_referenced_packages

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/entity/product_entity.dart';

class DeliveryOrdersPDF {
  static Future<Uint8List> generatePDF({
    required CustomerEntity customer,
    required List<InvoiceEntity> invoices,
    required List<ProductEntity> products,
    required PdfColor themeColor,
  }) async {
    debugPrint('🚀 Starting PDF generation process');
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

      debugPrint('📄 Creating document pages');
      for (var invoice in invoices) {
        debugPrint('📝 Processing invoice: ${invoice.invoiceNumber}');

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            header:
                (context) => pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Delivery Order Summary', style: headerStyle),
                ),
            build:
                (context) => [
                  // Customer Information
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      //   border: pw.Border.all(color: themeColor),
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
                          'Store Name: ${customer.storeName}',
                          style: contentStyle,
                        ),
                        pw.Text(
                          'Owner: ${customer.ownerName}',
                          style: contentStyle,
                        ),
                        pw.Text(
                          'Address: ${customer.address}',
                          style: contentStyle,
                        ),
                        pw.Text(
                          'Contact: ${customer.contactNumber}',
                          style: contentStyle,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Invoice Details
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      //   border: pw.Border.all(color: themeColor),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice Information', style: subHeaderStyle),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Invoice Number: ${invoice.invoiceNumber}',
                          style: contentStyle,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Products Table
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
                    headers: ['Product', 'Quantity', 'Unit Price', 'Total'],
                    data:
                        invoice.productList
                            .map(
                              (product) => [
                                product.name,
                                '${product.case_} cases, ${product.totalAmount} pcs',
                                'P${product.pricePerCase}/case, P${product.pricePerPc}/pc',
                                'P${product.totalAmount}',
                              ],
                            )
                            .toList(),
                  ),
                  pw.SizedBox(height: 20),

                  // Total Amount
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Total Amount: P${customer.totalAmount}',
                                style: totalStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 40),

                  // Signatures
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(width: 150, child: pw.Divider()),
                          pw.Text('Customer Signature', style: contentStyle),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(width: 150, child: pw.Divider()),
                          pw.Text(
                            'Delivery Personnel Signature',
                            style: contentStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
          ),
        );
        debugPrint('✅ Page added for invoice: ${invoice.invoiceNumber}');
      }

      debugPrint('💾 Saving PDF document');
      final bytes = await pdf.save();
      debugPrint('✅ PDF generation completed successfully');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error generating PDF: $e');
      rethrow;
    }
  }
}
