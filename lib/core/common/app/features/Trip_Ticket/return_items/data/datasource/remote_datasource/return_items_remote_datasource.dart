import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/data/model/return_items_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class ReturnItemsRemoteDataSource {
  // Get return items by trip ID
  Future<List<ReturnItemsModel>> getReturnItemsByTripId(String tripId);

  // Get return item by ID
  Future<ReturnItemsModel> getReturnItemById(String returnItemId);

  // Add items to return items by delivery ID
  Future<ReturnItemsModel> addItemsToReturnItemsByDeliveryId(String deliveryId, ReturnItemsModel returnItem);
}

class ReturnItemsRemoteDataSourceImpl implements ReturnItemsRemoteDataSource {
  const ReturnItemsRemoteDataSourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<ReturnItemsModel>> getReturnItemsByTripId(String tripId) async {
    try {
      debugPrint('🔄 Fetching return items for trip ID: $tripId');

      final result = await _pocketBaseClient
          .collection('returnItems')
          .getFullList(
            expand: 'trip,deliveryData,invoiceItem,invoiceData,'
                'trip.deliveryTeam,trip.personels,'
                'deliveryData.customer,deliveryData.invoice,'
                'invoiceItem.invoice,invoiceData.customer',
            filter: 'trip = "$tripId"',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${result.length} return items for trip ID: $tripId');

      List<ReturnItemsModel> returnItemsList = [];

      for (var record in result) {
        returnItemsList.add(_processReturnItemRecord(record));
      }

      debugPrint('✅ Successfully processed ${returnItemsList.length} return items');

      return returnItemsList;
    } catch (e) {
      debugPrint('❌ Failed to fetch return items by trip ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch return items by trip ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<ReturnItemsModel> getReturnItemById(String returnItemId) async {
    try {
      debugPrint('🔄 Fetching return item with ID: $returnItemId');

      final record = await _pocketBaseClient
          .collection('returnItems')
          .getOne(
            returnItemId,
            expand: 'trip,deliveryData,invoiceItem,invoiceData,'
                'trip.deliveryTeam,trip.personels,'
                'deliveryData.customer,deliveryData.invoice,'
                'invoiceItem.invoice,invoiceData.customer',
          );

      debugPrint('✅ Retrieved return item with ID: $returnItemId');

      return _processReturnItemRecord(record);
    } catch (e) {
      debugPrint('❌ Failed to fetch return item by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch return item by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<ReturnItemsModel> addItemsToReturnItemsByDeliveryId(
    String deliveryId,
    ReturnItemsModel returnItem,
  ) async {
    try {
      debugPrint('🔄 Adding return item to delivery ID: $deliveryId');

      // First, get the delivery data to extract trip information
      final deliveryRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryId, expand: 'trip');

      if (deliveryRecord.data['trip'] == null) {
        throw ServerException(
          message: 'Delivery data is not associated with any trip',
          statusCode: '400',
        );
      }

      final tripId = deliveryRecord.data['trip'].toString();

      // Prepare the return item data
      final returnItemData = {
        'trip': tripId,
        'deliveryData': deliveryId,
        'invoiceItem': returnItem.invoiceItem.target?.id,
        'invoiceData': returnItem.invoiceData.target?.id,
        'refId': returnItem.refId,
        'quantity': returnItem.quantity,
        'uom': returnItem.uom,
        'reason': _convertReasonToString(returnItem.reason),
        'created': DateTime.now().toUtc().toIso8601String(),
        'updated': DateTime.now().toUtc().toIso8601String(),
      };

      // Remove null values
      returnItemData.removeWhere((key, value) => value == null);

      debugPrint('📤 Creating return item with data: $returnItemData');

      // Create the return item
      final createdRecord = await _pocketBaseClient
          .collection('returnItems')
          .create(
            body: returnItemData,
            expand: 'trip,deliveryData,invoiceItem,invoiceData,'
                'trip.deliveryTeam,trip.personels,'
                'deliveryData.customer,deliveryData.invoice,'
                'invoiceItem.invoice,invoiceData.customer',
          );

      debugPrint('✅ Successfully created return item with ID: ${createdRecord.id}');

      return _processReturnItemRecord(createdRecord);
    } catch (e) {
      debugPrint('❌ Failed to add return item to delivery: ${e.toString()}');
      throw ServerException(
        message: 'Failed to add return item to delivery: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  /// Helper method to process a return item record
  ReturnItemsModel _processReturnItemRecord(RecordModel record) {
    try {
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
            ...tripRecord.data,
            'expand': tripRecord.expand,
          });
        }
      } else if (record.data['trip'] != null) {
        tripModel = TripModel(id: record.data['trip'].toString());
      }

      // Process delivery data
      DeliveryDataModel? deliveryDataModel;
      if (record.expand['deliveryData'] != null) {
        final deliveryData = record.expand['deliveryData'];
        if (deliveryData is List && deliveryData!.isNotEmpty) {
          final deliveryRecord = deliveryData[0];
          deliveryDataModel = DeliveryDataModel.fromJson({
            'id': deliveryRecord.id,
            'collectionId': deliveryRecord.collectionId,
            'collectionName': deliveryRecord.collectionName,
            ...deliveryRecord.data,
            'expand': deliveryRecord.expand,
          });
        }
      } else if (record.data['deliveryData'] != null) {
        deliveryDataModel = DeliveryDataModel(id: record.data['deliveryData'].toString());
      }

      // Process invoice item data
      InvoiceItemsModel? invoiceItemModel;
      if (record.expand['invoiceItem'] != null) {
        final invoiceItemData = record.expand['invoiceItem'];
        if (invoiceItemData is List && invoiceItemData!.isNotEmpty) {
          final invoiceItemRecord = invoiceItemData[0];
          invoiceItemModel = InvoiceItemsModel.fromJson({
            'id': invoiceItemRecord.id,
            'collectionId': invoiceItemRecord.collectionId,
            'collectionName': invoiceItemRecord.collectionName,
            ...invoiceItemRecord.data,
            'expand': invoiceItemRecord.expand,
          });
        }
      } else if (record.data['invoiceItem'] != null) {
        invoiceItemModel = InvoiceItemsModel(id: record.data['invoiceItem'].toString());
      }

      // Process invoice data
      InvoiceDataModel? invoiceDataModel;
      if (record.expand['invoiceData'] != null) {
        final invoiceData = record.expand['invoiceData'];
        if (invoiceData is List && invoiceData!.isNotEmpty) {
          final invoiceRecord = invoiceData[0];
          invoiceDataModel = InvoiceDataModel.fromJson({
            'id': invoiceRecord.id,
            'collectionId': invoiceRecord.collectionId,
            'collectionName': invoiceRecord.collectionName,
            ...invoiceRecord.data,
            'expand': invoiceRecord.expand,
          });
        }
      } else if (record.data['invoiceData'] != null) {
        invoiceDataModel = InvoiceDataModel(id: record.data['invoiceData'].toString());
      }

      return ReturnItemsModel(
        id: record.id,
        collectionId: record.collectionId,
        collectionName: record.collectionName,
        refId: record.data['refId']?.toString(),
        quantity: record.data['quantity'] as int?,
        uom: record.data['uom']?.toString(),
        reason: _parseReturnReason(record.data['reason']),
        trip: tripModel,
        deliveryData: deliveryDataModel,
        invoiceItem: invoiceItemModel,
        invoiceData: invoiceDataModel,
        created: _parseDate(record.data['created']),
        updated: _parseDate(record.data['updated']),
      );
    } catch (e) {
      debugPrint('❌ Error processing return item record: $e');
      rethrow;
    }
  }

  /// Helper method to parse return reason from string
  dynamic _parseReturnReason(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    
    try {
      // This will be handled by the model's fromJson method
      return value;
    } catch (e) {
      debugPrint('⚠️ Error parsing return reason: $e');
      return null;
    }
  }

  /// Helper method to convert reason enum to string
  String? _convertReasonToString(dynamic reason) {
    if (reason == null) return null;
    
    // This will be handled by the model's toJson method
    return reason.toString().split('.').last;
  }

  /// Helper method to parse date
  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('⚠️ Error parsing date: $e');
      return null;
    }
  }
}
