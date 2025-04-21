import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/model/undeliverable_customer_model.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class UndeliverableCustomerRemoteDataSource {
  Future<List<UndeliverableCustomerModel>> getUndeliverableCustomers(
      String tripId);
  Future<UndeliverableCustomerModel> createUndeliverableCustomer(
      UndeliverableCustomerModel undeliverableCustomer, String customerId);
  Future<void> saveUndeliverableCustomer(
      UndeliverableCustomerModel undeliverableCustomer, String customerId);
  Future<void> updateUndeliverableCustomer(
      UndeliverableCustomerModel undeliverableCustomer, String tripId);
  Future<void> deleteUndeliverableCustomer(String undeliverableCustomerId);
  Future<void> setUndeliverableReason(
      String customerId, UndeliverableReason reason);
  Future<UndeliverableCustomerModel> getUndeliverableCustomerById(
      String customerId);
}

class UndeliverableCustomerRemoteDataSourceImpl
    implements UndeliverableCustomerRemoteDataSource {
  const UndeliverableCustomerRemoteDataSourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  @override
  Future<List<UndeliverableCustomerModel>> getUndeliverableCustomers(
      String tripId) async {
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
          .collection('undeliverable_customers')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'customer,invoices,trip',
          );

      debugPrint(
          '✅ Retrieved ${records.length} undeliverable customers from API');

      return records.map((record) {
        final customerData = record.expand['customer']?[0];
        final customer = customerData != null
            ? CustomerModel(
                id: customerData.id,
                collectionId: customerData.collectionId,
                collectionName: customerData.collectionName,
                storeName: customerData.data['storeName'],
                ownerName: customerData.data['ownerName'],
                contactNumber: [customerData.data['contactNumber']],
                address: customerData.data['address'],
                municipality: customerData.data['municipality'],
                province: customerData.data['province'],
                modeOfPayment: customerData.data['modeOfPayment'],
              )
            : null;

        final invoicesList =
            (record.expand['invoices'] as List?)?.map((invoice) {
                  final invoiceRecord = invoice as RecordModel;
                  return InvoiceModel.fromJson({
                    'id': invoiceRecord.id,
                    'collectionId': invoiceRecord.collectionId,
                    'collectionName': invoiceRecord.collectionName,
                    'invoiceNumber': invoiceRecord.data['invoiceNumber'],
                    'status': invoiceRecord.data['status'],
                    'customer': invoiceRecord.data['customer'],
                    'created': invoiceRecord.created,
                    'updated': invoiceRecord.updated,
                  });
                }).toList() ??
                [];

        return UndeliverableCustomerModel(
          id: record.id,
          collectionId: record.collectionId,
          collectionName: record.collectionName,
          reason: record.data['reason'] != null
              ? UndeliverableReason.values.firstWhere(
                  (r) => r.toString().split('.').last == record.data['reason'],
                  orElse: () => UndeliverableReason.none,
                )
              : UndeliverableReason.none,
          time: DateTime.tryParse(record.data['time'] ?? ''),
          customer: customer,
          invoicesList: invoicesList,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Remote data fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load undeliverable customers: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<UndeliverableCustomerModel> getUndeliverableCustomerById(
      String customerId) async {
    try {
      debugPrint('📍 Fetching data for undeliverable customer: $customerId');

      final record = await _pocketBaseClient
          .collection('undeliverable_customers')
          .getOne(customerId, expand: 'customer,invoices,trip');

      // Map customer data
      final customerData = record.expand['customer']?[0];
      final customer = customerData != null
          ? CustomerModel(
              id: customerData.id,
              collectionId: customerData.collectionId,
              collectionName: customerData.collectionName,
              storeName: customerData.data['storeName'],
              ownerName: customerData.data['ownerName'],
              contactNumber: [customerData.data['contactNumber']],
              address: customerData.data['address'],
              municipality: customerData.data['municipality'],
              province: customerData.data['province'],
              modeOfPayment: customerData.data['modeOfPayment'],
            )
          : null;

      // Map invoices
      final invoicesList = (record.expand['invoices'] as List?)?.map((invoice) {
            final invoiceRecord = invoice as RecordModel;
            return InvoiceModel.fromJson({
              'id': invoiceRecord.id,
              'collectionId': invoiceRecord.collectionId,
              'collectionName': invoiceRecord.collectionName,
              'invoiceNumber': invoiceRecord.data['invoiceNumber'],
              'status': invoiceRecord.data['status'],
              'customer': invoiceRecord.data['customer'],
              'created': invoiceRecord.created,
              'updated': invoiceRecord.updated
            });
          }).toList() ??
          [];

      return UndeliverableCustomerModel(
        id: record.id,
        collectionId: record.collectionId,
        collectionName: record.collectionName,
        reason: record.data['reason'] != null
            ? UndeliverableReason.values.firstWhere(
                (r) => r.toString().split('.').last == record.data['reason'],
                orElse: () => UndeliverableReason.none,
              )
            : UndeliverableReason.none,
        time: DateTime.tryParse(record.data['time'] ?? ''),
        customer: customer,
        invoicesList: invoicesList,
      );
    } catch (e) {
      debugPrint('❌ Error fetching undeliverable customer: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch undeliverable customer: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<UndeliverableCustomerModel> createUndeliverableCustomer(
      UndeliverableCustomerModel undeliverableCustomer,
      String customerId) async {
    try {
      debugPrint(
          '🔄 Creating undeliverable customer record for ID: $customerId');

      final customerRecord =
          await _pocketBaseClient.collection('customers').getOne(
                customerId,
                expand: 'trip,invoices(customer)',
              );

      final tripId = customerRecord.expand['trip']?[0].id;
      debugPrint('🚚 Found assigned trip ID: $tripId');

      final invoiceIds = customerRecord.expand['invoices(customer)']
              ?.map((inv) => inv.id)
              .toList() ??
          [];

      debugPrint('📝 Invoice IDs: $invoiceIds');

      final currentTime = DateTime.now().toUtc().toIso8601String();

      final body = {
        'customer': customerId,
        'invoices': invoiceIds,
        'reason': undeliverableCustomer.reason?.toString().split('.').last,
        'time': currentTime,
        'trip': tripId,
        'transactionDate': currentTime,
        'created': currentTime,
        'updated': currentTime,
      };

      debugPrint('📝 Creating record with body: $body');

      final files = <String, MultipartFile>{};

      if (undeliverableCustomer.customerImage != null) {
        final imagePaths = undeliverableCustomer.customerImage!.split(',');
        for (var i = 0; i < imagePaths.length; i++) {
          final imageBytes = await File(imagePaths[i]).readAsBytes();
          files['customerImage'] = MultipartFile.fromBytes(
            'customerImage',
            imageBytes,
            filename: 'customer_image_$i.jpg',
          );
        }
      }
// After creating undeliverable customer record
      final record =
          await _pocketBaseClient.collection('undeliverable_customers').create(
                body: body,
                files: files.values.toList(),
              );

// Update tripticket with undelivered customer reference
      await _pocketBaseClient.collection('tripticket').update(
        tripId!,
        body: {
          'undeliveredCustomer': record.id,
        },
      );
      debugPrint(
          '✅ Updated tripticket with undelivered customer ID: ${record.id}');

// Update delivery team statistics
      final deliveryTeamRecords = await _pocketBaseClient
          .collection('delivery_team')
          .getList(filter: 'tripTicket = "$tripId"');

      if (deliveryTeamRecords.items.isNotEmpty) {
        final deliveryTeamRecord = deliveryTeamRecords.items.first;
        debugPrint('✅ Found delivery team: ${deliveryTeamRecord.id}');

        final currentUndelivered = int.tryParse(
                deliveryTeamRecord.data['undeliveredCustomers']?.toString() ??
                    '') ??
            0;
        final currentActive = int.tryParse(
                deliveryTeamRecord.data['activeDeliveries']?.toString() ??
                    '') ??
            0;

        await _pocketBaseClient.collection('delivery_team').update(
          deliveryTeamRecord.id,
          body: {
            'undeliveredCustomers': (currentUndelivered + 1).toString(),
            'activeDeliveries': (currentActive - 1).toString(),
          },
        );

        debugPrint('✅ Delivery team stats updated successfully');
      }

      debugPrint(
          '✅ Undeliverable customer created and team stats updated successfully');
      return UndeliverableCustomerModel.fromJson(record.toJson());
    } catch (e) {
      debugPrint('❌ Failed to create undeliverable customer: $e');
      throw ServerException(
        message: 'Failed to create undeliverable customer: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> saveUndeliverableCustomer(
      UndeliverableCustomerModel undeliverableCustomer,
      String customerId) async {
    try {
      debugPrint('🔄 Saving undeliverable customer for ID: $customerId');

      final customerRecord =
          await _pocketBaseClient.collection('customers').getOne(
                customerId,
                expand: 'trip,invoices(customer)',
              );

      final tripId = customerRecord.expand['trip']?[0].id;
      debugPrint('🚚 Found assigned trip ID: $tripId');

      await _pocketBaseClient.collection('undeliverable_customers').create(
        body: {
          ...undeliverableCustomer.toJson(),
          'customer': customerId,
          'trip': tripId,
        },
      );

      debugPrint('✅ Undeliverable customer saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save undeliverable customer: ${e.toString()}');
      throw ServerException(
        message: 'Failed to save undeliverable customer: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> updateUndeliverableCustomer(
      UndeliverableCustomerModel undeliverableCustomer, String tripId) async {
    try {
      debugPrint('🔄 Updating undeliverable customer for trip: $tripId');

      await _pocketBaseClient.collection('undeliverable_customers').update(
        undeliverableCustomer.id!,
        body: {
          ...undeliverableCustomer.toJson(),
          'trip': tripId,
          'updated': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Undeliverable customer updated successfully');
    } catch (e) {
      debugPrint('❌ Failed to update undeliverable customer: ${e.toString()}');
      throw ServerException(
        message: 'Failed to update undeliverable customer: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> deleteUndeliverableCustomer(
      String undeliverableCustomerId) async {
    try {
      debugPrint('🔄 Deleting undeliverable customer');

      await _pocketBaseClient.collection('undeliverable_customers').delete(
            undeliverableCustomerId,
          );

      debugPrint('✅ Undeliverable customer deleted successfully');
    } catch (e) {
      debugPrint('❌ Failed to delete undeliverable customer: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete undeliverable customer: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> setUndeliverableReason(
      String customerId, UndeliverableReason reason) async {
    try {
      debugPrint('🔄 Setting undeliverable reason for customer: $customerId');

      await _pocketBaseClient.collection('undeliverable_customers').update(
        customerId,
        body: {
          'reason': reason.toString().split('.').last,
          'updated': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Undeliverable reason updated successfully');
    } catch (e) {
      debugPrint('❌ Failed to set undeliverable reason: ${e.toString()}');
      throw ServerException(
        message: 'Failed to set undeliverable reason: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
