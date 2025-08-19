import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'dart:typed_data';

import '../../../../../../../../enums/undeliverable_reason.dart';

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

  /// Delete cancelled invoice
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId);
}

class CancelledInvoiceRemoteDataSourceImpl
    implements CancelledInvoiceRemoteDataSource {
  CancelledInvoiceRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices() async {
    try {
      debugPrint('🔄 Fetching all cancelled invoices');

      final records = await _pocketBaseClient
          .collection('cancelledInvoice')
          .getFullList(
            expand: 'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer',
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

      // If actualTripId looks like a tripNumberId (starts with TRIP-), 
      // we need to find the actual PocketBase record ID
      String pocketBaseTripId = actualTripId;
      
      if (actualTripId.startsWith('TRIP-')) {
        debugPrint('🔍 Trip ID appears to be tripNumberId, finding PocketBase record ID...');
        try {
          final tripResults = await _pocketBaseClient.collection('tripticket').getFullList(
            filter: 'tripNumberId = "$actualTripId"',
          );
          
          if (tripResults.isNotEmpty) {
            pocketBaseTripId = tripResults.first.id;
            debugPrint('✅ Found PocketBase trip ID: $pocketBaseTripId for tripNumberId: $actualTripId');
          } else {
            debugPrint('⚠️ No trip found with tripNumberId: $actualTripId');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to resolve tripNumberId: $e');
        }
      }

      final records = await _pocketBaseClient
          .collection('cancelledInvoice')
          .getFullList(
            filter: 'trip = "$pocketBaseTripId"',
            expand: 'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer',
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
          .getOne(id, expand: 'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer');

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

      // First, get the delivery data to extract trip, customer, and invoices information
      final deliveryDataRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId, expand: 'trip,customer,invoice,invoices,invoices.products,invoices.customer');

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

      // Extract invoices IDs from delivery data
      List<String> invoiceIds = [];
      if (deliveryDataRecord.expand['invoices'] != null) {
        final invoicesData = deliveryDataRecord.expand['invoices'];
        if (invoicesData is List) {
          invoiceIds = invoicesData!.map((invoice) => invoice.id).toList();
        }
      } else if (deliveryDataRecord.data['invoices'] != null && deliveryDataRecord.data['invoices'] is List) {
        invoiceIds = (deliveryDataRecord.data['invoices'] as List)
            .map((id) => id.toString())
            .toList();
      }

      // Also include single invoice if present (for backward compatibility)
      if (deliveryDataRecord.expand['invoice'] != null) {
        final invoiceData = deliveryDataRecord.expand['invoice'];
        if (invoiceData is List && invoiceData!.isNotEmpty) {
          final singleInvoiceId = invoiceData[0].id;
          if (!invoiceIds.contains(singleInvoiceId)) {
            invoiceIds.add(singleInvoiceId);
          }
        }
      } else if (deliveryDataRecord.data['invoice'] != null) {
        final singleInvoiceId = deliveryDataRecord.data['invoice'].toString();
        if (!invoiceIds.contains(singleInvoiceId)) {
          invoiceIds.add(singleInvoiceId);
        }
      }

      debugPrint('📄 Found invoice IDs: $invoiceIds');

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

      // Add invoices field if found
      if (invoiceIds.isNotEmpty) {
        body['invoices'] = invoiceIds;
        debugPrint('✅ Added invoices to cancelled invoice: $invoiceIds');
        
        // Also add the first invoice as single invoice for backward compatibility
        body['invoice'] = invoiceIds.first;
        debugPrint('✅ Added primary invoice to cancelled invoice: ${invoiceIds.first}');
      } else {
        debugPrint('⚠️ No invoices found in delivery data');
      }

      debugPrint('📋 Cancelled invoice body data: $body');

      // Prepare efficiently compressed files if image is provided
      final files = <MultipartFile>[];
      if (cancelledInvoice.image != null &&
          cancelledInvoice.image!.isNotEmpty) {
        debugPrint('📷 Processing cancelled invoice image (using native compression)');

        try {
          // Use the same efficient compression as trip updates
          final compressedImageBytes = await _compressImage(cancelledInvoice.image!);
          if (compressedImageBytes != null) {
            files.add(MultipartFile.fromBytes(
              'image',
              compressedImageBytes,
              filename: 'cancelled_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));
            debugPrint('✅ Added compressed cancelled invoice image (${(compressedImageBytes.length / 1024).toStringAsFixed(2)} KB)');
          } else {
            // Fallback to original if compression fails
            final originalBytes = await File(cancelledInvoice.image!).readAsBytes();
            files.add(MultipartFile.fromBytes(
              'image',
              originalBytes,
              filename: 'cancelled_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));
            debugPrint('⚠️ Using original image (compression failed): ${(originalBytes.length / 1024).toStringAsFixed(2)} KB');
          }
        } catch (imageError) {
          debugPrint(
            '⚠️ Image processing failed, uploading original: $imageError',
          );
          // Fallback to original file if any processing fails
          final imageBytes = await File(cancelledInvoice.image!).readAsBytes();
          files.add(
            MultipartFile.fromBytes(
              'image',
              imageBytes,
              filename: 'cancelled_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
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

      // Record cancelled invoice in trip ticket
      try {
        debugPrint('📝 Recording cancelled invoice in trip ticket: $tripId');
        
        // Get current trip ticket to check existing cancelled invoices
        final tripTicketRecord = await _pocketBaseClient
            .collection('tripticket')
            .getOne(tripId);
        
        // Get existing cancelled invoices array or initialize empty array
        List<String> existingCancelledInvoices = [];
        if (tripTicketRecord.data['cancelledInvoice'] != null) {
          final existing = tripTicketRecord.data['cancelledInvoice'];
          if (existing is List) {
            existingCancelledInvoices = existing.cast<String>();
          } else if (existing is String && existing.isNotEmpty) {
            existingCancelledInvoices = [existing];
          }
        }
        
        // Add new cancelled invoice ID if not already present
        if (!existingCancelledInvoices.contains(record.id)) {
          existingCancelledInvoices.add(record.id);
          
          // Update trip ticket with new cancelled invoice
          await _pocketBaseClient
              .collection('tripticket')
              .update(
                tripId,
                body: {
                  'cancelledInvoice': existingCancelledInvoices,
                  'updated': DateTime.now().toUtc().toIso8601String(),
                },
              );
          
          debugPrint('✅ Successfully recorded cancelled invoice in trip ticket');
          debugPrint('📋 Trip now has ${existingCancelledInvoices.length} cancelled invoices');
        } else {
          debugPrint('⚠️ Cancelled invoice already recorded in trip ticket');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to record cancelled invoice in trip ticket: $e');
        // Don't throw error as cancelled invoice creation should still succeed
      }

      await _pocketBaseClient
          .collection('deliveryData')
          .create(body: {'invoiceStatus': 'cancelled'});

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

      // Update user performance - increment cancelled deliveries
      try {
        debugPrint('📊 Updating user performance for cancelled delivery');

        // Get user ID from trip ticket
        final tripTicketRecord = await _pocketBaseClient
            .collection('tripticket')
            .getOne(tripId);

        final userId = tripTicketRecord.data['user'];
        if (userId != null && userId.isNotEmpty) {
          debugPrint('👤 Found user ID from trip: $userId');

          // Find user performance record
          final userPerformanceRecords = await _pocketBaseClient
              .collection('userPerformance')
              .getList(filter: 'user = "$userId"');

          if (userPerformanceRecords.items.isNotEmpty) {
            // Update existing record
            final userPerformanceRecord = userPerformanceRecords.items.first;
            final currentCancelledDeliveries =
                userPerformanceRecord.data['cancelledDeliveries'] ?? 0;
            final newCancelledDeliveries =
                (currentCancelledDeliveries is String)
                    ? (int.tryParse(currentCancelledDeliveries) ?? 0) + 1
                    : (currentCancelledDeliveries as int) + 1;

            debugPrint(
              '📈 Incrementing cancelled deliveries: $currentCancelledDeliveries → $newCancelledDeliveries',
            );

            // Calculate new cancellation rate
            final totalDeliveries =
                userPerformanceRecord.data['totalDeliveries'] ?? 0;
            final totalDelCount =
                (totalDeliveries is String)
                    ? (int.tryParse(totalDeliveries) ?? 0)
                    : (totalDeliveries as int);

            final cancellationRate =
                totalDelCount > 0
                    ? (newCancelledDeliveries / totalDelCount * 100)
                    : 0.0;

            // Recalculate success rate
            final successfulDeliveries =
                userPerformanceRecord.data['successfulDeliveries'] ?? 0;
            final successfulDelCount =
                (successfulDeliveries is String)
                    ? (int.tryParse(successfulDeliveries) ?? 0)
                    : (successfulDeliveries as int);

            final successRate =
                totalDelCount > 0
                    ? (successfulDelCount / totalDelCount * 100)
                    : 0.0;

            await _pocketBaseClient
                .collection('userPerformance')
                .update(
                  userPerformanceRecord.id,
                  body: {
                    'cancelledDeliveries': newCancelledDeliveries.toString(),
                    'cancellationRate': cancellationRate.toStringAsFixed(2),
                    'successRate': successRate.toStringAsFixed(2),
                    'updated': DateTime.now().toIso8601String(),
                  },
                );

            debugPrint(
              '✅ User performance updated - Cancelled deliveries: $newCancelledDeliveries, Cancellation rate: ${cancellationRate.toStringAsFixed(2)}%',
            );
          } else {
            debugPrint('⚠️ No user performance record found for user: $userId');
          }
        } else {
          debugPrint('⚠️ No user ID found in trip ticket');
        }
      } catch (e) {
        debugPrint(
          '⚠️ Failed to update user performance for cancelled delivery: $e',
        );
        // Don't throw error here as cancelled invoice creation should still succeed
      }

      final cancelledInvoiceModel = _processCancelledInvoiceRecord(
        createdRecord,
      );

      debugPrint(
        '✨ Successfully created cancelled invoice with customer and invoice relations',
      );
      debugPrint('📊 Final model verification:');
      debugPrint('   - Model ID: ${cancelledInvoiceModel.id}');
      debugPrint(
        '   - Has Customer: ${cancelledInvoiceModel.customer.target != null}',
      );
      debugPrint(
        '   - Customer Name: ${cancelledInvoiceModel.customer.target?.name ?? "null"}',
      );
      debugPrint(
        '   - Has Invoice: ${cancelledInvoiceModel.invoice.target != null}',
      );
      debugPrint(
        '   - Invoice ID: ${cancelledInvoiceModel.invoice.target?.id ?? "null"}',
      );
      debugPrint(
        '   - Has Delivery Data: ${cancelledInvoiceModel.deliveryData.target != null}',
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

    // Process invoices data (multiple)
    List<InvoiceDataModel> invoicesList = [];
    if (record.expand['invoices'] != null) {
      final invoicesData = record.expand['invoices'];
      if (invoicesData is List) {
        invoicesList = invoicesData!.map((invoice) {
          return InvoiceDataModel.fromJson({
            'id': invoice.id,
            'collectionId': invoice.collectionId,
            'collectionName': invoice.collectionName,
            ...invoice.data,
            'expand': invoice.expand,
          });
        }).toList();
        debugPrint('✅ Processed ${invoicesList.length} invoices');
      }
    } else if (record.data['invoices'] != null && record.data['invoices'] is List) {
      invoicesList = (record.data['invoices'] as List)
          .map((id) => InvoiceDataModel(id: id.toString()))
          .toList();
      debugPrint('📋 Using ${invoicesList.length} invoice ID references');
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
    if (record.data['image'] != null &&
        record.data['image'].toString().isNotEmpty) {
      final baseUrl = _pocketBaseClient.baseUrl;
      final collectionId = record.collectionId;
      final recordId = record.id;
      final filename = record.data['image'];
      imageUrl = '$baseUrl/api/files/$collectionId/$recordId/$filename';
      debugPrint('📷 Processed image URL: $imageUrl');
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
      invoices: invoicesList,
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
    debugPrint(
      '   - Customer: ${cancelledInvoice.customer.target!.name ?? "null"}',
    );
    debugPrint(
      '   - Invoice: ${cancelledInvoice.invoice.target!.id ?? "null"}',
    );
    debugPrint(
      '   - Trip: ${cancelledInvoice.trip.target!.tripNumberId ?? "null"}',
    );
    debugPrint(
      '   - Delivery Data: ${cancelledInvoice.deliveryData.target?.id ?? "null"}',
    );

    return cancelledInvoice;
  }

  /// Compress image file to reduce size (same as trip updates)
  Future<Uint8List?> _compressImage(String imagePath) async {
    try {
      debugPrint('🗜️ Compressing cancelled invoice image: $imagePath');
      
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: 70, // 70% quality
        minWidth: 800, // Max width 800px
        minHeight: 600, // Max height 600px
        format: CompressFormat.jpeg,
      );
      
      if (compressedBytes != null) {
        final originalSize = await File(imagePath).length();
        debugPrint('📊 Cancelled invoice image compressed: $originalSize bytes -> ${compressedBytes.length} bytes');
        debugPrint('📉 Compression ratio: ${((originalSize - compressedBytes.length) / originalSize * 100).toStringAsFixed(1)}%');
      }
      
      return compressedBytes;
    } catch (e) {
      debugPrint('⚠️ Cancelled invoice image compression failed: $e');
      // Fallback to original file
      try {
        return await File(imagePath).readAsBytes();
      } catch (fallbackError) {
        debugPrint('❌ Failed to read original image file: $fallbackError');
        return null;
      }
    }
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

      final currentUndeliveredCustomers =
          int.tryParse(
            deliveryTeam.data['undeliveredCustomers']?.toString() ?? '0',
          ) ??
          0;

      final currentActiveDeliveries =
          int.tryParse(
            deliveryTeam.data['activeDeliveries']?.toString() ?? '0',
          ) ??
          0;

      final newUndelivered =
          (currentUndeliveredCustomers + 1).clamp(0, double.infinity).toInt();
      final newActiverDeliveries = currentActiveDeliveries - 1;
      // Update delivery team with new undelivered count
      await _pocketBaseClient
          .collection('deliveryTeam')
          .update(
            deliveryTeam.id,
            body: {
              'undeliveredCustomers': newUndelivered,
              'activeDeliveries': newActiverDeliveries,
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Updated delivery team stats:');
      debugPrint('   - Previous undelivered: $currentUndeliveredCustomers');
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
