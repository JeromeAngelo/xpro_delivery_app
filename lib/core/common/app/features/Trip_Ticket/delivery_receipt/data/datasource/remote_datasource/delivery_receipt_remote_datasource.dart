import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


abstract class DeliveryReceiptRemoteDatasource {
  /// Get delivery receipt by trip ID
  Future<DeliveryReceiptModel> getDeliveryReceiptByTripId(String tripId);

  /// Get delivery receipt by delivery data ID
  Future<DeliveryReceiptModel> getDeliveryReceiptByDeliveryDataId(String deliveryDataId);

  /// Create delivery receipt by delivery data ID
  Future<DeliveryReceiptModel> createDeliveryReceiptByDeliveryDataId({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
    required double? amount, 
  });

  /// Delete delivery receipt by ID
  Future<bool> deleteDeliveryReceipt(String id);
}

class DeliveryReceiptRemoteDatasourceImpl implements DeliveryReceiptRemoteDatasource {
  const DeliveryReceiptRemoteDatasourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<DeliveryReceiptModel> getDeliveryReceiptByTripId(String tripId) async {
    try {
      debugPrint('🔄 Fetching delivery receipt by trip ID: $tripId');

      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Using trip ID: $actualTripId');

      final records = await _pocketBaseClient.collection('deliveryReceipt').getFullList(
        filter: 'trip = "$actualTripId"',
        expand: 'trip,deliveryData',
      );

      if (records.isEmpty) {
        throw const ServerException(
          message: 'No delivery receipt found for this trip',
          statusCode: '404',
        );
      }

      final record = records.first;
      debugPrint('✅ Retrieved delivery receipt: ${record.id}');

      final mappedData = _mapDeliveryReceiptData(record);
      return DeliveryReceiptModel.fromJson(mappedData);

    } catch (e) {
      debugPrint('❌ Error fetching delivery receipt by trip ID: $e');
      throw ServerException(
        message: 'Failed to load delivery receipt by trip ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<DeliveryReceiptModel> getDeliveryReceiptByDeliveryDataId(String deliveryDataId) async {
    try {
      debugPrint('🔄 Fetching delivery receipt by delivery data ID: $deliveryDataId');

      // Extract delivery data ID if we received a JSON object
      String actualDeliveryDataId;
      if (deliveryDataId.startsWith('{')) {
        final deliveryData = jsonDecode(deliveryDataId);
        actualDeliveryDataId = deliveryData['id'];
      } else {
        actualDeliveryDataId = deliveryDataId;
      }

      debugPrint('🎯 Using delivery data ID: $actualDeliveryDataId');

      final records = await _pocketBaseClient.collection('deliveryReceipt').getFullList(
        filter: 'deliveryData = "$actualDeliveryDataId"',
        expand: 'trip,deliveryData',
      );

      if (records.isEmpty) {
        throw const ServerException(
          message: 'No delivery receipt found for this delivery data',
          statusCode: '404',
        );
      }

      final record = records.first;
      debugPrint('✅ Retrieved delivery receipt: ${record.id}');

      final mappedData = _mapDeliveryReceiptData(record);
      return DeliveryReceiptModel.fromJson(mappedData);

    } catch (e) {
      debugPrint('❌ Error fetching delivery receipt by delivery data ID: $e');
      throw ServerException(
        message: 'Failed to load delivery receipt by delivery data ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

    @override
  Future<DeliveryReceiptModel> createDeliveryReceiptByDeliveryDataId({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
    required double? amount, 
  }) async {
    try {
      debugPrint('🔄 Creating delivery receipt for delivery data: $deliveryDataId');

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
       final tripId = await _getTripIdFromDeliveryData(actualDeliveryDataId);

          final invoiceItems = await _getInvoiceItemsFromDeliveryData(actualDeliveryDataId);

      // Prepare files for upload with compression
      final files = <MultipartFile>[];

      // Handle customer signature file - Convert to PDF
      if (customerSignature != null && customerSignature.isNotEmpty) {
        try {
          final signatureFile = File(customerSignature);
          if (await signatureFile.exists()) {
            debugPrint('📝 Processing customer signature...');
            final signaturePdfBytes = await _convertSignatureToPdf(customerSignature);
            files.add(MultipartFile.fromBytes(
              'customerSignature',
              signaturePdfBytes,
              filename: 'customer_signature_${DateTime.now().millisecondsSinceEpoch}.pdf',
            ));
            debugPrint('✅ Added customer signature as PDF (${signaturePdfBytes.length} bytes)');
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
            final receiptBytes = await _compressPdf(receiptFile);
            files.add(MultipartFile.fromBytes(
              'receiptFile',
              receiptBytes,
              filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
            ));
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
              final compressedImageBytes = await _compressImage(imagePath);
              if (compressedImageBytes != null) {
                files.add(MultipartFile.fromBytes(
                  'customerImages',
                  compressedImageBytes,
                  filename: 'customer_image_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ));
                debugPrint('✅ Added compressed customer image ${i + 1}/${customerImages.length} (${compressedImageBytes.length} bytes)');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error processing customer image $i: $e');
          }
        }
      }

      // Calculate total file size
      final totalSize = files.fold<int>(0, (sum, file) => sum + file.length);
      debugPrint('📦 Total upload size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');

          // Prepare body data - Include trip data and amount
      final body = <String, dynamic>{
        'deliveryData': actualDeliveryDataId,
        'status': status ?? 'completed',
        'dateTimeCompleted': _formatDateTime(dateTimeCompleted),
        'totalAmount': amount ?? 0.0, // ADDED: Include amount in body
        if (tripId != null) 'trip': tripId,
        if (invoiceItems.isNotEmpty) 'invoiceItems': invoiceItems,
      };


      debugPrint('📦 Creating delivery receipt with ${files.length} files');
      if (tripId != null) {
        debugPrint('🚛 Including trip data: $tripId');
      }
      debugPrint('⏱️ Starting optimized remote creation...');

      final startTime = DateTime.now();

      // Create the record with compressed files
      final record = await _pocketBaseClient.collection('deliveryReceipt').create(
        body: body,
        files: files,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('⏱️ Remote creation took: ${duration.inMilliseconds}ms');

      debugPrint('✅ Created delivery receipt: ${record.id}');

      // Update delivery data with "Mark as Received" status (run in parallel)
      _updateDeliveryDataWithReceivedStatus(actualDeliveryDataId);

      // Get the created record with expanded relations for better data
      final createdRecord = await _pocketBaseClient.collection('deliveryReceipt').getOne(
        record.id,
        expand: 'deliveryData,deliveryData.customer,deliveryData.invoice,deliveryData.trip',
      );

      final mappedData = _mapDeliveryReceiptData(createdRecord);
      return DeliveryReceiptModel.fromJson(mappedData);

    } catch (e) {
      debugPrint('❌ Error creating delivery receipt: $e');
      throw ServerException(
        message: 'Failed to create delivery receipt: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
  /// Get trip ID from delivery data
  Future<String?> _getTripIdFromDeliveryData(String deliveryDataId) async {
    try {
      debugPrint('🔍 Getting trip ID for delivery data: $deliveryDataId');
      
      final deliveryDataRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId, expand: 'trip');
      
      final tripId = deliveryDataRecord.data['trip'];
      debugPrint('🚛 Found trip ID: $tripId');
      
      return tripId;
    } catch (e) {
      debugPrint('⚠️ Error getting trip ID: $e');
      return null;
    }
  }

  /// Get invoice items from delivery data
  Future<List<String>> _getInvoiceItemsFromDeliveryData(String deliveryDataId) async {
    try {
      debugPrint('🔍 Getting invoice items for delivery data: $deliveryDataId');
      
      final deliveryDataRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId, expand: 'invoiceItems');
      
      final invoiceItems = deliveryDataRecord.data['invoiceItems'] as List?;
      final invoiceItemIds = invoiceItems?.map((item) => item.toString()).toList() ?? [];
      
      debugPrint('📦 Found ${invoiceItemIds.length} invoice items');
      
      return invoiceItemIds;
    } catch (e) {
      debugPrint('⚠️ Error getting invoice items: $e');
      return [];
    }
  }



    /// Compress image file to reduce size
  Future<Uint8List?> _compressImage(String imagePath) async {
    try {
      debugPrint('🗜️ Compressing image: $imagePath');
      
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: 70, // 70% quality
        minWidth: 800, // Max width 800px
        minHeight: 600, // Max height 600px
        format: CompressFormat.jpeg,
      );
      
      if (compressedBytes != null) {
        final originalSize = await File(imagePath).length();
        debugPrint('📊 Image compressed: ${originalSize} bytes -> ${compressedBytes.length} bytes');
        debugPrint('📉 Compression ratio: ${((originalSize - compressedBytes.length) / originalSize * 100).toStringAsFixed(1)}%');
      }
      
      return compressedBytes;
    } catch (e) {
      debugPrint('⚠️ Image compression failed: $e');
      // Fallback to original file
      return await File(imagePath).readAsBytes();
    }
  }

  /// Convert signature image to PDF
  Future<Uint8List> _convertSignatureToPdf(String signaturePath) async {
    try {
      debugPrint('📄 Converting signature to PDF: $signaturePath');
      
      // Read and compress the signature image first
      final compressedImageBytes = await _compressImage(signaturePath);
      if (compressedImageBytes == null) {
        throw Exception('Failed to process signature image');
      }
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Create image from compressed bytes
      final image = pw.MemoryImage(compressedImageBytes);
      
      // Add page with signature
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Customer Signature',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: double.infinity,
                  height: 200,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                  ),
                  child: pw.Center(
                    child: pw.Image(
                      image,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Time: ${DateTime.now().toString().split(' ')[1].substring(0, 8)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      );
      
      final pdfBytes = await pdf.save();
      debugPrint('✅ Signature converted to PDF: ${pdfBytes.length} bytes');
      
      return pdfBytes;
    } catch (e) {
      debugPrint('❌ Signature to PDF conversion failed: $e');
      // Fallback to compressed image
      return await _compressImage(signaturePath) ?? Uint8List(0);
    }
  }

  /// Compress PDF file
  Future<Uint8List> _compressPdf(String pdfPath) async {
    try {
      debugPrint('🗜️ Processing PDF file: $pdfPath');
      
      final pdfBytes = await File(pdfPath).readAsBytes();
      debugPrint('📊 PDF size: ${pdfBytes.length} bytes');
      
      // For now, just return the original PDF bytes
      // You can add PDF compression library here if needed
      return pdfBytes;
    } catch (e) {
      debugPrint('⚠️ PDF processing failed: $e');
      rethrow;
    }
  }


    /// Update delivery data with "Mark as Received" status (runs asynchronously)
  void _updateDeliveryDataWithReceivedStatus(String deliveryDataId) {
    // Run this asynchronously to not block the main creation
    Future.microtask(() async {
      try {
        debugPrint('🔄 Updating delivery data with "Mark as Received" status: $deliveryDataId');

        // Get the "Mark as Received" status from delivery_status_choices
        final receivedStatus = await _pocketBaseClient
            .collection('delivery_status_choices')
            .getFirstListItem('title = "Mark as Received"');

        debugPrint('✅ Found "Mark as Received" status: ${receivedStatus.id}');

        // Create delivery update record
        final deliveryUpdateRecord = await _pocketBaseClient
            .collection('delivery_update')
            .create(
              body: {
                'deliveryData': deliveryDataId,
                'title': receivedStatus.data['title'],
                'subtitle': receivedStatus.data['subtitle'] ?? 'Package has been received by customer',
                'time': DateTime.now().toIso8601String(),
                'created': DateTime.now().toIso8601String(),
                'updated': DateTime.now().toIso8601String(),
                'isAssigned': true,
                'assignedTo': null,
                'customer': null,
                'remarks': 'Delivery receipt created - package marked as received',
                'image': null,
              },
            );

        debugPrint('✅ Created delivery update record: ${deliveryUpdateRecord.id}');

        // Update the delivery data with the new delivery update
        await _pocketBaseClient
            .collection('deliveryData')
            .update(
              deliveryDataId,
              body: {
                'deliveryUpdates+': [deliveryUpdateRecord.id],
              },
            );

        debugPrint('✅ Updated delivery data with "Mark as Received" status');

      } catch (e) {
        debugPrint('❌ Error updating delivery data with received status: $e');
      }
    });
  }



  @override
  Future<bool> deleteDeliveryReceipt(String id) async {
    try {
      debugPrint('🔄 Deleting delivery receipt: $id');

      await _pocketBaseClient.collection('deliveryReceipt').delete(id);

      debugPrint('✅ Successfully deleted delivery receipt: $id');
      return true;

    } catch (e) {
      debugPrint('❌ Error deleting delivery receipt: $e');
      throw ServerException(
        message: 'Failed to delete delivery receipt: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  /// Helper method to map delivery receipt data from PocketBase record
  Map<String, dynamic> _mapDeliveryReceiptData(RecordModel record) {
    return {
      'id': record.id,
      'collectionId': record.collectionId,
      'collectionName': record.collectionName,
      'status': record.data['status'],
      'dateTimeCompleted': record.data['dateTimeCompleted'],
      'customerImages': record.data['customerImages'],
      'customerSignature': record.data['customerSignature'],
      'receiptFile': record.data['receiptFile'],
      'totalAmount': record.data['totalAmount'],
      'trip': record.data['trip'],
      'deliveryData': record.data['deliveryData'],
      'created': record.created,
      'updated': record.updated,
      'expand': {
        'trip': _mapExpandedData(record.expand['trip']),
        'deliveryData': _mapExpandedData(record.expand['deliveryData']),
      }
    };
  }

  /// Helper method to map expanded data
  dynamic _mapExpandedData(dynamic data) {
    if (data == null) return null;
    
    if (data is RecordModel) {
      return {
        'id': data.id,
        'collectionId': data.collectionId,
        'collectionName': data.collectionName,
        ...Map<String, dynamic>.from(data.data),
        'created': data.created,
        'updated': data.updated,
      };
    }
    
    if (data is List) {
      return data.map((item) => _mapExpandedData(item)).toList();
    }
    
    return data;
  }

  /// Safe DateTime formatting to avoid errors
  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    
    try {
      // Format to ISO 8601 string which is safe for PocketBase
      return dateTime.toUtc().toIso8601String();
    } catch (e) {
      debugPrint('⚠️ Error formatting DateTime: $e');
      // Fallback to current time if formatting fails
      return DateTime.now().toUtc().toIso8601String();
    }
  }
}
