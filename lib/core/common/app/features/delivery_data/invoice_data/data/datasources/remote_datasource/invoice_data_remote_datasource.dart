import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';


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

  // Set invoice unloaded by ID
  Future<bool> setInvoiceUnloadedById(String invoiceDataId);
}

class InvoiceDataRemoteDataSourceImpl implements InvoiceDataRemoteDataSource {
  const InvoiceDataRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<InvoiceDataModel>> getAllInvoiceData() async {
    try {
      debugPrint('🔄 Fetching all invoice data');

      final result = await _pocketBaseClient
          .collection('invoiceData')
          .getFullList(expand: 'customer', sort: '-created');

      debugPrint('✅ Retrieved ${result.length} invoice data records');

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
      debugPrint('❌ Failed to fetch all invoice data: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load invoice data: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<InvoiceDataModel> getInvoiceDataById(String id) async {
    try {
      debugPrint('🔄 Fetching invoice data by ID: $id');

      final record = await _pocketBaseClient
          .collection('invoiceData')
          .getOne(id, expand: 'customer');

      debugPrint('✅ Retrieved invoice data: ${record.id}');

      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'refId': record.data['refId'] ?? '',
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
            final mappedData = {
              'id': invoiceRecord.id,
              'collectionId': invoiceRecord.collectionId,
              'collectionName': invoiceRecord.collectionName,
              'refId': invoiceRecord.data['refId'] ?? '',
              'name': invoiceRecord.data['name'] ?? '',
              'documentDate': invoiceRecord.data['documentDate'],
              'totalAmount': invoiceRecord.data['totalAmount'],
              'volume': invoiceRecord.data['volume'],
              'weight': invoiceRecord.data['weight'],

              'expand': {'customer': deliveryData.expand['customer']},
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

      // Create a new invoice status record
      await _pocketBaseClient
          .collection('invoiceStatus')
          .create(
            body: {
              // Don't specify the ID field - let PocketBase generate it
              'invoiceData': invoiceId,
              'status': 'assigned',
            },
          );

      debugPrint('✅ Created new invoice status with invoice data');

      // Update the invoice data to reference this status
      // Since we let PocketBase generate the ID, we need to fetch the created record
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
      }

      debugPrint('✅ Successfully added invoice to invoice status');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to add invoice to invoice status: ${e.toString()}');
      throw ServerException(
        message: 'Failed to add invoice to invoice status: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> setInvoiceUnloadedById(String invoiceDataId) async {
    try {
      debugPrint('🔄 Setting invoice to unloaded for invoice data ID: $invoiceDataId');

      // Find invoiceStatus records where invoiceData field matches this invoice ID
      final invoiceStatusRecords = await _pocketBaseClient
          .collection('invoiceStatus')
          .getFullList(
            filter: 'invoiceData = "$invoiceDataId"',
          );

      debugPrint('📊 Found ${invoiceStatusRecords.length} invoiceStatus records for invoice: $invoiceDataId');

      if (invoiceStatusRecords.isEmpty) {
        debugPrint('⚠️ No invoiceStatus records found for invoice: $invoiceDataId');
        return false;
      }

      // Update all matching invoiceStatus records
      for (var statusRecord in invoiceStatusRecords) {
        await _pocketBaseClient
            .collection('invoiceStatus')
            .update(
              statusRecord.id,
              body: {
                'tripStatus': 'unloaded',
                'updated': DateTime.now().toUtc().toIso8601String(),
              },
            );
        
        debugPrint('✅ Updated invoiceStatus record: ${statusRecord.id} to unloaded');
      }

      debugPrint('✅ Successfully set invoice to unloaded for invoice data ID: $invoiceDataId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to set invoice to unloaded: ${e.toString()}');
      throw ServerException(
        message: 'Failed to set invoice to unloaded: ${e.toString()}',
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
