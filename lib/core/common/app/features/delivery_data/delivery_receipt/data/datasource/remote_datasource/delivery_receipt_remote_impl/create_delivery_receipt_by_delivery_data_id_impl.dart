import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart' show RecordModel;
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/delivery_receipt_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CreateDeliveryReceiptByDeliveryDataIdImpl on DeliveryReceiptRemoteBase {
  Future<DeliveryReceiptModel> createDeliveryReceiptByDeliveryDataId({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
    required double? amount,
    required String? mop,
    String? chequeNumber,
    String? transactionNumber,
    String? bankName,
    String? refNumber,
    String? bankAccountNumber,
  }) async {
    try {
      debugPrint(
        '🔄 Creating delivery receipt for delivery data: $deliveryDataId',
      );

      // Extract delivery data ID if we received a JSON object
      String actualDeliveryDataId;
      if (deliveryDataId.startsWith('{')) {
        final deliveryData = jsonDecode(deliveryDataId);
        actualDeliveryDataId = deliveryData['id'];
      } else {
        actualDeliveryDataId = deliveryDataId;
      }

      debugPrint('🎯 Using delivery data ID: $actualDeliveryDataId');

      //store trip and invoice items to delivery receipt collection
      final tripId = await getTripIdFromDeliveryData(actualDeliveryDataId);

      final invoiceItems = await getInvoiceItemsFromDeliveryData(
        actualDeliveryDataId,
      );

      // Resolve deliveryData to extract deliveryNumber for transactionNumber
      String? deliveryNumber;
      try {
        final deliveryDataRecord = await pocketBaseClient
            .collection('deliveryData')
            .getOne(actualDeliveryDataId);
        deliveryNumber = deliveryDataRecord.data['deliveryNumber']?.toString();
      } catch (e) {
        debugPrint('⚠️ Failed to resolve deliveryNumber (non-blocking): $e');
      }

      // Auto-generate transactionNumber if not provided
      // Format: {deliveryNumberNumericPart}-{yyyymmddHHmmss}
      // e.g., DEL-35093 → 35093-20260529143022
      final effectiveTransactionNumber =
          (transactionNumber != null && transactionNumber.isNotEmpty)
              ? transactionNumber
              : _generateTransactionNumber(deliveryNumber);
      debugPrint('🔢 Transaction number: $effectiveTransactionNumber');

      // -------------------------------------------------------------
      // 1️⃣ Create Delivery Collection FIRST
      // -------------------------------------------------------------
      try {
        debugPrint(
          '📦 Creating delivery collection for: $actualDeliveryDataId',
        );

        // Resolve customer and invoice IDs from delivery data
        String? customerId;
        List<String> invoiceIds = [];

        try {
          // Expand both 'invoice' (single) and 'invoices' (multi) relations
          final deliveryDataRecord = await pocketBaseClient
              .collection('deliveryData')
              .getOne(actualDeliveryDataId, expand: 'customer,invoices');

          // Resolve customer ID
          customerId = deliveryDataRecord.data['customer']?.toString();
          debugPrint('👤 Customer ID resolved: $customerId');

          // Debug: log raw data for invoices
          debugPrint(
            '🧾 Raw invoices data type: ${deliveryDataRecord.data['invoices']?.runtimeType}',
          );
          debugPrint(
            '🧾 Raw invoices value: ${deliveryDataRecord.data['invoices']}',
          );

          // Resolve invoices from 'invoices' (multi-relation) field
          // Note: PocketBase stores multi-relation fields as comma-separated strings
          final invoicesData = deliveryDataRecord.data['invoices'];
          if (invoicesData != null) {
            if (invoicesData is List) {
              invoiceIds = invoicesData.map((item) => item.toString()).toList();
              debugPrint(
                '🧾 Resolved ${invoiceIds.length} invoices from "invoices" field (List)',
              );
            } else if (invoicesData is String) {
              // PocketBase multi-relation fields are comma-separated ID strings
              invoiceIds =
                  invoicesData
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
              debugPrint(
                '🧾 Resolved ${invoiceIds.length} invoices from "invoices" field (comma-separated String)',
              );
            }
          }

          // Also check expanded invoices for RecordModel list
          if (invoiceIds.isEmpty) {
            final dynamic expandedInvoices =
                deliveryDataRecord.expand['invoices'];
            if (expandedInvoices != null) {
              if (expandedInvoices is List) {
                invoiceIds =
                    expandedInvoices.map((e) {
                      if (e is RecordModel) return e.id;
                      return e.toString();
                    }).toList();
                debugPrint(
                  '🧾 Resolved ${invoiceIds.length} invoices from expanded "invoices"',
                );
              } else if (expandedInvoices is RecordModel) {
                invoiceIds = [(expandedInvoices).id];
                debugPrint(
                  '🧾 Resolved 1 invoice from expanded "invoices" (single RecordModel)',
                );
              }
            }
          }

          debugPrint('🧾 Final invoice IDs for collection: $invoiceIds');
        } catch (e) {
          debugPrint(
            '⚠️ Failed to resolve customer/invoice from deliveryData (non-blocking): $e',
          );
        }

        // Build collection body
        final collectionBody = <String, dynamic>{
          'deliveryData': actualDeliveryDataId,
          'invoiceStatus': 'completed',
          'completedAt': DateTime.now().toUtc().toIso8601String(),
          'status': 'completed',
          'totalAmount': (amount ?? 0.0).toString(),
          'mop': mop,
          'transactionNumber': effectiveTransactionNumber,
          'created': DateTime.now().toUtc().toIso8601String(),
          'updated': DateTime.now().toUtc().toIso8601String(),
        };

        // Add trip if available
        if (tripId != null) {
          collectionBody['trip'] = tripId;
        }

        // Add optional fields only if they have values
        if (customerId != null && customerId.isNotEmpty) {
          collectionBody['customer'] = customerId;
        }
        if (invoiceIds.isNotEmpty) {
          collectionBody['invoices'] = invoiceIds;
        }
        if (chequeNumber != null && chequeNumber.isNotEmpty) {
          collectionBody['chequeNumber'] = chequeNumber;
        }
        if (bankName != null && bankName.isNotEmpty) {
          collectionBody['bankName'] = bankName;
        }
        if (refNumber != null && refNumber.isNotEmpty) {
          collectionBody['refNumber'] = refNumber;
        }
        if (bankAccountNumber != null && bankAccountNumber.isNotEmpty) {
          collectionBody['bankAccountNumber'] = bankAccountNumber;
        }

        final deliveryCollectionRecord = await pocketBaseClient
            .collection('deliveryCollection')
            .create(body: collectionBody);

        debugPrint(
          '✅ Delivery collection created → ${deliveryCollectionRecord.id}',
        );

        // Link the collection to the trip ticket
        if (tripId != null) {
          try {
            await pocketBaseClient
                .collection('tripticket')
                .update(
                  tripId,
                  body: {
                    'deliveryCollection+': [deliveryCollectionRecord.id],
                    'updated': DateTime.now().toUtc().toIso8601String(),
                  },
                );
            debugPrint('✅ Collection linked to trip ticket: $tripId');
          } catch (e) {
            debugPrint(
              '⚠️ Failed to link collection to trip ticket (non-blocking): $e',
            );
          }
        }
      } catch (e) {
        debugPrint(
          '⚠️ Failed to create delivery collection (non-blocking): $e',
        );
        // Non-blocking: continue with receipt creation
      }

      // -------------------------------------------------------------
      // 3️⃣ Create Delivery Receipt
      // -------------------------------------------------------------
      // Prepare files for upload with compression
      final files = <MultipartFile>[];

      // Handle customer signature file - Convert to PDF
      if (customerSignature != null && customerSignature.isNotEmpty) {
        try {
          final signatureFile = File(customerSignature);
          if (await signatureFile.exists()) {
            debugPrint('📝 Processing customer signature...');
            final signaturePdfBytes = await convertSignatureToPdf(
              customerSignature,
            );
            files.add(
              MultipartFile.fromBytes(
                'customerSignature',
                signaturePdfBytes,
                filename:
                    'customer_signature_${DateTime.now().millisecondsSinceEpoch}.pdf',
              ),
            );
            debugPrint(
              '✅ Added customer signature as PDF (${signaturePdfBytes.length} bytes)',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error processing customer signature file: $e');
        }
      }

      // Handle receipt file - Compress PDF
      if (receiptFile != null && receiptFile.isNotEmpty) {
        try {
          final receipt = File(receiptFile);
          if (await receipt.exists()) {
            debugPrint('🧾 Processing receipt file...');
            final receiptBytes = await compressPdf(receiptFile);
            files.add(
              MultipartFile.fromBytes(
                'receiptFile',
                receiptBytes,
                filename:
                    'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
              ),
            );
            debugPrint('✅ Added receipt file (${receiptBytes.length} bytes)');
          }
        } catch (e) {
          debugPrint('⚠️ Error processing receipt file: $e');
        }
      }

      // Handle customer images - Compress images
      if (customerImages != null && customerImages.isNotEmpty) {
        debugPrint('📸 Processing ${customerImages.length} customer images...');

        for (int i = 0; i < customerImages.length; i++) {
          try {
            final imagePath = customerImages[i];
            final imageFile = File(imagePath);
            if (await imageFile.exists()) {
              final compressedImageBytes = await compressImageToSmallSize(
                imagePath,
              );
              if (compressedImageBytes != null) {
                files.add(
                  MultipartFile.fromBytes(
                    'customerImages',
                    compressedImageBytes,
                    filename:
                        'customer_image_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  ),
                );
                debugPrint(
                  '✅ Added compressed customer image ${i + 1}/${customerImages.length} (${compressedImageBytes.length} bytes)',
                );
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error processing customer image $i: $e');
          }
        }
      }

      // Calculate total file size
      final totalSize = files.fold<int>(0, (sum, file) => sum + file.length);
      debugPrint(
        '📦 Total upload size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Prepare body data - Include trip data and amount
      final body = <String, dynamic>{
        'deliveryData': actualDeliveryDataId,
        'status': status ?? 'completed',
        'dateTimeCompleted': formatDateTime(dateTimeCompleted),
        'totalAmount': amount ?? 0.0, // ADDED: Include amount in body
        'mop': mop,
        'transactionNumber': effectiveTransactionNumber,
        if (tripId != null) 'trip': tripId,
        if (invoiceItems.isNotEmpty) 'invoiceItems': invoiceItems,
        if (chequeNumber != null && chequeNumber.isNotEmpty)
          'chequeNumber': chequeNumber,
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
        if (refNumber != null && refNumber.isNotEmpty) 'refNumber': refNumber,
        if (bankAccountNumber != null && bankAccountNumber.isNotEmpty)
          'bankAccountNumber': bankAccountNumber,
      };

      debugPrint('📦 Creating delivery receipt with ${files.length} files');
      if (tripId != null) {
        debugPrint('🚛 Including trip data: $tripId');
      }
      debugPrint('⏱️ Starting optimized remote creation...');

      final startTime = DateTime.now();

      // Create the record with compressed files
      final record = await pocketBaseClient
          .collection('deliveryReceipt')
          .create(body: body, files: files);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('⏱️ Remote creation took: ${duration.inMilliseconds}ms');

      debugPrint('✅ Created delivery receipt: ${record.id}');

      // Get the created record with expanded relations for better data
      final createdRecord = await pocketBaseClient
          .collection('deliveryReceipt')
          .getOne(
            record.id,
            expand:
                'deliveryData,deliveryData.customer,deliveryData.invoice,deliveryData.trip',
          );

      final mappedData = mapDeliveryReceiptData(createdRecord);
      final createdReceipt = DeliveryReceiptModel.fromJson(mappedData);

      // Link the receipt to the delivery collection
      try {
        // Find the collection we created earlier for this deliveryData
        final collectionRecords = await pocketBaseClient
            .collection('deliveryCollection')
            .getFullList(filter: 'deliveryData = "$actualDeliveryDataId"');

        if (collectionRecords.isNotEmpty) {
          final collectionId = collectionRecords.first.id;
          await pocketBaseClient
              .collection('deliveryCollection')
              .update(collectionId, body: {'deliveryReceipt': record.id});
          debugPrint('✅ Receipt linked to delivery collection: $collectionId');
        }
      } catch (e) {
        debugPrint(
          '⚠️ Failed to link receipt to collection (non-blocking): $e',
        );
      }

      // -------------------------------------------------------------
      // 4️⃣ Create "Mark as Received" delivery update
      // -------------------------------------------------------------
      try {
        debugPrint(
          '📝 Creating "Mark as Received" delivery update for: $actualDeliveryDataId',
        );

        final now = DateTime.now().toUtc().toIso8601String();

        // Create the delivery update record in PocketBase
        final deliveryUpdateRecord = await pocketBaseClient
            .collection('deliveryUpdate')
            .create(
              body: {
                'deliveryData': actualDeliveryDataId,
                'title': 'Mark as Received',
                'subtitle': 'Received Delivery',
                'time': now,
                'created': now,
                'isAssigned': true,
              },
            );

        debugPrint('✅ Delivery update created → ${deliveryUpdateRecord.id}');

        // Link the delivery update to the deliveryData collection
        await pocketBaseClient
            .collection('deliveryData')
            .update(
              actualDeliveryDataId,
              body: {
                'deliveryUpdates+': [deliveryUpdateRecord.id],
              },
            );
      } catch (e) {
        debugPrint(
          '⚠️ Failed to create "Mark as Received" delivery update (non-blocking): $e',
        );
        // Non-blocking: receipt was still created successfully
      }

      return createdReceipt;
    } catch (e) {
      debugPrint('❌ Error creating delivery receipt: $e');
      throw ServerException(
        message: 'Failed to create delivery receipt: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  /// Generates a transaction number from deliveryNumber + current date/time.
  /// Format: {numericPart}-{yyyymmddHHmmss}
  /// e.g., DEL-35093 → 35093-20260529143022
  String _generateTransactionNumber(String? deliveryNumber) {
    // Extract numeric part from deliveryNumber (e.g., "DEL-35093" → "35093")
    String? numericPart;
    if (deliveryNumber != null && deliveryNumber.isNotEmpty) {
      final match = RegExp(r'\d+').firstMatch(deliveryNumber);
      if (match != null) {
        numericPart = match.group(0);
      }
    }

    // Build date/time suffix: yyyymmddHHmmss
    final now = DateTime.now();
    final dateTimeSuffix =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final txn =
        numericPart != null ? '$numericPart-$dateTimeSuffix' : dateTimeSuffix;

    debugPrint(
      '🔢 Generated transaction number: $txn (from deliveryNumber: $deliveryNumber)',
    );
    return txn;
  }
}
