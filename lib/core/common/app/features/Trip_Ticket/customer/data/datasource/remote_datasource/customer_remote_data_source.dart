import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers(String tripId);
  Future<CustomerModel> getCustomerLocation(String customerId);
  Future<void> updateCustomer(CustomerModel customer);
  Future<String> calculateCustomerTotalTime(String customerId);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  const CustomerRemoteDataSourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  @override
  Future<List<CustomerModel>> getCustomers(String tripId) async {
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

      // Get customers using trip ID
      final result =
          await _pocketBaseClient.collection('customers').getFullList(
                filter: 'trip = "$actualTripId"',
                expand: 'deliveryStatus,invoices,trip',
              );

      debugPrint(
          '✅ Retrieved ${result.length} customers for trip: $actualTripId');

      List<CustomerModel> customers = [];

      for (var record in result) {
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
          'latitude': record.data['latitude'],
          'longitude': record.data['longitude'],
          'remarks': record.data['remarks'] ?? '',
          'notes': record.data['notes'] ?? '',
          'totalTime': record.data['totalTime'] ?? '',
          'trip': actualTripId,
          'hasNotes': record.data['hasNotes'] ?? false,
          'confirmedTotalPayment': double.tryParse(
              record.data['confirmedTotalPayment']?.toString() ?? '0'),
          'deliveryTeam': record.data['deliveryTeam'],
          'expand': {
            'deliveryStatus': record.expand['deliveryStatus'] ?? [],
            'invoices': record.expand['invoices'] ?? [],
          }
        };

        customers.add(CustomerModel.fromJson(mappedData));
      }

      return customers;
    } catch (e) {
      debugPrint('❌ Get Customer Remote data fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load customers by trip id: ${e.toString()}',
        statusCode: '500',
      );
    }
  }



  @override
  Future<CustomerModel> getCustomerLocation(String customerId) async {
    try {
      debugPrint('📍 Fetching data for customer: $customerId');

      // Get basic customer data first
      final record = await _pocketBaseClient.collection('customers').getOne(
            customerId,
            expand: 'deliveryStatus',
          );

      // Then get invoices separately
      final invoices =
          await _pocketBaseClient.collection('invoices').getFullList(
                filter: 'customer = "$customerId"',
                expand: 'productList',
              );

      final deliveryStatusList =
          (record.expand['deliveryStatus'] as List?)?.map((status) {
                final statusRecord = status as RecordModel;
                return DeliveryUpdateModel.fromJson({
                  'id': statusRecord.id,
                  'collectionId': statusRecord.collectionId,
                  'collectionName': statusRecord.collectionName,
                  'title': statusRecord.data['title'],
                  'subtitle': statusRecord.data['subtitle'],
                  'time': statusRecord.data['time'],
                  'customer': statusRecord.data['customer'],
                  'isAssigned': statusRecord.data['isAssigned'],
                  'created': null,
                  'updated': null
                });
              }).toList() ??
              [];

      final invoicesList = invoices
          .map((invoice) => InvoiceModel.fromJson({
                'id': invoice.id,
                'collectionId': invoice.collectionId,
                'collectionName': invoice.collectionName,
                'invoiceNumber': invoice.data['invoiceNumber'],
                'status': invoice.data['status'],
                'productList': invoice.expand['productList'] ?? [],
                'customer': invoice.data['customer'],
                'totalAmount': record.data['totalAmount'],
                'created': null,
                'updated': null
              }))
          .toList();

      return CustomerModel(
        id: record.id,
        collectionId: record.collectionId,
        collectionName: record.collectionName,
        deliveryNumber: record.data['deliveryNumber'],
        storeName: record.data['storeName'],
        ownerName: record.data['ownerName'],
        contactNumber: [record.data['contactNumber']],
        address: record.data['address'],
        municipality: record.data['municipality'],
        province: record.data['province'],
        modeOfPayment: record.data['modeOfPayment'],
        deliveryStatusList: deliveryStatusList,
        invoicesList: invoicesList,
        numberOfInvoices: invoicesList.length,
        hasNotes: record.data['hasNotes'] ?? false,
        confirmedTotalPayment: double.tryParse(
            record.data['confirmedTotalPayment']?.toString() ?? '0'),
        totalAmount:
            double.tryParse(record.data['totalAmount']?.toString() ?? '0'),
        latitude: record.data['latitude'],
        longitude: record.data['longitude'],
        remarks: record.data['remarks'],
        notes: record.data['notes'],
      );
    } catch (e) {
      debugPrint('❌ Customer Location Error fetching customer data: $e');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  // Add this implementation
  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      debugPrint('🌐 Updating customer in remote: ${customer.id}');

      await _pocketBaseClient.collection('customers').update(
        customer.id!,
        body: {
          'deliveryNumber': customer.deliveryNumber,
          'storeName': customer.storeName,
          'ownerName': customer.ownerName,
          'contactNumber': customer.contactNumber,
          'address': customer.address,
          'municipality': customer.municipality,
          'province': customer.province,
          'modeOfPayment': customer.modeOfPayment,
          'latitude': customer.latitude,
          'longitude': customer.longitude,
          'totalAmount': customer.totalAmount?.toString(),
          'remarks': customer.remarks,
          'notes': customer.notes,
        },
      );

      debugPrint('✅ Customer updated successfully in remote');
    } catch (e) {
      debugPrint('❌ Remote update failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to update customer: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<String> calculateCustomerTotalTime(String customerId) async {
    try {
      debugPrint('⏱️ Calculating total time for customer: $customerId');

      final record = await _pocketBaseClient.collection('customers').getOne(
            customerId,
            expand: 'deliveryStatus',
          );

      final deliveryUpdates = record.expand['deliveryStatus'] as List? ?? [];
      if (deliveryUpdates.isEmpty) return '0m';

      final sortedUpdates = deliveryUpdates.map((update) {
        final data = update.data;
        return DeliveryUpdateModel.fromJson({
          'id': update.id,
          'collectionId': update.collectionId,
          'collectionName': update.collectionName,
          'title': data['title'],
          'subtitle': data['subtitle'],
          'time': data['time'],
          'customer': data['customer'],
          'isAssigned': data['isAssigned'],
        });
      }).toList()
        ..sort((a, b) => a.time!.compareTo(b.time!));

      final arrivedIndex = sortedUpdates.indexWhere(
          (update) => update.title?.toLowerCase().trim() == 'arrived');

      if (arrivedIndex == -1) return '0m';

      // Check for undelivered status
      final undeliveredIndex = sortedUpdates.indexWhere((update) =>
          update.title?.toLowerCase().trim() == 'mark as undelivered');

      // Get end delivery status
      final endDeliveryIndex = sortedUpdates.indexWhere(
          (update) => update.title?.toLowerCase().trim() == 'end delivery');

      // Determine relevant updates based on delivery scenario
      List<DeliveryUpdateModel> relevantUpdates;
      if (undeliveredIndex != -1) {
        // Undelivered scenario - calculate until mark as undelivered
        relevantUpdates =
            sortedUpdates.sublist(arrivedIndex, undeliveredIndex + 1);
      } else if (endDeliveryIndex != -1) {
        // Normal delivery - include end delivery
        relevantUpdates =
            sortedUpdates.sublist(arrivedIndex, endDeliveryIndex + 1);
      } else {
        // Fallback to all updates from arrived
        relevantUpdates = sortedUpdates.sublist(arrivedIndex);
      }

      int totalSeconds = 0;
      for (int i = 0; i < relevantUpdates.length - 1; i++) {
        final currentTime = relevantUpdates[i].time!;
        final nextTime = relevantUpdates[i + 1].time!;
        final diffInSeconds = nextTime.difference(currentTime).inSeconds;
        totalSeconds += diffInSeconds;

        debugPrint(
            'Status: ${relevantUpdates[i].title} -> ${relevantUpdates[i + 1].title}');
        debugPrint(
            'Time: ${_formatTime(currentTime)} -> ${_formatTime(nextTime)}');
        debugPrint(
            'Difference: ${diffInSeconds ~/ 60} minutes ${diffInSeconds % 60} seconds\n');
      }

      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final seconds = totalSeconds % 60;

      String totalTime;
      if (hours > 0) {
        totalTime = '${hours}h ${minutes}m ${seconds}s';
      } else if (minutes > 0) {
        totalTime = '${minutes}m ${seconds}s';
      } else {
        totalTime = '${seconds}s';
      }

      await _pocketBaseClient.collection('customers').update(
        customerId,
        body: {'totalTime': totalTime},
      );

      debugPrint(
          '✅ Total accumulated time: $totalTime ($totalSeconds seconds)');
      return totalTime;
    } catch (e) {
      debugPrint('❌ Failed to calculate total time: $e');
      throw ServerException(message: e.toString(), statusCode: '404');
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
