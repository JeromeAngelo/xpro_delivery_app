import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';

import 'dart:typed_data';
import 'package:image/image.dart' as img;

import '../../../../../../../../enums/undeliverable_reason.dart';
import '../../../../../../../../errors/exceptions.dart';
import '../../../../trip/data/models/trip_models.dart';
import '../../../../customer_data/data/model/customer_data_model.dart';
import '../../../../delivery_data/data/model/delivery_data_model.dart';
import '../../../../invoice_data/data/model/invoice_data_model.dart';
import '../../model/cancelled_invoice_model.dart';

abstract class CancelledInvoiceRemoteDataSource {
  /// Get all cancelled invoices
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices();

  /// Load cancelled invoices by trip ID
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  );

  /// Load cancelled invoice by ID
  Future<CancelledInvoiceModel> loadCancelledInvoiceById(String id);

  /// Create cancelled invoice
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
    String deliveryDataId,
  );

  Future<bool> reassignTripForCancelledInvoice(String deliveryDataId);

  /// Delete cancelled invoice
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId);
}

class CancelledInvoiceRemoteDataSourceImpl
    implements CancelledInvoiceRemoteDataSource {
  CancelledInvoiceRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  @override
  Future<bool> reassignTripForCancelledInvoice(String deliveryDataId) async {
    try {
      debugPrint(
        '🔄 Reassigning trip for cancelled invoice with delivery data ID: $deliveryDataId',
      );

      // Step 1: Update the delivery data to remove trip assignment
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'hasTrip': false,
              'deliveryUpdates': null,
              'trip': null,
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Successfully updated delivery data: $deliveryDataId');
      debugPrint('📋 Updated delivery data fields:');
      debugPrint('   - hasTrip: false');
      debugPrint('   - trip: null');
      debugPrint('   - updated: ${DateTime.now().toUtc().toIso8601String()}');

      // Step 2: Find and update the cancelled invoice with matching deliveryData
      debugPrint(
        '🔍 Searching for cancelled invoice with deliveryData: $deliveryDataId',
      );

      final cancelledInvoiceRecords = await _pocketBaseClient
          .collection('cancelledInvoice')
          .getFullList(filter: 'deliveryData = "$deliveryDataId"');

      if (cancelledInvoiceRecords.isEmpty) {
        debugPrint(
          '⚠️ No cancelled invoice found with deliveryData: $deliveryDataId',
        );
        // Still return true as the delivery data was updated successfully
        return true;
      }

      debugPrint(
        '📋 Found ${cancelledInvoiceRecords.length} cancelled invoice(s) to update',
      );

      // Step 3: Update each found cancelled invoice
      for (var cancelledInvoiceRecord in cancelledInvoiceRecords) {
        debugPrint(
          '🔄 Updating cancelled invoice: ${cancelledInvoiceRecord.id}',
        );

        await _pocketBaseClient
            .collection('cancelledInvoice')
            .update(
              cancelledInvoiceRecord.id,
              body: {
                'reason': 'rescheduled', // Change reason to rescheduled
                'trip': null, // Remove trip reference
                'updated': DateTime.now().toUtc().toIso8601String(),
              },
            );

        debugPrint(
          '✅ Successfully updated cancelled invoice: ${cancelledInvoiceRecord.id}',
        );
        debugPrint('📋 Updated cancelled invoice fields:');
        debugPrint('   - reason: rescheduled');
        debugPrint('   - trip: null');
        debugPrint('   - updated: ${DateTime.now().toUtc().toIso8601String()}');
      }

      debugPrint(
        '🎉 Successfully completed reassignment process for delivery data: $deliveryDataId',
      );
      debugPrint('📊 Summary:');
      debugPrint('   - Delivery data updated: ✅');
      debugPrint(
        '   - Cancelled invoices updated: ${cancelledInvoiceRecords.length}',
      );
      debugPrint('   - All invoices marked as rescheduled: ✅');

      return true;
    } catch (e) {
      debugPrint(
        '❌ Failed to reassign trip for cancelled invoice: ${e.toString()}',
      );
      debugPrint('🔍 Error details:');
      debugPrint('   - Delivery Data ID: $deliveryDataId');
      debugPrint('   - Error: ${e.toString()}');

      throw ServerException(
        message:
            'Failed to reassign trip for cancelled invoice: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices() async {
    try {
      debugPrint('🔄 Fetching all cancelled invoices');

      final records = await _pocketBaseClient
          .collection('cancelledInvoice')
          .getFullList(
            expand: 'deliveryData,trip,invoice,customer',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} cancelled invoices from API');

      List<CancelledInvoiceModel> cancelledInvoices = [];

      for (var record in records) {
        cancelledInvoices.add(_processCancelledInvoiceRecord(record));
      }

      debugPrint(
        '✨ Successfully processed ${cancelledInvoices.length} cancelled invoices',
      );
      return cancelledInvoices;
    } catch (e) {
      debugPrint('❌ Failed to fetch all cancelled invoices: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load cancelled invoices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  ) async {
    try {
      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🔄 Loading cancelled invoices for trip: $actualTripId');

      final records = await _pocketBaseClient
          .collection('cancelledInvoice')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'deliveryData,trip,invoice,customer',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} cancelled invoices from API');

      List<CancelledInvoiceModel> cancelledInvoices = [];

      for (var record in records) {
        cancelledInvoices.add(_processCancelledInvoiceRecord(record));
      }

      debugPrint(
        '✨ Successfully processed ${cancelledInvoices.length} cancelled invoices',
      );
      return cancelledInvoices;
    } catch (e) {
      debugPrint(
        '❌ Failed to load cancelled invoices by trip ID: ${e.toString()}',
      );
      throw ServerException(
        message: 'Failed to load cancelled invoices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<CancelledInvoiceModel> loadCancelledInvoiceById(String id) async {
    try {
      debugPrint('🔄 Loading cancelled invoice by ID: $id');

      final record = await _pocketBaseClient
          .collection('cancelledInvoice')
          .getOne(id, expand: 'deliveryData,trip,invoice,customer');

      debugPrint('✅ Retrieved cancelled invoice from API: ${record.id}');

      return _processCancelledInvoiceRecord(record);
    } catch (e) {
      debugPrint('❌ Failed to load cancelled invoice by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load cancelled invoice by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 Creating cancelled invoice for delivery data: $deliveryDataId',
      );
      debugPrint(
        '📝 Reason: ${cancelledInvoice.reason.toString().split('.').last}',
      );

      // First, get the delivery data to extract trip, customer, and invoice information
      final deliveryDataRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId, expand: 'trip,customer,invoice');

      final tripId = deliveryDataRecord.data['trip'];
      if (tripId == null) {
        throw const ServerException(
          message: 'Trip ID not found in delivery data',
          statusCode: '404',
        );
      }

      debugPrint('🚛 Found trip ID: $tripId');

      // Extract customer ID from delivery data
      String? customerId;
      if (deliveryDataRecord.expand['customer'] != null) {
        final customerData = deliveryDataRecord.expand['customer'];
        if (customerData is List && customerData!.isNotEmpty) {
          customerId = customerData[0].id;
        }
      } else if (deliveryDataRecord.data['customer'] != null) {
        customerId = deliveryDataRecord.data['customer'].toString();
      }

      debugPrint('👤 Found customer ID: $customerId');

      // Extract invoice ID from delivery data
      String? invoiceId;
      if (deliveryDataRecord.expand['invoice'] != null) {
        final invoiceData = deliveryDataRecord.expand['invoice'];
        if (invoiceData is List && invoiceData!.isNotEmpty) {
          invoiceId = invoiceData[0].id;
        }
      } else if (deliveryDataRecord.data['invoice'] != null) {
        invoiceId = deliveryDataRecord.data['invoice'].toString();
      }

      debugPrint('📄 Found invoice ID: $invoiceId');

      // Prepare the body data with customer and invoice fields
      final body = {
        'deliveryData': deliveryDataId,
        'trip': tripId,
        'reason': cancelledInvoice.reason.toString().split('.').last,
        'created': DateTime.now().toUtc().toIso8601String(),
        'updated': DateTime.now().toUtc().toIso8601String(),
      };

      // Add customer field if found
      if (customerId != null && customerId.isNotEmpty) {
        body['customer'] = customerId;
        debugPrint('✅ Added customer to cancelled invoice: $customerId');
      } else {
        debugPrint('⚠️ No customer found in delivery data');
      }

      // Add invoice field if found
      if (invoiceId != null && invoiceId.isNotEmpty) {
        body['invoice'] = invoiceId;
        debugPrint('✅ Added invoice to cancelled invoice: $invoiceId');
      } else {
        debugPrint('⚠️ No invoice found in delivery data');
      }

      debugPrint('📋 Cancelled invoice body data: $body');

      // Prepare optimized files if image is provided
      final files = <MultipartFile>[];
      if (cancelledInvoice.image != null &&
          cancelledInvoice.image!.isNotEmpty) {
        debugPrint('📷 Optimizing and adding image to cancelled invoice');

        try {
          // Read and compress the image
          final originalFile = File(cancelledInvoice.image!);
          final originalBytes = await originalFile.readAsBytes();

          debugPrint(
            '📊 Original image size: ${(originalBytes.length / 1024).toStringAsFixed(2)} KB',
          );

          // Compress image if it's larger than 500KB
          Uint8List compressedBytes = originalBytes;
          if (originalBytes.length > 500 * 1024) {
            debugPrint('🗜️ Compressing image for faster upload');

            // Decode and resize image
            final image = img.decodeImage(originalBytes);
            if (image != null) {
              // Resize to max 1024px width while maintaining aspect ratio
              final resized = img.copyResize(
                image,
                width: image.width > 1024 ? 1024 : image.width,
                interpolation: img.Interpolation.linear,
              );

              // Compress as JPEG with 70% quality
              compressedBytes = Uint8List.fromList(
                img.encodeJpg(resized, quality: 70),
              );

              debugPrint(
                '📊 Compressed image size: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB',
              );
              debugPrint(
                '📉 Size reduction: ${((1 - compressedBytes.length / originalBytes.length) * 100).toStringAsFixed(1)}%',
              );
            }
          }

          files.add(
            MultipartFile.fromBytes(
              'image',
              compressedBytes,
              filename:
                  'cancelled_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );

          debugPrint('✅ Image prepared for upload');
        } catch (imageError) {
          debugPrint(
            '⚠️ Image processing failed, uploading original: $imageError',
          );
          // Fallback to original file if compression fails
          final imageBytes = await File(cancelledInvoice.image!).readAsBytes();
          files.add(
            MultipartFile.fromBytes(
              'image',
              imageBytes,
              filename:
                  'cancelled_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        }
      }

      debugPrint('🚀 Starting upload to PocketBase...');
      final startTime = DateTime.now();

      // Create the cancelled invoice record
      final record =
          files.isNotEmpty
              ? await _pocketBaseClient
                  .collection('cancelledInvoice')
                  .create(body: body, files: files)
              : await _pocketBaseClient
                  .collection('cancelledInvoice')
                  .create(body: body);

      final uploadTime = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('⚡ Upload completed in ${uploadTime}ms');
      debugPrint('✅ Created cancelled invoice: ${record.id}');

      // Verify the created record has the customer and invoice fields
      debugPrint('🔍 Verifying created record data:');
      debugPrint('   - Delivery Data: ${record.data['deliveryData']}');
      debugPrint('   - Trip: ${record.data['trip']}');
      debugPrint('   - Customer: ${record.data['customer']}');
      debugPrint('   - Invoice: ${record.data['invoice']}');
      debugPrint('   - Reason: ${record.data['reason']}');

      // Update delivery team stats
      await _updateDeliveryTeamStats(tripId);

      // Fetch the created record with expanded relations including customer and invoice
      final createdRecord = await _pocketBaseClient
          .collection('cancelledInvoice')
          .getOne(record.id, expand: 'deliveryData,trip,invoice,customer');

      debugPrint('🔍 Expanded record verification:');
      debugPrint(
        '   - Has deliveryData expand: ${createdRecord.expand['deliveryData'] != null}',
      );
      debugPrint(
        '   - Has trip expand: ${createdRecord.expand['trip'] != null}',
      );
      debugPrint(
        '   - Has customer expand: ${createdRecord.expand['customer'] != null}',
      );
      debugPrint(
        '   - Has invoice expand: ${createdRecord.expand['invoice'] != null}',
      );

      final cancelledInvoiceModel = _processCancelledInvoiceRecord(
        createdRecord,
      );

      debugPrint(
        '✨ Successfully created cancelled invoice with customer and invoice relations',
      );
      debugPrint('📊 Final model verification:');
      debugPrint('   - Model ID: ${cancelledInvoiceModel.id}');
      debugPrint(
        '   - Has Customer: ${cancelledInvoiceModel.customer != null}',
      );
      debugPrint(
        '   - Customer Name: ${cancelledInvoiceModel.customer!.name ?? "null"}',
      );
      debugPrint('   - Has Invoice: ${cancelledInvoiceModel.invoice != null}');
      debugPrint(
        '   - Invoice ID: ${cancelledInvoiceModel.invoice!.id ?? "null"}',
      );
      debugPrint(
        '   - Has Delivery Data: ${cancelledInvoiceModel.deliveryData != null}',
      );

      return cancelledInvoiceModel;
    } catch (e) {
      debugPrint('❌ Failed to create cancelled invoice: ${e.toString()}');
      throw ServerException(
        message: 'Failed to create cancelled invoice: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId) async {
    try {
      debugPrint('🔄 Deleting cancelled invoice: $cancelledInvoiceId');

      await _pocketBaseClient
          .collection('cancelledInvoice')
          .delete(cancelledInvoiceId);

      debugPrint('✅ Successfully deleted cancelled invoice');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete cancelled invoice: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete cancelled invoice: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // Helper method to process a cancelled invoice record - matching delivery_data pattern
  CancelledInvoiceModel _processCancelledInvoiceRecord(RecordModel record) {
    debugPrint('🔄 Processing cancelled invoice record: ${record.id}');
    debugPrint('📋 Raw record data: ${record.data}');
    debugPrint('📋 Record expand keys: ${record.expand.keys.toList()}');

    // Process delivery data
    DeliveryDataModel? deliveryDataModel;
    if (record.expand['deliveryData'] != null) {
      final deliveryDataData = record.expand['deliveryData'];
      if (deliveryDataData is List && deliveryDataData!.isNotEmpty) {
        final deliveryDataRecord = deliveryDataData[0];
        deliveryDataModel = DeliveryDataModel.fromJson({
          'id': deliveryDataRecord.id,
          'collectionId': deliveryDataRecord.collectionId,
          'collectionName': deliveryDataRecord.collectionName,
          ...deliveryDataRecord.data,
        });
        debugPrint('✅ Processed delivery data: ${deliveryDataModel.id}');
      }
    } else if (record.data['deliveryData'] != null) {
      deliveryDataModel = DeliveryDataModel(
        id: record.data['deliveryData'].toString(),
      );
      debugPrint(
        '📋 Using delivery data ID reference: ${deliveryDataModel.id}',
      );
    }

    // Process trip data
    TripModel? tripModel;
    if (record.expand['trip'] != null) {
      final tripData = record.expand['trip'];
      if (tripData is List && tripData!.isNotEmpty) {
        final tripRecord = tripData[0];
        tripModel = TripModel.fromJson({
          'id': tripRecord.id,
          'collectionId': tripRecord.collectionId,
          'collectionName': tripRecord.collectionName,
          'tripNumberId': tripRecord.data['tripNumberId'],
          'qrCode': tripRecord.data['qrCode'],
          'isAccepted': tripRecord.data['isAccepted'],
          'isEndTrip': tripRecord.data['isEndTrip'],
        });
        debugPrint(
          '✅ Processed trip: ${tripModel.id} - ${tripModel.tripNumberId}',
        );
      }
    } else if (record.data['trip'] != null) {
      tripModel = TripModel(id: record.data['trip'].toString());
      debugPrint('📋 Using trip ID reference: ${tripModel.id}');
    }

    // Process invoice data
    InvoiceDataModel? invoiceModel;
    if (record.expand['invoice'] != null) {
      final invoiceData = record.expand['invoice'];
      if (invoiceData is List && invoiceData!.isNotEmpty) {
        final invoiceRecord = invoiceData[0];
        invoiceModel = InvoiceDataModel.fromJson({
          'id': invoiceRecord.id,
          'collectionId': invoiceRecord.collectionId,
          'collectionName': invoiceRecord.collectionName,
          ...invoiceRecord.data,
        });
        debugPrint(
          '✅ Processed invoice: ${invoiceModel.id} - Amount: ${invoiceModel.totalAmount}',
        );
      }
    } else if (record.data['invoice'] != null) {
      invoiceModel = InvoiceDataModel(id: record.data['invoice'].toString());
      debugPrint('📋 Using invoice ID reference: ${invoiceModel.id}');
    }

    // Process customer data
    CustomerDataModel? customerModel;
    if (record.expand['customer'] != null) {
      final customerData = record.expand['customer'];
      if (customerData is List && customerData!.isNotEmpty) {
        final customerRecord = customerData[0];
        customerModel = CustomerDataModel.fromJson({
          'id': customerRecord.id,
          'collectionId': customerRecord.collectionId,
          'collectionName': customerRecord.collectionName,
          ...customerRecord.data,
        });
        debugPrint(
          '✅ Processed customer: ${customerModel.id} - ${customerModel.name}',
        );
      }
    } else if (record.data['customer'] != null) {
      customerModel = CustomerDataModel(id: record.data['customer'].toString());
      debugPrint('📋 Using customer ID reference: ${customerModel.id}');
    }

    // Parse dates safely
    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        debugPrint('⚠️ Failed to parse date: $dateString');
        return null;
      }
    }

    // Parse reason enum safely
    UndeliverableReason? parseReason(String? reasonString) {
      if (reasonString == null || reasonString.isEmpty) return null;
      try {
        return UndeliverableReason.values.firstWhere(
          (reason) => reason.toString().split('.').last == reasonString,
          orElse: () => UndeliverableReason.none,
        );
      } catch (e) {
        debugPrint(
          '⚠️ Failed to parse reason: $reasonString, defaulting to other',
        );
        return UndeliverableReason.none;
      }
    }

   // Process image URL
String? imageUrl;
if (record.data['image'] != null && record.data['image'].toString().isNotEmpty) {
  final baseUrl = _pocketBaseClient.baseUrl;
  final collectionName = record.collectionName;
  final recordId = record.id;

  // 🧹 Clean filename (remove any brackets)
  final rawFilename = record.data['image'].toString();
  final filename = rawFilename.replaceAll(RegExp(r'[\[\]]'), '');

  imageUrl = '$baseUrl/api/files/$collectionName/$recordId/$filename';
  debugPrint('📷 Fixed image URL: $imageUrl');
}


    final cancelledInvoice = CancelledInvoiceModel(
      id: record.id,
      collectionId: record.collectionId,
      collectionName: record.collectionName,
      reason: parseReason(record.data['reason']) ?? UndeliverableReason.none,
      image: imageUrl,
      deliveryData: deliveryDataModel,
      trip: tripModel,
      invoice: invoiceModel,
      customer: customerModel,
      created: parseDate(record.created),
      updated: parseDate(record.updated),
    );

    debugPrint(
      '✅ Successfully processed cancelled invoice: ${cancelledInvoice.id}',
    );
    debugPrint('📊 Cancelled Invoice summary:');
    debugPrint('   - ID: ${cancelledInvoice.id}');
    debugPrint(
      '   - Reason: ${cancelledInvoice.reason.toString().split('.').last}',
    );
    debugPrint('   - Has Image: ${cancelledInvoice.image != null}');
    debugPrint('   - Customer: ${cancelledInvoice.customer!.name ?? "null"}');
    debugPrint('   - Invoice: ${cancelledInvoice.invoice!.id ?? "null"}');
    debugPrint('   - Trip: ${cancelledInvoice.trip!.tripNumberId ?? "null"}');
    debugPrint(
      '   - Delivery Data: ${cancelledInvoice.deliveryData!.id ?? "null"}',
    );

    return cancelledInvoice;
  }

  // Helper method to update delivery team stats
  Future<void> _updateDeliveryTeamStats(String tripId) async {
    try {
      debugPrint('📊 Updating delivery team stats for trip: $tripId');

      // Get delivery team for this trip
      final deliveryTeamRecords = await _pocketBaseClient
          .collection('deliveryTeam')
          .getFullList(filter: 'tripTicket = "$tripId"');

      if (deliveryTeamRecords.isEmpty) {
        debugPrint('⚠️ No delivery team found for trip: $tripId');
        return;
      }

      final deliveryTeam = deliveryTeamRecords.first;
      debugPrint('🚛 Found delivery team: ${deliveryTeam.id}');

      // Get current stats
      int currentUndelivered = deliveryTeam.data['undeliveredCustomers'] ?? 0;
      int newUndelivered = currentUndelivered + 1;

      // Update delivery team with new undelivered count
      await _pocketBaseClient
          .collection('deliveryTeam')
          .update(
            deliveryTeam.id,
            body: {
              'undeliveredCustomers': newUndelivered,
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Updated delivery team stats:');
      debugPrint('   - Previous undelivered: $currentUndelivered');
      debugPrint('   - New undelivered: $newUndelivered');
    } catch (e) {
      debugPrint('⚠️ Failed to update delivery team stats: ${e.toString()}');
      // Don't throw error as this is not critical for the main operation
    }
  }

  // // Helper method to get image file extension
  // String _getImageExtension(String imagePath) {
  //   final extension = imagePath.split('.').last.toLowerCase();
  //   switch (extension) {
  //     case 'jpg':
  //     case 'jpeg':
  //       return 'jpg';
  //     case 'png':
  //       return 'png';
  //     case 'webp':
  //       return 'webp';
  //     default:
  //       return 'jpg'; // Default to jpg
  //   }
  // }

  // // Helper method to validate image file
  // bool _isValidImageFile(String imagePath) {
  //   final validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  //   final extension = imagePath.split('.').last.toLowerCase();
  //   return validExtensions.contains(extension);
  // }
}
