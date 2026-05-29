import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:pdf/pdf.dart';
import '../../../../../../../../../../src/transaction_screen/presentation/utils/confirmation_payment_widgets/delivery_orders_pdf.dart';

mixin GenerateDeliveryReceiptPdfImpl on DeliveryReceiptLocalBase {
  Future<Uint8List> generateDeliveryReceiptPdf(
    DeliveryDataEntity deliveryData,
  ) async {
    try {
      debugPrint(
        '📄 LOCAL: Generating delivery receipt PDF for: ${deliveryData.id}',
      );
      debugPrint('📄 LOCAL: Customer: ${deliveryData.customer.target?.name}');
      debugPrint('📄 LOCAL: Invoice: ${deliveryData.invoice.target?.refId}');

      final pdfBytes = await DeliveryOrdersPDF.generatePDF(
        deliveryData: deliveryData,
        themeColor: PdfColor.fromHex('#2196F3'), // Default blue theme
      );

      debugPrint('✅ LOCAL: Delivery receipt PDF generated successfully');
      debugPrint('📊 LOCAL: PDF size: ${pdfBytes.length} bytes');

      return pdfBytes;
    } catch (e) {
      debugPrint('❌ LOCAL: PDF generation failed: ${e.toString()}');
      throw CacheException(
        message: 'Failed to generate delivery receipt PDF: ${e.toString()}',
      );
    }
  }
}
