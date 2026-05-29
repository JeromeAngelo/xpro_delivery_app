import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';

import '../../../../../../../../../enums/undeliverable_reason.dart';

abstract class CancelledInvoiceRemoteBase {
  final PocketBase pocketBaseClient;

  const CancelledInvoiceRemoteBase({required this.pocketBaseClient});

  // ================================================================
  // HELPER METHODS (formerly private, now public for mixin access)
  // ================================================================

  /// Process a cancelled invoice record - matching delivery_data pattern
  CancelledInvoiceModel processCancelledInvoiceRecord(RecordModel record) {
    debugPrint('🔄 Processing cancelled invoice record: ${record.id}');
    debugPrint('📋 Raw record data: ${record.data}');
    debugPrint('📋 Record expand keys: ${record.expand.keys.toList()}');

    // Process delivery data
    DeliveryDataModel? deliveryDataModel;
    if (record.expand['deliveryData'] != null) {
      final deliveryDataData = record.expand['deliveryData'];
      if (deliveryDataData is List) {
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
      if (tripData is List) {
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
      if (invoiceData is List) {
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
            }).toList() ??
            [];
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
      final baseUrl = pocketBaseClient.baseUrl;
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
  Future<Uint8List?> compressImage(String imagePath) async {
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

  /// Helper method to update delivery team stats
  Future<void> updateDeliveryTeamStats(String tripId) async {
    try {
      debugPrint('📊 Updating delivery team stats for trip: $tripId');

      // Get delivery team for this trip
      final deliveryTeamRecords = await pocketBaseClient
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
      await pocketBaseClient
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
}
