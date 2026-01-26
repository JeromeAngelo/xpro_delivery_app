import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
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
            expand:
                'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer',
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
        debugPrint(
          '🔍 Trip ID appears to be tripNumberId, finding PocketBase record ID...',
        );
        try {
          final tripResults = await _pocketBaseClient
              .collection('tripticket')
              .getFullList(filter: 'id = "$actualTripId"');

          if (tripResults.isNotEmpty) {
            pocketBaseTripId = tripResults.first.id;
            debugPrint(
              '✅ Found PocketBase trip ID: $pocketBaseTripId for tripNumberId: $actualTripId',
            );
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
            expand:
                'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer',
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
          .getOne(
            id,
            expand:
                'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer',
          );

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
    final deliveryDataRecord = await _pocketBaseClient
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
      invoiceIds.addAll(
        invoicesExpand!.map((e) => e.id).whereType<String>(),
      );
    }

    if (deliveryDataRecord.data['invoice'] != null) {
      final singleInvoiceId =
          deliveryDataRecord.data['invoice'].toString();
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
        final bytes = await _compressImage(imagePath);
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
            ? await _pocketBaseClient
                .collection('cancelledInvoice')
                .create(body: body, files: files)
            : await _pocketBaseClient
                .collection('cancelledInvoice')
                .create(body: body);

    debugPrint('✅ CancelledInvoice created → ${record.id}');

    // --------------------------------------------------
    // 7️⃣ LINK TO TRIPTICKET (SAFE)
    // --------------------------------------------------
    try {
      final tripTicket = await _pocketBaseClient
          .collection('tripticket')
          .getOne(tripId);

      final existing =
          (tripTicket.data['cancelledInvoice'] as List?)
                  ?.cast<String>() ??
              [];

      if (!existing.contains(record.id)) {
        existing.add(record.id);

        await _pocketBaseClient.collection('tripticket').update(
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
      await _updateDeliveryTeamStats(tripId);
    // --------------------------------------------------
    // 8️⃣ UPDATE DELIVERYDATA STATUS
    // --------------------------------------------------
    await _pocketBaseClient.collection('deliveryData').update(
      deliveryDataId,
      body: {
        'invoiceStatus': 'cancelled',
        'updated': DateTime.now().toUtc().toIso8601String(),
      },
    );

    // --------------------------------------------------
    // 9️⃣ RETURN FULL MODEL
    // --------------------------------------------------
    final createdRecord = await _pocketBaseClient
        .collection('cancelledInvoice')
        .getOne(
          record.id,
          expand: 'deliveryData,trip,invoice,customer',
        );

    return _processCancelledInvoiceRecord(createdRecord);
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
      if (deliveryDataData is List ) {
        final deliveryDataRecord = deliveryDataData?[0];
        deliveryDataModel = DeliveryDataModel.fromJson({
          'id': deliveryDataRecord?.id,
          'collectionId': deliveryDataRecord?.collectionId,
          'collectionName': deliveryDataRecord?.collectionName,
          ...deliveryDataRecord?.data ?? {},
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
      if (tripData is List ) {
        final tripRecord = tripData?[0];
        tripModel = TripModel.fromJson({
          'id': tripRecord?.id,
          'collectionId': tripRecord?.collectionId,
          'collectionName': tripRecord?.collectionName,
          'tripNumberId': tripRecord?.data['tripNumberId'],
          'qrCode': tripRecord?.data['qrCode'],
          'isAccepted': tripRecord?.data['isAccepted'],
          'isEndTrip': tripRecord?.data['isEndTrip'],
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
      if (invoiceData is List ) {
        final invoiceRecord = invoiceData?[0];
        invoiceModel = InvoiceDataModel.fromJson({
          'id': invoiceRecord?.id,
          'collectionId': invoiceRecord?.collectionId,
          'collectionName': invoiceRecord?.collectionName,
          ...invoiceRecord?.data ?? {},
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
        invoicesList =
            invoicesData?.map((invoice) {
              return InvoiceDataModel.fromJson({
                'id': invoice.id,
                'collectionId': invoice.collectionId,
                'collectionName': invoice.collectionName,
                ...invoice.data,
                'expand': invoice.expand,
              });
            }).toList() ?? [];
        debugPrint('✅ Processed ${invoicesList.length} invoices');
      }
    } else if (record.data['invoices'] != null &&
        record.data['invoices'] is List) {
      invoicesList =
          (record.data['invoices'] as List)
              .map((id) => InvoiceDataModel(id: id.toString()))
              .toList();
      debugPrint('📋 Using ${invoicesList.length} invoice ID references');
    }

    // Process customer data
    CustomerDataModel? customerModel;
    if (record.expand['customer'] != null) {
      final customerData = record.expand['customer'];
      if (customerData is List) {
        final customerRecord = customerData?[0];
        customerModel = CustomerDataModel.fromJson({
          'id': customerRecord?.id,
          'collectionId': customerRecord?.collectionId,
          'collectionName': customerRecord?.collectionName,
          ...customerRecord?.data ?? {},
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
      deliveryDataModel: deliveryDataModel,
      tripModel: tripModel,
      invoiceModel: invoiceModel,
      invoicesList: invoicesList,
      customerModel: customerModel,
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
      '   - Customer: ${cancelledInvoice.customer.target?.name ?? "null"}',
    );
    debugPrint(
      '   - Invoice: ${cancelledInvoice.invoice.target?.id ?? "null"}',
    );
    debugPrint(
      '   - Trip: ${cancelledInvoice.trip.target?.tripNumberId ?? "null"}',
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
        debugPrint(
          '📊 Cancelled invoice image compressed: $originalSize bytes -> ${compressedBytes.length} bytes',
        );
        debugPrint(
          '📉 Compression ratio: ${((originalSize - compressedBytes.length) / originalSize * 100).toStringAsFixed(1)}%',
        );
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
