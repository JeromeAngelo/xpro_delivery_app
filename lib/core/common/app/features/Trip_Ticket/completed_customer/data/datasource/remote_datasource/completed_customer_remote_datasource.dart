import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/models/completed_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';


abstract class CompletedCustomerRemoteDatasource {
  Future<List<CompletedCustomerModel>> getCompletedCustomers(String tripId);
  Future<CompletedCustomerModel> getCompletedCustomerById(String customerId);
}

class CompletedCustomerRemoteDatasourceImpl
    implements CompletedCustomerRemoteDatasource {
  const CompletedCustomerRemoteDatasourceImpl(
      {required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  
  @override
  Future<List<CompletedCustomerModel>> getCompletedCustomers(
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

      debugPrint('🎯 Using trip ID: $actualTripId');

      final records = await _pocketBaseClient
          .collection('completedCustomer')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'deliveryStatus,invoices,transaction,returns,customer,trip',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} completed customers from API');

      return records.map((record) {
        final mappedData = {
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          'deliveryNumber': record.data['deliveryNumber'] ?? '',
          'storeName': record.data['storeName'] ?? '',
          'ownerName': record.data['ownerName'] ?? '',
          'contactNumber': record.data['contactNumber'] ?? '',
          'address': record.data['address'] ?? '',
          'municipality': record.data['municipality'] ?? '',
          'province': record.data['province'] ?? '',
          'modeOfPayment': record.data['modeOfPayment'] ?? '',
          'timeCompleted': record.data['timeCompleted'],
          'totalAmount': record.data['totalAmount'],
          'trip': actualTripId,
          'expand': {
            'deliveryStatus':
                record.expand['deliveryStatus']
                    ?.map((status) => status.data)
                    .toList(),
            'invoices':
                record.expand['invoices']
                    ?.map((invoice) => invoice.data)
                    .toList(),
            'transaction':
                record.expand['transaction']
                    ?.map((transaction) => transaction.data)
                    .first,
            'returns':
                record.expand['returns']
                    ?.map((returnItem) => returnItem.data)
                    .toList(),
            'customer':
                record.expand['customer']
                    ?.map((customer) => customer.data)
                    .first,
            'trip': record.expand['trip']?.map((trip) => trip.data).first,
          },
        };
        return CompletedCustomerModel.fromJson(mappedData);
      }).toList();
    } catch (e) {
      debugPrint(
        '❌ Get Completed Customer Remote data fetch failed: ${e.toString()}',
      );
      throw ServerException(
        message: 'Failed to load completed customers: ${e.toString()}',
        statusCode: '500',
      );
    }
  }


  @override
Future<CompletedCustomerModel> getCompletedCustomerById(String customerId) async {
  try {
    debugPrint('📍 Fetching data for completed customer: $customerId');

    final record = await _pocketBaseClient.collection('completedCustomer').getOne(
      customerId,
      expand: 'deliveryStatus',
    );

    final invoices = await _pocketBaseClient.collection('invoices').getFullList(
      filter: 'customer = "$customerId"',
      expand: 'productList',
    );

    final deliveryStatusList = (record.expand['deliveryStatus'] as List?)?.map((status) {
      final statusRecord = status as RecordModel;
      return DeliveryUpdateModel.fromJson({
        'id': statusRecord.id,
        'collectionId': statusRecord.collectionId,
        'collectionName': statusRecord.collectionName,
        'title': statusRecord.data['title'] ?? '',
        'subtitle': statusRecord.data['subtitle'] ?? '',
        'time': statusRecord.data['time'] ?? '',
        'customer': statusRecord.data['customer'] ?? '',
        'isAssigned': statusRecord.data['isAssigned'] ?? false,
        'created': statusRecord.created.toString(),
        'updated': statusRecord.updated.toString()
      });
    }).toList() ?? [];

    final invoicesList = invoices.map((invoice) => InvoiceModel.fromJson({
      'id': invoice.id,
      'collectionId': invoice.collectionId,
      'collectionName': invoice.collectionName,
      'invoiceNumber': invoice.data['invoiceNumber'] ?? '',
      'status': invoice.data['status'] ?? '',
      'productList': invoice.expand['productList'] ?? [],
      'customer': invoice.data['customer'] ?? '',
      'totalAmount': record.data['totalAmount'] ?? '0',
      'created': invoice.created.toString(),
      'updated': invoice.updated.toString()
    })).toList();

    return CompletedCustomerModel(
      id: record.id,
      collectionId: record.collectionId,
      collectionName: record.collectionName,
      deliveryNumber: record.data['deliveryNumber'] ?? '',
      storeName: record.data['storeName'] ?? '',
      ownerName: record.data['ownerName'] ?? '',
      contactNumber: [record.data['contactNumber'] ?? ''],
      address: record.data['address'] ?? '',
      municipality: record.data['municipality'] ?? '',
      province: record.data['province'] ?? '',
      modeOfPayment: record.data['modeOfPayment'] ?? '',
      deliveryStatusList: deliveryStatusList,
      invoicesList: invoicesList,
      timeCompleted: DateTime.tryParse(record.data['timeCompleted'] ?? ''),
      totalAmount: double.tryParse(record.data['totalAmount']?.toString() ?? '0'),
    );

  } catch (e) {
    debugPrint('❌ Error fetching completed customer: ${e.toString()}');
    throw ServerException(
      message: 'Failed to fetch completed customer: ${e.toString()}',
      statusCode: '500',
    );
  }
}

}
