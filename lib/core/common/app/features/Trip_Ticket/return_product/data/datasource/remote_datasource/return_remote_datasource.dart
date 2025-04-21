import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
abstract class ReturnRemoteDatasource {
  Future<List<ReturnModel>> getReturns(String tripId);
  Future<ReturnModel> getReturnByCustomerId(String customerId);
}

class ReturnRemoteDatasourceImpl implements ReturnRemoteDatasource {
  const ReturnRemoteDatasourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
@override
Future<List<ReturnModel>> getReturns(String tripId) async {
  try {
    // Extract trip ID if we received a JSON object
    String actualTripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      actualTripId = tripData['id'];
    } else {
      actualTripId = tripId;
    }
    
    debugPrint('🎯 Using trip ID: $actualTripId');

    final records = await _pocketBaseClient.collection('returns').getFullList(
      filter: 'trip = "$actualTripId"',
      expand: 'invoice,customer,trip',
    );

    debugPrint('✅ Retrieved ${records.length} returns from API');

    return records.map((record) {
      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'productName': record.data['productName']?.toString(),
        'productDescription': record.data['productDescription']?.toString(),
        'productQuantityCase': int.tryParse(record.data['productQuantityCase']?.toString() ?? '0'),
        'productQuantityPcs': int.tryParse(record.data['productQuantityPcs']?.toString() ?? '0'),
        'productQuantityPack': int.tryParse(record.data['productQuantityPack']?.toString() ?? '0'),
        'productQuantityBox': int.tryParse(record.data['productQuantityBox']?.toString() ?? '0'),
        'isCase': record.data['isCase'] as bool?,
        'isPcs': record.data['isPcs'] as bool?,
        'isBox': record.data['isBox'] as bool?,
        'isPack': record.data['isPack'] as bool?,
        'reason': record.data['reason'],
        'returnDate': record.data['returnDate'],
        'trip': actualTripId,
        'expand': {
          'invoice': record.expand['invoice']?.map((invoice) => invoice.data).first,
          'customer': record.expand['customer']?.map((customer) => customer.data).first,
          'trip': record.expand['trip']?.map((trip) => trip.data).first,
        }
      };

      return ReturnModel.fromJson(mappedData);
    }).toList();

  } catch (e) {
    debugPrint('❌ Returns fetch failed: ${e.toString()}');
    throw ServerException(
      message: 'Failed to load returns: ${e.toString()}',
      statusCode: '500',
    );
  }
}

  @override
  Future<ReturnModel> getReturnByCustomerId(String customerId) async {
    try {
      debugPrint('📍 Fetching returns for customer: $customerId');
      
      final customerRecord = await _pocketBaseClient.collection('customers').getOne(
        customerId,
        expand: 'returnList,returnList.invoice,returnList.trip'
      );

      final returns = customerRecord.expand['returnList'] as List?;
      if (returns == null || returns.isEmpty) {
        throw const ServerException(
          message: 'No returns found for this customer',
          statusCode: '404',
        );
      }

      final returnRecord = returns.first as RecordModel;
      
      final invoices = returnRecord.expand['invoice'] as List?;
      final invoice = invoices?.isNotEmpty == true 
          ? InvoiceModel.fromJson({
              'id': (invoices!.first as RecordModel).id,
              'collectionId': (invoices.first as RecordModel).collectionId,
              'collectionName': (invoices.first as RecordModel).collectionName,
              ...(invoices.first as RecordModel).data,
            })
          : null;

      final customer = CustomerModel.fromJson({
        'id': customerRecord.id,
        'collectionId': customerRecord.collectionId,
        'collectionName': customerRecord.collectionName,
        ...customerRecord.data,
      });

      final trips = returnRecord.expand['trip'] as List?;
      final trip = trips?.isNotEmpty == true
          ? TripModel.fromJson({
              'id': (trips!.first as RecordModel).id,
              'collectionId': (trips.first as RecordModel).collectionId,
              'collectionName': (trips.first as RecordModel).collectionName,
              ...(trips.first as RecordModel).data,
            })
          : null;

      return ReturnModel(
        id: returnRecord.id,
        collectionId: returnRecord.collectionId,
        collectionName: returnRecord.collectionName,
        productName: returnRecord.data['productName']?.toString(),
        productDescription: returnRecord.data['productDescription']?.toString(),
        productQuantityCase: int.tryParse(returnRecord.data['productQuantityCase']?.toString() ?? '0'),
        productQuantityPcs: int.tryParse(returnRecord.data['productQuantityPcs']?.toString() ?? '0'),
        productQuantityPack: int.tryParse(returnRecord.data['productQuantityPack']?.toString() ?? '0'),
        productQuantityBox: int.tryParse(returnRecord.data['productQuantityBox']?.toString() ?? '0'),
        isCase: returnRecord.data['isCase'] as bool?,
        isPcs: returnRecord.data['isPcs'] as bool?,
        isBox: returnRecord.data['isBox'] as bool?,
        isPack: returnRecord.data['isPack'] as bool?,
        reason: returnRecord.data['reason'] != null 
            ? ProductReturnReason.values.firstWhere(
                (r) => r.toString() == returnRecord.data['reason'],
                orElse: () => ProductReturnReason.damaged,
              )
            : null,
        returnDate: DateTime.tryParse(returnRecord.data['returnDate']?.toString() ?? ''),
        invoice: invoice,
        customer: customer,
        trip: trip,
      );
    } catch (e) {
      debugPrint('❌ Error fetching return: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch return: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
