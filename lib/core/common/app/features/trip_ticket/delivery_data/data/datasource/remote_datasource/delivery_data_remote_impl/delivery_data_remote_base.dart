import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';

import '../../../../../../../../../enums/invoice_status.dart';

class DeliveryDataRemoteBase {
  final PocketBase pocketBaseClient;

  const DeliveryDataRemoteBase({required this.pocketBaseClient});

  // ================================================================
  // HELPER METHODS (formerly private, now public for mixin access)
  // ================================================================

  /// Format seconds into readable time format (matching local datasource format)
  String formatDeliveryTime(int totalSeconds) {
    if (totalSeconds <= 0) {
      return '0m';
    }

    final totalMinutes = (totalSeconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    // Format: "1h 30m" (matching local datasource format)
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  String formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  /// Update delivery data with total delivery time and return formatted time
  Future<String> updateDeliveryDataTotalTime(
    String deliveryId,
    int totalSeconds,
  ) async {
    try {
      final timeText = formatDeliveryTime(totalSeconds);
      debugPrint(
        '💾 Updating delivery data $deliveryId with total time: $timeText',
      );

      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryId,
            body: {
              'totalDeliveryTime': timeText,
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint(
        '✅ Successfully updated delivery data with total time: $timeText',
      );
      return timeText;
    } catch (e) {
      debugPrint('⚠️ Failed to update delivery data with total time: $e');
      // Return formatted time even if update fails
      return formatDeliveryTime(totalSeconds);
    }
  }

  // Helper method to process a delivery data record
  DeliveryDataModel processDeliveryDataRecord(RecordModel record) {
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
      }
    } else if (record.data['customer'] != null) {
      customerModel = CustomerDataModel(id: record.data['customer'].toString());
    }

    // Process invoices data (multiple)
    List<InvoiceDataModel> invoicesList = [];
    if (record.expand['invoices'] != null) {
      final invoicesData = record.expand['invoices'];
      if (invoicesData is List) {
        invoicesList =
            invoicesData!.map((invoice) {
              return InvoiceDataModel.fromJson({
                'id': invoice.id,
                'collectionId': invoice.collectionId,
                'collectionName': invoice.collectionName,
                ...invoice.data,
                'expand': invoice.expand,
              });
            }).toList();
      }
    } else if (record.data['invoices'] != null &&
        record.data['invoices'] is List) {
      invoicesList =
          (record.data['invoices'] as List)
              .map((id) => InvoiceDataModel(id: id.toString()))
              .toList();
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
      }
    } else if (record.data['trip'] != null) {
      tripModel = TripModel(id: record.data['trip'].toString());
    }

    // Process delivery updates
    List<DeliveryUpdateModel> deliveryUpdatesList = [];
    if (record.expand['deliveryUpdates'] != null) {
      final deliveryUpdatesData = record.expand['deliveryUpdates'];
      if (deliveryUpdatesData is List) {
        deliveryUpdatesList =
            deliveryUpdatesData!.map((update) {
              return DeliveryUpdateModel.fromJson({
                'id': update.id,
                'collectionId': update.collectionId,
                'collectionName': update.collectionName,
                'title': update.data['title'],
                'subtitle': update.data['subtitle'],
                'time': update.data['time'],
                'customer': update.data['customer'],
                'isAssigned': update.data['isAssigned'],
                'deliveryNumber': update.data['deliveryNumber'],
              });
            }).toList();
      }
    } else if (record.data['deliveryUpdates'] != null &&
        record.data['deliveryUpdates'] is List) {
      deliveryUpdatesList =
          (record.data['deliveryUpdates'] as List)
              .map((id) => DeliveryUpdateModel(id: id.toString()))
              .toList();
    }

    List<InvoiceItemsModel> invoiceItemsList = [];
    if (record.expand['invoiceItems'] != null) {
      final invoiceItemsData = record.expand['invoiceItems'];
      if (invoiceItemsData is List) {
        invoiceItemsList =
            invoiceItemsData!.map((item) {
              return InvoiceItemsModel.fromJson({
                'id': item.id,
                'collectionId': item.collectionId,
                'collectionName': item.collectionName,
                'name': item.data['name'],
                'brand': item.data['brand'],
                'refId': item.data['refId'],
                'uom': item.data['uom'],
                'quantity': item.data['quantity'],
                'totalBaseQuantity': item.data['totalBaseQuantity'],
                'uomPrice': item.data['uomPrice'],
                'totalPrice': item.data['totalPrice'],
              });
            }).toList();
      }
    } else if (record.data['invoiceItems'] != null &&
        record.data['invoiceItems'] is List) {
      invoiceItemsList =
          (record.data['invoiceItems'] as List)
              .map((id) => InvoiceItemsModel(id: id.toString()))
              .toList();
    }

    // UPDATED: Process invoice status with proper enum conversion
    InvoiceStatus? invoiceStatus;
    final invoiceStatusString = record.data['invoiceStatus'];
    if (invoiceStatusString != null && invoiceStatusString is String) {
      try {
        // Convert string to enum
        invoiceStatus = parseInvoiceStatus(invoiceStatusString);
        debugPrint('✅ Parsed invoice status: ${invoiceStatus.name}');
      } catch (e) {
        debugPrint(
          '⚠️ Failed to parse invoice status "$invoiceStatusString": $e',
        );
        invoiceStatus = InvoiceStatus.none; // Default fallback
      }
    }

    // Calculate total amount with fallback to invoices
    double calculatedTotalAmount = 0.0;

    // Priority 1: Use totalAmount from record if available and > 0
    if (record.data['totalAmount'] != null) {
      final parsed = double.tryParse(record.data['totalAmount'].toString());
      if (parsed != null && parsed > 0) {
        calculatedTotalAmount = parsed;
        debugPrint(
          '💰 Remote: Using totalAmount from record: ₱${calculatedTotalAmount.toStringAsFixed(2)}',
        );
      }
    }

    // Priority 2: Calculate from invoices if totalAmount is 0 or null
    if (calculatedTotalAmount <= 0 && invoicesList.isNotEmpty) {
      try {
        for (final invoice in invoicesList) {
          if (invoice.totalAmount != null && invoice.totalAmount! > 0) {
            calculatedTotalAmount += invoice.totalAmount!;
          }
        }
        if (calculatedTotalAmount > 0) {
          debugPrint(
            '💰 Remote: Calculated totalAmount from ${invoicesList.length} invoices: ₱${calculatedTotalAmount.toStringAsFixed(2)}',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Remote: Error calculating total from invoices: $e');
      }
    }

    final deliveryModel = DeliveryDataModel(
      id: record.id,
      deliveryNumber: record.data['deliveryNumber'],
      invoiceStatus: invoiceStatus, // Now properly converted to enum
      customerData: customerModel,
      invoiceItemsList: invoiceItemsList,
      invoicesList: invoicesList,
      tripData: tripModel,
      deliveryUpdatesList: deliveryUpdatesList,
      paymentMode: record.data['paymentMode']?.toString(),
      storeName: record.data['storeName']?.toString(),
      ownerName: record.data['ownerName']?.toString(),
      contactNumber: record.data['contactNumber']?.toString(),
      barangay: record.data['barangay']?.toString(),
      municipality: record.data['municipality']?.toString(),
      province: record.data['province']?.toString(),
      refID: record.data['refID']?.toString(),
      totalDeliveryTime: record.data['totalDeliveryTime']?.toString(),
      hasTrip: record.data['hasTrip'] as bool? ?? false,
      totalAmount: calculatedTotalAmount > 0 ? calculatedTotalAmount : null,
      isUnloaded: record.data['isUnloaded'] as bool? ?? false,
      isUnloading: record.data['isUnloading'] as bool? ?? false,
      created: parseDate(record.data['created']),
      updated: parseDate(record.data['updated']),
    );

    // ENHANCEMENT: Validate delivery status is present
    debugPrint('🔍 Validating delivery status for ${deliveryModel.id}...');

    if (deliveryUpdatesList.isEmpty) {
      debugPrint(
        '⚠️ WARNING: Delivery ${deliveryModel.id} has NO delivery updates - missing required status ("End Delivery" or "Mark as Undelivered")',
      );
    } else {
      final hasRequiredStatus = deliveryUpdatesList.any((update) {
        final titleLower = (update.title ?? '').toLowerCase();
        return titleLower.contains('end delivery') ||
            titleLower.contains('mark as undelivered');
      });

      if (hasRequiredStatus) {
        debugPrint(
          '✅ Delivery ${deliveryModel.id} has required final status update',
        );
      } else {
        debugPrint(
          '⚠️ WARNING: Delivery ${deliveryModel.id} missing required final status ("End Delivery" or "Mark as Undelivered")',
        );
        debugPrint(
          '   Available statuses: ${deliveryUpdatesList.map((u) => u.title).toList()}',
        );
      }
    }

    return deliveryModel;
  }

  // Helper method to parse invoice status string to enum
  InvoiceStatus parseInvoiceStatus(String statusString) {
    final normalizedStatus = statusString.toLowerCase().trim();

    switch (normalizedStatus) {
      case 'none':
      case 'pending':
      case '':
        return InvoiceStatus.none;
      case 'truck':
      case 'in_truck':
      case 'intruck':
        return InvoiceStatus.truck;
      case 'unloading':
        return InvoiceStatus.unloading;
      case 'unloaded':
        return InvoiceStatus.unloaded;
      case 'completed':
      case 'complete':
        return InvoiceStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return InvoiceStatus.cancelled;
      default:
        debugPrint(
          '⚠️ Unknown invoice status: "$statusString", defaulting to none',
        );
        return InvoiceStatus.none;
    }
  }

  // Helper method to parse date strings
  DateTime? parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('⚠️ Failed to parse date "$value": $e');
      return null;
    }
  }

  // ================================================================
  // DELIVERY STATUS VALIDATION METHODS
  // ================================================================

  /// Check if a delivery data has required final status
  /// Returns true if delivery has "End Delivery" or "Mark as Undelivered" status
  bool hasRequiredDeliveryStatus(DeliveryDataModel delivery) {
    if (delivery.deliveryUpdates.isEmpty) {
      return false;
    }

    return delivery.deliveryUpdates.any((update) {
      final titleLower = (update.title ?? '').toLowerCase();
      return titleLower.contains('end delivery') ||
          titleLower.contains('mark as undelivered');
    });
  }

  /// Get delivery status summary
  Map<String, dynamic> getDeliveryStatusSummary(DeliveryDataModel delivery) {
    final updateTitles =
        delivery.deliveryUpdates.map((u) => u.title ?? 'Unknown').toList();

    final hasEndDelivery = updateTitles.any(
      (title) => title.toLowerCase().contains('end delivery'),
    );

    final hasMarkUndelivered = updateTitles.any(
      (title) => title.toLowerCase().contains('mark as undelivered'),
    );

    return {
      'deliveryId': delivery.id,
      'totalUpdates': delivery.deliveryUpdates.length,
      'updateTitles': updateTitles,
      'hasEndDelivery': hasEndDelivery,
      'hasMarkUndelivered': hasMarkUndelivered,
      'isCompliant': hasEndDelivery || hasMarkUndelivered,
    };
  }
}
