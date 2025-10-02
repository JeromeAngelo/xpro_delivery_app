
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart' show PocketBase, RecordModel;
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class CollectionRemoteDataSource {
  /// Load collections by trip ID from remote
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId);

  /// Load collection by ID from remote
  Future<CollectionModel> getCollectionById(String collectionId);

  /// Delete collection from remote
  Future<bool> deleteCollection(String collectionId);
}

class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  const CollectionRemoteDataSourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId) async {
    try {
      // Extract trip ID if we received a JSON object
      // String actualTripId;
      // if (tripId.startsWith('{')) {
      //   final tripData = jsonDecode(tripId);
      //   actualTripId = tripData['id'];
      // } else {
      //   actualTripId = tripId;
      // }

      // debugPrint('🔄 Fetching collections for trip ID: $actualTripId');

      // // If actualTripId looks like a tripNumberId (starts with TRIP-), 
      // // we need to find the actual PocketBase record ID
      // String pocketBaseTripId = actualTripId;
      
      // if (actualTripId.startsWith('TRIP-')) {
      //   debugPrint('🔍 Trip ID appears to be tripNumberId, finding PocketBase record ID...');
      //   try {
      //     final tripResults = await _pocketBaseClient.collection('tripticket').getFullList(
      //       filter: 'id = "$actualTripId"',
      //     );
          
      //     if (tripResults.isNotEmpty) {
      //       pocketBaseTripId = tripResults.first.id;
      //       debugPrint('✅ Found PocketBase trip ID: $pocketBaseTripId for tripNumberId: $actualTripId');
      //     } else {
      //       debugPrint('⚠️ No trip found with tripNumberId: $actualTripId');
      //     }
      //   } catch (e) {
      //     debugPrint('⚠️ Failed to resolve tripNumberId: $e');
      //   }
      // }

      final records = await _pocketBaseClient
          .collection('deliveryCollection')
          .getFullList(
            filter: 'trip = "$tripId"',
            expand: 'deliveryData,trip,customer,invoice,invoices,invoices.products,invoices.customer',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} collections from API');

      List<CollectionModel> collections = [];

      for (var record in records) {
        collections.add(_processCollectionRecord(record));
      }

      debugPrint('✨ Successfully processed ${collections.length} collections');
      return collections;
    } catch (e) {
      debugPrint('❌ Collections fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load collections: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<CollectionModel> getCollectionById(String collectionId) async {
    try {
      debugPrint('🔄 Fetching collection by ID: $collectionId');

      final record = await _pocketBaseClient
          .collection('deliveryCollection')
          .getOne(
            collectionId,
            expand: 'deliveryData,trip,customer,invoice,invoices,invoices.products,invoices.customer',
          );

      debugPrint('✅ Retrieved collection from API: ${record.id}');

      return _processCollectionRecord(record);
    } catch (e) {
      debugPrint('❌ Collection fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load collection: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteCollection(String collectionId) async {
    try {
      debugPrint('🔄 Deleting collection: $collectionId');

      await _pocketBaseClient
          .collection('deliveryCollection')
          .delete(collectionId);

      debugPrint('✅ Successfully deleted collection: $collectionId');
      return true;
    } catch (e) {
      debugPrint('❌ Collection deletion failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete collection: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // Helper method to process a collection record - matching delivery_data pattern
  CollectionModel _processCollectionRecord(RecordModel record) {
    debugPrint('🔄 Processing collection record: ${record.id}');
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
      deliveryDataModel = DeliveryDataModel(id: record.data['deliveryData'].toString());
      debugPrint('📋 Using delivery data ID reference: ${deliveryDataModel.id}');
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
        debugPrint('✅ Processed trip: ${tripModel.id} - ${tripModel.tripNumberId}');
      }
    } else if (record.data['trip'] != null) {
      tripModel = TripModel(id: record.data['trip'].toString());
      debugPrint('📋 Using trip ID reference: ${tripModel.id}');
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
        debugPrint('✅ Processed customer: ${customerModel.id} - ${customerModel.name}');
      }
    } else if (record.data['customer'] != null) {
      customerModel = CustomerDataModel(id: record.data['customer'].toString());
      debugPrint('📋 Using customer ID reference: ${customerModel.id}');
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
        debugPrint('✅ Processed invoice: ${invoiceModel.id} - Amount: ${invoiceModel.totalAmount}');
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
        debugPrint('✅ Processed ${invoicesList.length} invoices for collection');
      }
    } else if (record.data['invoices'] != null && record.data['invoices'] is List) {
      invoicesList = (record.data['invoices'] as List)
          .map((id) => InvoiceDataModel(id: id.toString()))
          .toList();
      debugPrint('📋 Using ${invoicesList.length} invoice ID references');
    }

    // Parse totalAmount with fallback to invoice amount
    double? totalAmount;
    if (record.data['totalAmount'] != null) {
      if (record.data['totalAmount'] is double) {
        totalAmount = record.data['totalAmount'];
      } else if (record.data['totalAmount'] is int) {
        totalAmount = (record.data['totalAmount'] as int).toDouble();
      } else if (record.data['totalAmount'] is String) {
        totalAmount = double.tryParse(record.data['totalAmount']);
      }
    }

    // Fallback to invoice totalAmount if collection amount is null/0
    if ((totalAmount == null || totalAmount == 0) && invoiceModel?.totalAmount != null) {
      totalAmount = invoiceModel!.totalAmount;
      debugPrint('🔄 Using invoice totalAmount as fallback: $totalAmount');
    }

    debugPrint('💰 Final totalAmount for collection ${record.id}: $totalAmount');

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

    final collection = CollectionModel(
      id: record.id,
      collectionId: record.collectionId,
      collectionName: record.collectionName,
      totalAmount: totalAmount,
      deliveryData: deliveryDataModel,
      trip: tripModel,
      customer: customerModel,
      invoice: invoiceModel,
      invoices: invoicesList,
      created: parseDate(record.created),
      updated: parseDate(record.updated),
    );

    debugPrint('✅ Successfully processed collection: ${collection.id}');
    // debugPrint('📊 Collection summary:');
    // debugPrint('   - ID: ${collection.id}');
    // debugPrint('   - Total Amount: ${collection.totalAmount}');
    // debugPrint('   - Customer: ${collection.customer.target!.name ?? "null"}');
    // debugPrint('   - Invoice: ${collection.invoice.target!.id ?? "null"}');
    // debugPrint('   - Trip: ${collection.trip.target!.tripNumberId ?? "null"}');

    return collection;
  }
}
