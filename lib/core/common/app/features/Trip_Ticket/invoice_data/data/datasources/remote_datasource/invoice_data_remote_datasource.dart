import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';

abstract class InvoiceDataRemoteDataSource {
  // Get all invoice data
  Future<List<InvoiceDataModel>> getAllInvoiceData();

  // Get invoice data by ID
  Future<InvoiceDataModel> getInvoiceDataById(String id);

  Future<List<InvoiceDataModel>> getInvoiceDataByCustomerId(String customerId);

  // Get invoice data by delivery ID
  Future<List<InvoiceDataModel>> getInvoiceDataByDeliveryId(String deliveryId);

  // Add invoice data to delivery
  Future<bool> addInvoiceDataToDelivery({
    required String invoiceId,
    required String deliveryId,
  });

  // Add invoice data to invoice status
  Future<bool> addInvoiceDataToInvoiceStatus({
    required String invoiceId,
    required String invoiceStatusId,
  });
}

class InvoiceDataRemoteDataSourceImpl implements InvoiceDataRemoteDataSource {
  const InvoiceDataRemoteDataSourceImpl({required PocketBase pocketBaseClient})
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
@override
Future<List<InvoiceDataModel>> getAllInvoiceData() async {
  try {
    debugPrint('🔄 Fetching all invoice data');

    await _ensureAuthenticated();

    const int pageSize = 200; // tune: 100–500
    int page = 1;

    final List<InvoiceDataModel> all = [];

    while (true) {
      final res = await _pocketBaseClient.collection('invoiceData').getList(
            page: page,
            perPage: pageSize,
            sort: '-created',
            expand: 'customer',
          );

      final items = res.items;
      if (items.isEmpty) break;

      all.addAll(items.map(_invoiceFromRecordFast));
      if (items.length < pageSize) break;

      page++;
    }

    debugPrint('✅ Retrieved ${all.length} invoice data records');
    return all;
  } catch (e) {
    debugPrint('❌ Failed to fetch all invoice data: $e');
    throw ServerException(
      message: 'Failed to load invoice data: $e',
      statusCode: '500',
    );
  }
}

// Faster mapping (no intermediate Map allocation per field)
InvoiceDataModel _invoiceFromRecordFast(RecordModel record) {
  return InvoiceDataModel.fromJson({
    'id': record.id,
    'collectionId': record.collectionId,
    'collectionName': record.collectionName,
    'refId': record.data['refID'] ?? '',
    'name': record.data['name'] ?? '',
    'documentDate': record.data['documentDate'],
    'totalAmount': record.data['totalAmount'],
    'volume': record.data['volume'],
    'weight': record.data['weight'],
    'expand': {'customer': record.expand['customer']},
  });
}


  @override
  Future<InvoiceDataModel> getInvoiceDataById(String id) async {
    try {
      debugPrint('🔄 Fetching invoice data by ID: $id');

      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      final record = await _pocketBaseClient
          .collection('invoiceData')
          .getOne(id, expand: 'customer');

      debugPrint('✅ Retrieved invoice data: ${record.id}');

      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'refId': record.data['refID'] ?? '',
        'name': record.data['name'] ?? '',
        'documentDate': record.data['documentDate'],
        'totalAmount': record.data['totalAmount'],
        'volume': record.data['volume'],
        'weight': record.data['weight'],

        'expand': {'customer': record.expand['customer']},
      };

      return InvoiceDataModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Failed to fetch invoice data by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load invoice data by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<InvoiceDataModel>> getInvoiceDataByDeliveryId(
    String deliveryId,
  ) async {
    try {
      debugPrint('🔄 Fetching invoice data for delivery: $deliveryId');

      // Validate deliveryId parameter
      if (deliveryId.isEmpty) {
        debugPrint('❌ Invalid deliveryId: deliveryId is empty');
        throw const ServerException(
          message: 'Delivery ID cannot be empty',
          statusCode: '400',
        );
      }

      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      // First, get the delivery data to find the invoices
      final deliveryData = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryId, expand: 'invoice,customer');

      // Check if there are invoices in the delivery data
      if (deliveryData.expand.containsKey('invoice') &&
          deliveryData.expand['invoice'] != null) {
        final invoicesData = deliveryData.expand['invoice'] as List;
        List<InvoiceDataModel> invoicesList = [];

        for (var invoiceRecord in invoicesData) {
          if (invoiceRecord is RecordModel) {
            // Get the full invoice record with customer expansion to ensure we have customer data
            final fullInvoiceRecord = await _pocketBaseClient
                .collection('invoiceData')
                .getOne(invoiceRecord.id, expand: 'customer');

            final mappedData = {
              'id': fullInvoiceRecord.id,
              'collectionId': fullInvoiceRecord.collectionId,
              'collectionName': fullInvoiceRecord.collectionName,
              'refId': fullInvoiceRecord.data['refID'] ?? '',
              'name': fullInvoiceRecord.data['name'] ?? '',
              'documentDate': fullInvoiceRecord.data['documentDate'],
              'totalAmount': fullInvoiceRecord.data['totalAmount'],
              'volume': fullInvoiceRecord.data['volume'],
              'weight': fullInvoiceRecord.data['weight'],

              'expand': {'customer': fullInvoiceRecord.expand['customer']},
            };

            invoicesList.add(InvoiceDataModel.fromJson(mappedData));
          }
        }

        debugPrint('✅ Retrieved ${invoicesList.length} invoices for delivery');
        return invoicesList;
      }

      debugPrint('⚠️ No invoices found for delivery: $deliveryId');
      return [];
    } catch (e) {
      debugPrint(
        '❌ Failed to fetch invoice data by delivery ID: ${e.toString()}',
      );
      throw ServerException(
        message: 'Failed to load invoice data by delivery ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<InvoiceDataModel>> getInvoiceDataByCustomerId(
    String customerId,
  ) async {
    try {
      debugPrint('🔄 Fetching invoice data for customer: $customerId');

      final result = await _pocketBaseClient
          .collection('invoiceData')
          .getFullList(
            expand: 'customer',
            filter: 'customer = "$customerId"',
            sort: '-created',
          );

      debugPrint(
        '✅ Retrieved ${result.length} invoice data records for customer',
      );

      List<InvoiceDataModel> invoiceDataList = [];

      for (var record in result) {
        final mappedData = {
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          'refId': record.data['refID'] ?? '',
          'name': record.data['name'] ?? '',
          'documentDate': record.data['documentDate'],
          'totalAmount': record.data['totalAmount'],
          'volume': record.data['volume'],
          'weight': record.data['weight'],

          'expand': {'customer': record.expand['customer']},
        };

        invoiceDataList.add(InvoiceDataModel.fromJson(mappedData));
      }

      return invoiceDataList;
    } catch (e) {
      debugPrint(
        '❌ Failed to fetch invoice data by customer ID: ${e.toString()}',
      );
      throw ServerException(
        message: 'Failed to load invoice data by customer ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> addInvoiceDataToDelivery({
    required String invoiceId,
    required String deliveryId,
  }) async {
    try {
      debugPrint('🔄 Adding invoice $invoiceId to delivery $deliveryId');

      // Step 1: Get the invoice data to check its customer
      final invoiceData = await _pocketBaseClient
          .collection('invoiceData')
          .getOne(invoiceId, expand: 'customer');

      final customerId = invoiceData.data['customer']?.toString();

      if (customerId == null || customerId.isEmpty) {
        debugPrint(
          '⚠️ Invoice $invoiceId has no customer, cannot add to delivery',
        );
        throw ServerException(
          message: 'Invoice has no associated customer',
          statusCode: '400',
        );
      }

      // Check if deliveryId is empty - if so, create a new delivery
      if (deliveryId.isEmpty) {
        debugPrint('📝 Creating new delivery for invoice $invoiceId');

        // Create a base delivery data template
        final baseDeliveryData = {
          'status': 'pending',
          'created': DateTime.now().toIso8601String(),
          'updated': DateTime.now().toIso8601String(),
          'invoice': [invoiceId], // Start with this invoice
          'customer': customerId, // Set the customer from the invoice
        };

        // Create the new delivery data record
        final newDeliveryRecord = await _pocketBaseClient
            .collection('deliveryData')
            .create(body: baseDeliveryData);

        final newDeliveryId = newDeliveryRecord.id;
        debugPrint(
          '✅ Created new delivery $newDeliveryId for invoice $invoiceId',
        );

        // Update the invoice to associate it with the new delivery
        await _pocketBaseClient
            .collection('invoiceData')
            .update(
              invoiceId,
              body: {
                'deliveryData': newDeliveryId, // Link to the new delivery
                'customer': customerId, // Ensure customer is set
              },
            );

        debugPrint(
          '✅ Updated invoice $invoiceId to link to delivery $newDeliveryId',
        );

        // Create invoice status entry for this invoice
        final invoiceStatusId =
            'status_${invoiceId}_${DateTime.now().millisecondsSinceEpoch}';
        await addInvoiceDataToInvoiceStatus(
          invoiceId: invoiceId,
          invoiceStatusId: invoiceStatusId,
        );

        return true;
      } else {
        // Step 2: Get the delivery data to check its customer
        final deliveryData = await _pocketBaseClient
            .collection('deliveryData')
            .getOne(deliveryId, expand: 'invoice,customer');

        // Check if the delivery already has a customer
        final deliveryCustomerId = deliveryData.data['customer']?.toString();

        // If delivery has a customer, ensure it matches the invoice's customer
        if (deliveryCustomerId != null &&
            deliveryCustomerId.isNotEmpty &&
            deliveryCustomerId != customerId) {
          debugPrint(
            '⚠️ Customer mismatch: Invoice customer ($customerId) doesn\'t match delivery customer ($deliveryCustomerId)',
          );
          throw ServerException(
            message: 'Invoice customer doesn\'t match delivery customer',
            statusCode: '400',
          );
        }

        // Get current invoices in the delivery
        List<String> currentInvoices = [];
        if (deliveryData.data['invoice'] != null) {
          if (deliveryData.data['invoice'] is List) {
            currentInvoices =
                (deliveryData.data['invoice'] as List)
                    .map((e) => e.toString())
                    .toList();
          } else if (deliveryData.data['invoice'] is String) {
            currentInvoices = [deliveryData.data['invoice'].toString()];
          }
        }

        // Check if invoice is already in the delivery
        if (currentInvoices.contains(invoiceId)) {
          debugPrint(
            '⚠️ Invoice $invoiceId is already in delivery $deliveryId',
          );
          return true; // Already added, consider it a success
        }

        // Add the new invoice to the list
        currentInvoices.add(invoiceId);

        // Update the delivery with the new invoice and ensure customer is set
        await _pocketBaseClient
            .collection('deliveryData')
            .update(
              deliveryId,
              body: {
                'invoice': currentInvoices,
                'customer': customerId, // Set or update the customer
                'updated': DateTime.now().toIso8601String(),
              },
            );

        // Update the invoice to link it to this delivery
        await _pocketBaseClient
            .collection('invoiceData')
            .update(
              invoiceId,
              body: {
                'deliveryData': deliveryId,
                'customer': customerId, // Ensure customer is set
              },
            );

        debugPrint('✅ Added invoice $invoiceId to delivery $deliveryId');

        // Create invoice status entry for this invoice
        final invoiceStatusId =
            'status_${invoiceId}_${DateTime.now().millisecondsSinceEpoch}';
        await addInvoiceDataToInvoiceStatus(
          invoiceId: invoiceId,
          invoiceStatusId: invoiceStatusId,
        );

        return true;
      }
    } catch (e) {
      debugPrint('❌ Failed to add invoice to delivery: ${e.toString()}');
      throw ServerException(
        message: 'Failed to add invoice to delivery: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> addInvoiceDataToInvoiceStatus({
    required String invoiceId,
    String? invoiceStatusId,
  }) async {
    try {
      // Generate a fixed-length ID if not provided
      final statusId = invoiceStatusId ?? _generateFixedLengthId(15);

      debugPrint('🔄 Adding invoice $invoiceId to invoice status $statusId');

      // First, get the invoice data with expanded customer information
      final invoiceRecord = await _pocketBaseClient
          .collection('invoiceData')
          .getOne(invoiceId, expand: 'customer');

      debugPrint('📋 Invoice record data: ${invoiceRecord.data}');
      debugPrint('📋 Invoice expand data: ${invoiceRecord.expand}');

      String? customerId;

      // Extract customer ID using the same logic as addInvoiceDataToDelivery
      if (invoiceRecord.expand.containsKey('customer') &&
          invoiceRecord.expand['customer'] != null) {
        final customerData = invoiceRecord.expand['customer'];
        if (customerData is List && customerData!.isNotEmpty) {
          customerId = (customerData.first).id;
          debugPrint('✅ Found customer ID from expand list: $customerId');
        }
      } else if (invoiceRecord.data.containsKey('customer') &&
          invoiceRecord.data['customer'] != null) {
        customerId = invoiceRecord.data['customer'].toString();
        debugPrint('✅ Found customer ID from data field: $customerId');
      }

      if (customerId == null || customerId.isEmpty) {
        debugPrint('⚠️ Invoice $invoiceId has no customer data');
        debugPrint(
          '📋 Available data fields: ${invoiceRecord.data.keys.toList()}',
        );
        debugPrint(
          '📋 Available expand fields: ${invoiceRecord.expand.keys.toList()}',
        );

        // Create status record without customer data
        final statusData = {'invoiceData': invoiceId, 'status': 'assigned'};

        await _pocketBaseClient
            .collection('invoiceStatus')
            .create(body: statusData);

        debugPrint('⚠️ Created invoice status without customer data');
      } else {
        debugPrint('📋 Invoice $invoiceId belongs to customer: $customerId');

        // Create a new invoice status record with both invoiceData and customerData
        final statusData = {
          'invoiceData': invoiceId,
          'customerData': customerId,
          'status': 'assigned',
        };

        debugPrint('📤 Creating invoice status with data: $statusData');

        await _pocketBaseClient
            .collection('invoiceStatus')
            .create(body: statusData);

        debugPrint('✅ Created invoice status record with customer data');
      }

      // Update the invoice data to reference this status
      // Fetch the created record to get its ID
      final records = await _pocketBaseClient
          .collection('invoiceStatus')
          .getList(
            page: 1,
            filter: 'invoiceData = "$invoiceId" && status = "assigned"',
            sort: '-created',
          );

      if (records.items.isNotEmpty) {
        final createdStatusId = records.items.first.id;

        await _pocketBaseClient
            .collection('invoiceData')
            .update(invoiceId, body: {'invoiceStatus': createdStatusId});

        debugPrint('✅ Updated invoice with new status ID: $createdStatusId');

        // Log the complete status record for verification
        final statusRecord = records.items.first;
        debugPrint('📊 Final Invoice Status Record:');
        debugPrint('  - ID: ${statusRecord.id}');
        debugPrint('  - Invoice Data: ${statusRecord.data['invoiceData']}');
        debugPrint(
          '  - Customer Data: ${statusRecord.data['customerData'] ?? 'NOT SET'}',
        );
        debugPrint('  - Status: ${statusRecord.data['status']}');

        // Verify the customer data was actually saved
        if (statusRecord.data['customerData'] != null) {
          debugPrint('✅ Customer data successfully saved to invoice status');
        } else {
          debugPrint('❌ Customer data was NOT saved to invoice status');
        }
      }

      debugPrint('✅ Successfully processed invoice status creation');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to add invoice to invoice status: ${e.toString()}');
      debugPrint('❌ Error details: $e');
      throw ServerException(
        message: 'Failed to add invoice to invoice status: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // Helper method to generate a fixed-length ID if needed
  String _generateFixedLengthId(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
