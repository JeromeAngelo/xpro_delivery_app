import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';

import '../../../../invoice_items/data/model/invoice_items_model.dart';

abstract class DeliveryDataRemoteDataSource {
  // Get all delivery data
  Future<List<DeliveryDataModel>> getAllDeliveryData();

  // Get all delivery data by trip ID
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId);

  // Get delivery data by ID
  Future<DeliveryDataModel> getDeliveryDataById(String id);

  Future<List<DeliveryDataModel>> getAllDeliveryDataWithTrips();

  Future<bool> deleteDeliveryData(String id);

  Future<bool> addDeliveryDataToTrip(String tripId);
}

class DeliveryDataRemoteDataSourceImpl implements DeliveryDataRemoteDataSource {
  const DeliveryDataRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  static const String _authTokenKey = 'auth_token';
  static const String _authUserKey = 'auth_user';

  // Helper method to ensure PocketBase client is authenticated
  Future<void> _ensureAuthenticated() async {
    try {
      // Check if already authenticated
      if (_pocketBaseClient.authStore.isValid) {
        debugPrint('✅ PocketBase client already authenticated');
        return;
      }

      debugPrint('⚠️ PocketBase client not authenticated, attempting to restore from storage');

      // Try to restore authentication from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(_authTokenKey);
      final userDataString = prefs.getString(_authUserKey);

      if (authToken != null && userDataString != null) {
        debugPrint('🔄 Restoring authentication from storage');

        // Restore the auth store with token only
        // The PocketBase client will handle the record validation
        _pocketBaseClient.authStore.save(authToken, null);
        
        debugPrint('✅ Authentication restored from storage');
      } else {
        debugPrint('❌ No stored authentication found');
        throw const ServerException(
          message: 'User not authenticated. Please log in again.',
          statusCode: '401',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to ensure authentication: ${e.toString()}');
      throw ServerException(
        message: 'Authentication error: ${e.toString()}',
        statusCode: '401',
      );
    }
  }

  // Helper method for retry logic with exponential backoff
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int retryCount = 0;
    Duration delay = initialDelay;

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;

        // Check if it's a network-related error
        bool isNetworkError =
            e.toString().contains('Failed to fetch') ||
            e.toString().contains('statusCode: 0') ||
            e.toString().contains('isAbort: true') ||
            e.toString().contains('ClientException');

        debugPrint(
          '🔄 Attempt $retryCount/$maxRetries failed for $operationName: ${e.toString()}',
        );

        if (retryCount >= maxRetries || !isNetworkError) {
          debugPrint(
            '❌ Max retries exceeded or non-network error for $operationName',
          );

          // Provide more user-friendly error messages
          if (isNetworkError) {
            throw ServerException(
              message:
                  'Network connection failed. Please check your internet connection and try again.',
              statusCode: '503',
            );
          }

          rethrow;
        }

        debugPrint(
          '⏳ Retrying $operationName in ${delay.inSeconds} seconds...',
        );
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
      }
    }

    throw ServerException(
      message: 'Failed to complete $operationName after $maxRetries attempts',
      statusCode: '503',
    );
  }

  @override
  Future<List<DeliveryDataModel>> getAllDeliveryDataWithTrips() async {
    return await _retryWithBackoff(() async {
      debugPrint('🔄 Fetching all delivery data with trips');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      final result = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            filter:
                'hasTrip = true', // ← ONLY DIFFERENCE: true instead of false
            expand: 'customer,invoice,trip,deliveryUpdates,invoiceItems',
            sort: '-created',
          );

      debugPrint(
        '✅ Retrieved ${result.length} delivery data records with trips',
      );

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(_processDeliveryDataRecord(record));
      }

      return deliveryDataList;
    }, 'getAllDeliveryDataWithTrips');
  }

  @override
  Future<List<DeliveryDataModel>> getAllDeliveryData() async {
    return await _retryWithBackoff(() async {
      debugPrint('🔄 Fetching all delivery data');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      final result = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            filter: 'hasTrip = false',
            expand: 'customer,invoice,trip,deliveryUpdates,invoiceItems',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${result.length} delivery data records');

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(_processDeliveryDataRecord(record));
      }

      return deliveryDataList;
    }, 'getAllDeliveryData');
  }

  @override
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId) async {
    return await _retryWithBackoff(() async {
      debugPrint('🔄 Fetching delivery data for trip ID: $tripId');

      final result = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            expand: 'customer,invoice,trip,deliveryUpdates,invoiceItems',
            filter: 'trip = "$tripId"',
            sort: '-created',
          );

      debugPrint(
        '✅ Retrieved ${result.length} delivery data records for trip ID: $tripId',
      );

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(_processDeliveryDataRecord(record));
      }

      return deliveryDataList;
    }, 'getDeliveryDataByTripId');
  }

  @override
  Future<DeliveryDataModel> getDeliveryDataById(String id) async {
    return await _retryWithBackoff(() async {
      debugPrint('🔄 Fetching delivery data with ID: $id');

      final record = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            id,
            expand: 'customer,invoice,trip,deliveryUpdates,invoiceItems',
          );

      debugPrint('✅ Retrieved delivery data with ID: $id');

      return _processDeliveryDataRecord(record);
    }, 'getDeliveryDataById');
  }

  @override
  Future<bool> deleteDeliveryData(String id) async {
    try {
      debugPrint('🔄 Deleting delivery data with ID: $id');

      // First, get the delivery data to check its relationships
      final record = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(id);

      // Get the invoice ID from the delivery data
      final invoiceId = record.data['invoice'];

      if (invoiceId != null && invoiceId != '') {
        debugPrint(
          '🔍 Found invoice ID: $invoiceId in delivery data, checking for invoiceStatus records',
        );

        // Find any invoiceStatus records that reference this invoice
        try {
          final invoiceStatusRecords = await _pocketBaseClient
              .collection('invoiceStatus')
              .getFullList(filter: 'invoiceData = "$invoiceId"');

          // Delete each invoiceStatus record that references this invoice
          for (var statusRecord in invoiceStatusRecords) {
            debugPrint('🗑️ Deleting invoiceStatus record: ${statusRecord.id}');
            await _pocketBaseClient
                .collection('invoiceStatus')
                .delete(statusRecord.id);
          }

          debugPrint(
            '✅ Deleted ${invoiceStatusRecords.length} invoiceStatus records',
          );
        } catch (e) {
          // Just log the error but continue with deleting the delivery data
          debugPrint(
            '⚠️ Error while deleting invoiceStatus records: ${e.toString()}',
          );
        }
      }

      // Delete the delivery data
      await _pocketBaseClient.collection('deliveryData').delete(id);

      debugPrint('✅ Successfully deleted delivery data with ID: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete delivery data: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete delivery data: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  @override
  Future<bool> addDeliveryDataToTrip(String tripId) async {
    return await _retryWithBackoff(() async {
      debugPrint('🔄 Adding delivery data to trip ID: $tripId');
      
      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      try {
        // Find delivery data records that don't have a trip assigned (hasTrip = false)
        final availableDeliveryData = await _pocketBaseClient
            .collection('deliveryData')
            .getFullList(
              filter: 'hasTrip = false',
              sort: 'created',
            );

        if (availableDeliveryData.isEmpty) {
          debugPrint('⚠️ No available delivery data to assign to trip');
          throw const ServerException(
            message: 'No available delivery data found to assign to trip',
            statusCode: '404',
          );
        }

        // Take the first available delivery data record
        final deliveryDataRecord = availableDeliveryData.first;
        
        // Update the delivery data record to assign it to the trip
        await _pocketBaseClient.collection('deliveryData').update(
          deliveryDataRecord.id,
          body: {
            'trip': tripId,
            'hasTrip': true,
          },
        );

        debugPrint('✅ Successfully added delivery data ${deliveryDataRecord.id} to trip $tripId');
        return true;
      } catch (e) {
        debugPrint('❌ Failed to add delivery data to trip: ${e.toString()}');
        throw ServerException(
          message: 'Failed to add delivery data to trip: ${e.toString()}',
          statusCode: e is ServerException ? e.statusCode : '500',
        );
      }
    }, 'addDeliveryDataToTrip');
  }

  // Helper method to process a delivery data record
  DeliveryDataModel _processDeliveryDataRecord(RecordModel record) {
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
      }
    } else if (record.data['invoice'] != null) {
      invoiceModel = InvoiceDataModel(id: record.data['invoice'].toString());
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

    // Add this after the deliveryUpdates processing section:

    // Process invoice items
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
                'refId': item.data['refID'],
                'uom': item.data['uom'],
                'quantity': item.data['quantity'],
                'totalBaseQuantity': item.data['totalBaseQuantity'],
                'uomPrice': item.data['uomPrice'],
                'totalAmount': item.data['totalAmount'],
                'invoiceData': item.data['invoiceData'],
                'created': item.data['created'],
                'updated': item.data['updated'],
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

    return DeliveryDataModel(
      id: record.id,
      collectionId: record.collectionId,
      collectionName: record.collectionName,
      deliveryNumber: record.data['deliveryNumber'],
      customer: customerModel,
      invoice: invoiceModel,
      trip: tripModel,
      invoiceItems: invoiceItemsList,
      deliveryUpdates: deliveryUpdatesList,
    );
  }
}
