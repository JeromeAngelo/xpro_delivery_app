import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/cancelled_invoice_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../../enums/undeliverable_reason.dart';

mixin CreateCancelledInvoiceImpl on CancelledInvoiceRemoteBase {
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
    String deliveryDataId,
  ) async {
    try {
      // --------------------------------------------------
      // 🛑 HARD VALIDATION (STOP BAD RETRIES)
      // --------------------------------------------------
      if (deliveryDataId.trim().isEmpty) {
        throw const ServerException(
          message: 'Missing deliveryDataId for cancelled invoice',
          statusCode: '400',
        );
      }

      final safeReason =
          cancelledInvoice.reason?.toString().isNotEmpty == true
              ? cancelledInvoice.reason!
              : UndeliverableReason.storeClosed.name;

      debugPrint('🔄 Syncing CancelledInvoice');
      debugPrint('   📦 deliveryDataId: $deliveryDataId');
      debugPrint('   📝 reason: $safeReason');

      // --------------------------------------------------
      // 1️⃣ Fetch DeliveryData (single source of truth)
      // --------------------------------------------------
      final deliveryDataRecord = await pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand:
                'trip,customer,invoice,invoices,invoices.products,invoices.customer',
          );

      final tripId = deliveryDataRecord.data['trip'];
      if (tripId == null || tripId.toString().isEmpty) {
        throw const ServerException(
          message: 'Trip ID missing in deliveryData',
          statusCode: '400',
        );
      }

      // --------------------------------------------------
      // 2️⃣ Extract Customer
      // --------------------------------------------------
      String? customerId;
      final customerExpand = deliveryDataRecord.expand['customer'];
      if (customerExpand is List && customerExpand!.isNotEmpty) {
        customerId = customerExpand.first.id;
      } else if (deliveryDataRecord.data['customer'] != null) {
        customerId = deliveryDataRecord.data['customer'].toString();
      }

      // --------------------------------------------------
      // 3️⃣ Extract Invoices
      // --------------------------------------------------
      final List<String> invoiceIds = [];

      final invoicesExpand = deliveryDataRecord.expand['invoices'];
      if (invoicesExpand is List) {
        invoiceIds.addAll(invoicesExpand!.map((e) => e.id).whereType<String>());
      }

      if (deliveryDataRecord.data['invoice'] != null) {
        final singleInvoiceId = deliveryDataRecord.data['invoice'].toString();
        if (!invoiceIds.contains(singleInvoiceId)) {
          invoiceIds.add(singleInvoiceId);
        }
      }

      // --------------------------------------------------
      // 4️⃣ Build BODY (PB SAFE)
      // --------------------------------------------------
      final body = <String, dynamic>{
        'deliveryData': deliveryDataId,
        'trip': tripId,
        'reason': safeReason,
        'created': DateTime.now().toUtc().toIso8601String(),
        'updated': DateTime.now().toUtc().toIso8601String(),
      };

      if (customerId?.isNotEmpty == true) {
        body['customer'] = customerId;
      }

      if (invoiceIds.isNotEmpty) {
        body['invoices'] = invoiceIds;
        body['invoice'] = invoiceIds.first; // backward compat
      }

      debugPrint('📋 CancelledInvoice BODY → $body');

      // --------------------------------------------------
      // 5️⃣ FILE UPLOAD (SAFE)
      // --------------------------------------------------
      final files = <MultipartFile>[];

      final imagePath = cancelledInvoice.image;
      if (imagePath != null && imagePath.trim().isNotEmpty) {
        try {
          final bytes = await compressImage(imagePath);
          if (bytes != null && bytes.isNotEmpty) {
            files.add(
              MultipartFile.fromBytes(
                'image',
                bytes,
                filename:
                    'cancelled_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            );
          }
        } catch (e) {
          debugPrint('⚠️ Image compression failed → $e');
        }
      }

      // --------------------------------------------------
      // 6️⃣ CREATE RECORD
      // --------------------------------------------------
      final record =
          files.isNotEmpty
              ? await pocketBaseClient
                  .collection('cancelledInvoice')
                  .create(body: body, files: files)
              : await pocketBaseClient
                  .collection('cancelledInvoice')
                  .create(body: body);

      debugPrint('✅ CancelledInvoice created → ${record.id}');

      // --------------------------------------------------
      // 7️⃣ LINK TO TRIPTICKET (SAFE)
      // --------------------------------------------------
      try {
        final tripTicket = await pocketBaseClient
            .collection('tripticket')
            .getOne(tripId);

        final existing =
            (tripTicket.data['cancelledInvoice'] as List?)?.cast<String>() ??
            [];

        if (!existing.contains(record.id)) {
          existing.add(record.id);

          await pocketBaseClient
              .collection('tripticket')
              .update(
                tripId,
                body: {
                  'cancelledInvoice': existing,
                  'updated': DateTime.now().toUtc().toIso8601String(),
                },
              );
        }
      } catch (e) {
        debugPrint('⚠️ Failed linking to tripticket → $e');
      }
      await updateDeliveryTeamStats(tripId);
      // --------------------------------------------------
      // 8️⃣ UPDATE DELIVERYDATA STATUS
      // --------------------------------------------------
      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'invoiceStatus': 'cancelled',
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      // --------------------------------------------------
      // 9️⃣ RETURN FULL MODEL
      // --------------------------------------------------
      final createdRecord = await pocketBaseClient
          .collection('cancelledInvoice')
          .getOne(record.id, expand: 'deliveryData,trip,invoice,customer');

      return processCancelledInvoiceRecord(createdRecord);
    } catch (e, st) {
      debugPrint('❌ createCancelledInvoice FAILED');
      debugPrint('$e');
      debugPrint('$st');

      throw ServerException(
        message: 'Failed to create cancelled invoice: $e',
        statusCode: '500',
      );
    }
  }
}
