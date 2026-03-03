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

      debugPrint(
        '⚠️ PocketBase client not authenticated, attempting to restore from storage',
      );

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
            expand:
                'customer,invoice,invoices,trip,deliveryUpdates,invoiceItems,trip.user', // ← ALSO EXPAND TRIP.USER
            sort: '-created',
          );

      debugPrint(
        '✅ Retrieved ${result.length} delivery data records with trips',
      );

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(_processDeliveryDataRecordFull(record));
      }

      return deliveryDataList;
    }, 'getAllDeliveryDataWithTrips');
  }

  @override
Future<List<DeliveryDataModel>> getAllDeliveryData() async {
  return _retryWithBackoff(() async {
    debugPrint('🔄 Fetching all delivery data');

    await _ensureAuthenticated();

    // Use pagination instead of getFullList
    const perPage = 200;
    int page = 1;

    final List<RecordModel> all = [];

    while (true) {
      final res = await _pocketBaseClient.collection('deliveryData').getList(
            page: page,
            perPage: perPage,
            filter: 'hasTrip = false',
            expand: 'customer,invoice,invoices,trip,deliveryUpdates,invoiceItems',
            sort: '-created',
            // fields: 'id,created,hasTrip,deliveryNumber,customer,invoice,expand.customer,expand.invoice', // enable if possible
          );

      all.addAll(res.items);

      if (res.items.length < perPage) break; // no more pages
      page++;
    }

    debugPrint('✅ Retrieved ${all.length} delivery data records');

    return all.map(_processDeliveryDataRecordFull).toList(growable: false);
  }, 'getAllDeliveryData');
}

  @override
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId) async {
    return await _retryWithBackoff(() async {
      debugPrint('🔄 Fetching delivery data for trip ID: $tripId');

      final result = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            expand:
                'customer,invoice,invoices,trip,deliveryUpdates,invoiceItems',
            filter: 'trip = "$tripId"',
            sort: '-created',
          );

      debugPrint(
        '✅ Retrieved ${result.length} delivery data records for trip ID: $tripId',
      );

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(_processDeliveryDataRecordFull(record));
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
            expand:
                'customer,invoice,invoices,trip,deliveryUpdates,invoiceItems',
          );

      debugPrint('✅ Retrieved delivery data with ID: $id');

      return _processDeliveryDataRecordFull(record);
    }, 'getDeliveryDataById');
  }
@override
Future<bool> deleteDeliveryData(String id) async {
  try {
    debugPrint('🔄 Deleting delivery data with ID: $id');

    // Step 1: Fetch the deliveryData record to check relationships
    final record = await _pocketBaseClient
        .collection('deliveryData')
        .getOne(id);

    debugPrint('📦 Found delivery data record: ${record.id}');

    // Step 2: Delete all invoiceStatus records referencing this deliveryData
    try {
      final invoiceStatusRecords = await _pocketBaseClient
          .collection('invoiceStatus')
          .getFullList(filter: 'deliveryData = "$id"');

      if (invoiceStatusRecords.isNotEmpty) {
        for (var statusRecord in invoiceStatusRecords) {
          debugPrint('🗑️ Deleting invoiceStatus record: ${statusRecord.id}');
          await _pocketBaseClient
              .collection('invoiceStatus')
              .delete(statusRecord.id);
        }
        debugPrint('✅ Deleted ${invoiceStatusRecords.length} invoiceStatus records linked to deliveryData: $id');
      } else {
        debugPrint('ℹ️ No invoiceStatus records found referencing deliveryData: $id');
      }
    } catch (e) {
      debugPrint('⚠️ Error while deleting invoiceStatus records: ${e.toString()}');
      // Continue even if deleting related statuses fails
    }

    // Step 3: Optionally, delete related invoice by its ID (if present)
    final invoiceId = record.data['invoice'];
    if (invoiceId != null && invoiceId.toString().isNotEmpty) {
      debugPrint('🧾 Deleting linked invoice record: $invoiceId');
      try {
        await _pocketBaseClient.collection('invoiceData').delete(invoiceId);
        debugPrint('✅ Deleted invoice record: $invoiceId');
      } catch (e) {
        debugPrint('⚠️ Failed to delete linked invoice record: ${e.toString()}');
      }
    }

    // Step 4: Delete the main deliveryData record
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
            .getFullList(filter: 'hasTrip = false', sort: 'created');

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
        await _pocketBaseClient
            .collection('deliveryData')
            .update(
              deliveryDataRecord.id,
              body: {'trip': tripId, 'hasTrip': true},
            );

        debugPrint(
          '✅ Successfully added delivery data ${deliveryDataRecord.id} to trip $tripId',
        );
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
// ✅ Helpers (compile-safe with PB Dart typing)

RecordModel? _firstExpanded(RecordModel record, String key) {
  // Force dynamic so analyzer doesn't lock the type to List<RecordModel>
  final dynamic exp = record.expand[key];
  if (exp == null) return null;

  // Case 1: PB returns a single RecordModel
  if (exp is RecordModel) return exp;

  // Case 2: PB returns a list of RecordModel
  if (exp is List) {
    if (exp.isEmpty) return null;
    final first = exp.first;
    return first is RecordModel ? first : null;
  }

  return null;
}

List<RecordModel> _listExpanded(RecordModel record, String key) {
  final dynamic exp = record.expand[key];
  if (exp == null) return const [];

  // Case 1: list relation expand
  if (exp is List) {
    return exp.whereType<RecordModel>().toList(growable: false);
  }

  // Case 2: single relation expand
  if (exp is RecordModel) return [exp];

  return const [];
}

/// ✅ FULL mapper: use for details view (your old logic, but safer)
DeliveryDataModel _processDeliveryDataRecordFull(RecordModel record) {
  // ---------------- Customer ----------------
  CustomerDataModel? customerModel;
  final customerRecord = _firstExpanded(record, 'customer');
  if (customerRecord != null) {
    customerModel = CustomerDataModel.fromJson({
      'id': customerRecord.id,
      'collectionId': customerRecord.collectionId,
      'collectionName': customerRecord.collectionName,
      'refId': customerRecord.data['refID'],
      ...customerRecord.data,
    });
  } else if (record.data['customer'] != null) {
    customerModel = CustomerDataModel(id: record.data['customer'].toString());
  }

  // ---------------- Invoice (single) ----------------
  InvoiceDataModel? invoiceModel;
  final invoiceRecord = _firstExpanded(record, 'invoice');
  if (invoiceRecord != null) {
    invoiceModel = InvoiceDataModel.fromJson({
      'id': invoiceRecord.id,
      'collectionId': invoiceRecord.collectionId,
      'collectionName': invoiceRecord.collectionName,
      ...invoiceRecord.data,
    });
  } else if (record.data['invoice'] != null) {
    invoiceModel = InvoiceDataModel(id: record.data['invoice'].toString());
  }

  // ---------------- Trip (single) ----------------
  TripModel? tripModel;
  final tripRecord = _firstExpanded(record, 'trip');
  if (tripRecord != null) {
    tripModel = TripModel.fromJson({
      'id': tripRecord.id,
      'collectionId': tripRecord.collectionId,
      'collectionName': tripRecord.collectionName,

      // keep your custom mapped fields (if your TripModel expects them)
      'tripNumberId': tripRecord.data['tripNumberId'],
      'qrCode': tripRecord.data['qrCode'],
      'isAccepted': tripRecord.data['isAccepted'],
      'isEndTrip': tripRecord.data['isEndTrip'],
      'user': tripRecord.data['user'],

      ...tripRecord.data,
    });
  } else if (record.data['trip'] != null) {
    tripModel = TripModel(id: record.data['trip'].toString());
  }

  // ---------------- Delivery Updates (many) ----------------
  List<DeliveryUpdateModel> deliveryUpdatesList = [];
  final deliveryUpdateRecords = _listExpanded(record, 'deliveryUpdates');
  if (deliveryUpdateRecords.isNotEmpty) {
    deliveryUpdatesList = deliveryUpdateRecords.map((update) {
      return DeliveryUpdateModel.fromJson({
        'id': update.id,
        'collectionId': update.collectionId,
        'collectionName': update.collectionName,
        'title': update.data['title'],
        'subtitle': update.data['subtitle'],
        'time': update.data['time'],
        'remarks': update.data['remarks'],
        'customer': update.data['customer'],
        'isAssigned': update.data['isAssigned'],
      });
    }).toList(growable: false);
  } else if (record.data['deliveryUpdates'] is List) {
    deliveryUpdatesList = (record.data['deliveryUpdates'] as List)
        .map((id) => DeliveryUpdateModel(id: id.toString()))
        .toList(growable: false);
  }

  // ---------------- Invoices (many) ----------------
  List<InvoiceDataModel> invoicesList = [];
  final invoicesRecords = _listExpanded(record, 'invoices');
  if (invoicesRecords.isNotEmpty) {
    invoicesList = invoicesRecords.map((invoice) {
      return InvoiceDataModel.fromJson({
        'id': invoice.id,
        'collectionId': invoice.collectionId,
        'collectionName': invoice.collectionName,
        ...invoice.data,
        'expand': invoice.expand,
      });
    }).toList(growable: false);
  } else if (record.data['invoices'] is List) {
    invoicesList = (record.data['invoices'] as List)
        .map((id) => InvoiceDataModel(id: id.toString()))
        .toList(growable: false);
  }

  // ---------------- Invoice Items (many) ----------------
  List<InvoiceItemsModel> invoiceItemsList = [];
  final invoiceItemsRecords = _listExpanded(record, 'invoiceItems');
  if (invoiceItemsRecords.isNotEmpty) {
    invoiceItemsList = invoiceItemsRecords.map((item) {
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
    }).toList(growable: false);
  } else if (record.data['invoiceItems'] is List) {
    invoiceItemsList = (record.data['invoiceItems'] as List)
        .map((id) => InvoiceItemsModel(id: id.toString()))
        .toList(growable: false);
  }

  return DeliveryDataModel(
    id: record.id,
    collectionId: record.collectionId,
    collectionName: record.collectionName,
    deliveryNumber: record.data['deliveryNumber'],
    refID: record.data['refID'],
    pinLang: record.data['pinLang'] != null
        ? double.tryParse(record.data['pinLang'].toString())
        : null,
    pinLong: record.data['pinLong'] != null
        ? double.tryParse(record.data['pinLong'].toString())
        : null,
    customer: customerModel,
    invoice: invoiceModel,
    invoices: invoicesList,
    trip: tripModel,
    invoiceItems: invoiceItemsList,
    deliveryUpdates: deliveryUpdatesList,
  );
}
}
