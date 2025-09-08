import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/data/model/invoice_preset_group_model.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';

abstract class InvoicePresetGroupRemoteDataSource {
  // Get all invoice preset groups
  Future<List<InvoicePresetGroupModel>> getAllInvoicePresetGroups();

  // Add all invoices from a preset group to a delivery
  Future<void> addAllInvoicesToDelivery({
    required String presetGroupId,
    required String deliveryId,
  });

  // Search for preset groups by reference ID
  Future<List<InvoicePresetGroupModel>> searchPresetGroupByRefId(String refId);

  Future<List<InvoicePresetGroupModel>> getAllUnassignedInvoicePresetGroups();
}

class InvoicePresetGroupRemoteDataSourceImpl
    implements InvoicePresetGroupRemoteDataSource {
  const InvoicePresetGroupRemoteDataSourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

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

  @override
  Future<List<InvoicePresetGroupModel>> getAllInvoicePresetGroups() async {
    try {
      debugPrint('🔄 Fetching all invoice preset groups');

      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      final result = await _pocketBaseClient
          .collection('invoicePresetGroup')
          .getFullList(
            expand: 'invoices',
            sort: '-created',
            filter:
                'groupStatus = "CONFIRMED" || groupStatus = "LOADING" || groupStatus = "LOADED" || groupStatus = "DISPATCH" || groupStatus = "DELIVERED"',
          );

      debugPrint('✅ Retrieved ${result.length} invoice preset groups');

      List<InvoicePresetGroupModel> presetGroups = [];

      for (var record in result) {
        final mappedData = {
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          'refId': record.data['refID'] ?? '',
          'name': record.data['name'] ?? '',

          'expand': {'invoices': record.expand['invoices']},
        };

        presetGroups.add(InvoicePresetGroupModel.fromJson(mappedData));
      }

      return presetGroups;
    } catch (e) {
      debugPrint('❌ Failed to fetch invoice preset groups: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load invoice preset groups: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<InvoicePresetGroupModel>>
  getAllUnassignedInvoicePresetGroups() async {
    try {
      debugPrint('🔄 Fetching all unassigned invoice preset groups');

      // Ensure PocketBase client is authenticated
      await _ensureAuthenticated();

      // 1. First, get all invoice preset groups with their invoices
      final presetGroups = await _pocketBaseClient
          .collection('invoicePresetGroup')
          .getFullList(expand: 'invoices', sort: '-created');

      debugPrint('✅ Retrieved ${presetGroups.length} invoice preset groups');

      // 2. Get all invoices that have already been assigned (have an invoiceStatus)
      final assignedInvoices = await _pocketBaseClient
          .collection('invoiceStatus')
          .getFullList(expand: 'invoiceData', fields: 'id,invoiceData');

      // Create a set of assigned invoice IDs for faster lookup
      final Set<String> assignedInvoiceIds = {};
      for (var statusRecord in assignedInvoices) {
        // Get the invoice ID from the invoiceData relation
        if (statusRecord.expand.containsKey('invoiceData') &&
            statusRecord.expand['invoiceData'] != null) {
          final invoiceData = statusRecord.expand['invoiceData'];
          if (invoiceData is List && invoiceData!.isNotEmpty) {
            for (var invoice in invoiceData) {
              assignedInvoiceIds.add(invoice.id);
            }
          }
        } else if (statusRecord.data.containsKey('invoiceData') &&
            statusRecord.data['invoiceData'] != null) {
          // If not expanded but we have the ID
          final invoiceId = statusRecord.data['invoiceData'].toString();
          if (invoiceId.isNotEmpty) {
            assignedInvoiceIds.add(invoiceId);
          }
        }
      }

      debugPrint(
        'ℹ️ Found ${assignedInvoiceIds.length} already assigned invoices',
      );

      List<InvoicePresetGroupModel> unassignedPresetGroups = [];

      // 3. Filter preset groups to only include those with unassigned invoices
      for (var presetGroup in presetGroups) {
        final invoicesData = presetGroup.expand['invoices'] as List?;

        if (invoicesData == null || invoicesData.isEmpty) {
          debugPrint(
            '⚠️ Preset group ${presetGroup.id} has no invoices, skipping',
          );
          continue;
        }

        // Check if any invoices in this group are unassigned
        bool hasUnassignedInvoices = false;
        List<dynamic> unassignedInvoices = [];

        for (var invoice in invoicesData) {
          final invoiceRecord = invoice as RecordModel;
          final invoiceId = invoiceRecord.id;

          if (!assignedInvoiceIds.contains(invoiceId)) {
            hasUnassignedInvoices = true;
            unassignedInvoices.add(invoice);
          }
        }

        if (hasUnassignedInvoices) {
          // Create a copy of the preset group with only unassigned invoices
          final mappedData = {
            'id': presetGroup.id,
            'collectionId': presetGroup.collectionId,
            'collectionName': presetGroup.collectionName,
            'refId': presetGroup.data['refID'] ?? '',
            'name': presetGroup.data['name'] ?? '',
            'description': presetGroup.data['description'] ?? '',
            'created': presetGroup.created,
            'updated': presetGroup.updated,
            'expand': {'invoices': unassignedInvoices},
          };

          unassignedPresetGroups.add(
            InvoicePresetGroupModel.fromJson(mappedData),
          );
          debugPrint(
            '✅ Added preset group ${presetGroup.id} with ${unassignedInvoices.length} unassigned invoices',
          );
        } else {
          debugPrint(
            'ℹ️ Preset group ${presetGroup.id} has no unassigned invoices, skipping',
          );
        }
      }

      debugPrint(
        '✅ Returning ${unassignedPresetGroups.length} unassigned invoice preset groups',
      );
      return unassignedPresetGroups;
    } catch (e) {
      debugPrint(
        '❌ Failed to fetch unassigned invoice preset groups: ${e.toString()}',
      );
      throw ServerException(
        message:
            'Failed to load unassigned invoice preset groups: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> addAllInvoicesToDelivery({
    required String presetGroupId,
    required String deliveryId,
  }) async {
    try {
      debugPrint(
        '🔄 Adding customer and all their invoices from preset group $presetGroupId to delivery $deliveryId',
      );

      // Ensure authentication
      await _ensureAuthenticated();

      // 1. Get the preset group with its invoices
      final presetGroupRecord = await _pocketBaseClient
          .collection('invoicePresetGroup')
          .getOne(presetGroupId, expand: 'invoices');

      final invoicesData = presetGroupRecord.expand['invoices'] as List?;
      if (invoicesData == null || invoicesData.isEmpty) {
        debugPrint('⚠️ No invoices found in preset group $presetGroupId');
        return;
      }

      debugPrint('✅ Found ${invoicesData.length} invoices in preset group');

      // 2. Group invoices by customer ID
      Map<String, List<RecordModel>> invoicesByCustomer = {};

      for (var invoiceData in invoicesData) {
        final invoiceRecord = invoiceData as RecordModel;
        final customerId = invoiceRecord.data['customer']?.toString();

        if (customerId != null && customerId.isNotEmpty) {
          if (!invoicesByCustomer.containsKey(customerId)) {
            invoicesByCustomer[customerId] = [];
          }
          invoicesByCustomer[customerId]!.add(invoiceRecord);
        }
      }

      debugPrint(
        '✅ Found ${invoicesByCustomer.length} different customers in preset group',
      );

      // 3. Process each customer separately
      for (var customerEntry in invoicesByCustomer.entries) {
        final customerId = customerEntry.key;
        final customerInvoicesInGroup = customerEntry.value;

        debugPrint(
          '🔄 Processing customer $customerId with ${customerInvoicesInGroup.length} invoices from preset group',
        );

        // Get ONLY invoices for this customer that are also inside the preset group
        final allInvoiceIds = customerInvoicesInGroup.map((invoice) => invoice.id).toList();
        
        debugPrint(
          '✅ Using ${allInvoiceIds.length} invoices for customer $customerId from preset group $presetGroupId',
        );
        debugPrint('📦 Invoice IDs to attach: $allInvoiceIds');


        // 4. Get customer data for enrichment
        RecordModel? customerRecord;
        try {
          customerRecord = await _pocketBaseClient
              .collection('customerData')
              .getOne(customerId);
          debugPrint('✅ Found customer: ${customerRecord.data['name']}');
        } catch (e) {
          debugPrint('⚠️ Could not fetch customer data for ID $customerId: $e');
        }

        // 5. Check if delivery already exists or create/update
        String actualDeliveryId = deliveryId;

        try {
          // Try to get existing delivery
          await _pocketBaseClient.collection('deliveryData').getOne(deliveryId);

          debugPrint('✅ Found existing delivery: $deliveryId');

          // Update existing delivery with customer and all their invoices
          final updateData = <String, dynamic>{
            'customer': customerId,
            'invoices':
                List<String>.from(allInvoiceIds), // Multiple relation - all customer invoices
            'updated': DateTime.now().toIso8601String(),
          };

          // Add enriched customer data if available
          if (customerRecord != null) {
            updateData.addAll({
              'storeName': customerRecord.data['name'] ?? '',
              'refID': customerRecord.data['refID'] ?? '',
              'province': customerRecord.data['province'] ?? '',
              'municipality': customerRecord.data['municipality'] ?? '',
              'barangay': customerRecord.data['barangay'] ?? '',
              'paymentMode': customerRecord.data['paymentMode'] ?? '',
              'ownerName': customerRecord.data['ownerName'] ?? '',
              'contactNumber': customerRecord.data['contactNumber'] ?? '',
            });
          }

          await _pocketBaseClient
              .collection('deliveryData')
              .update(deliveryId, body: updateData);

          debugPrint(
            '✅ Updated existing delivery with ${allInvoiceIds.length} invoices',
          );
        } catch (e) {
          // Delivery doesn't exist, create new one
          debugPrint('📝 Delivery not found, creating new delivery');

          final deliveryNumber = _generateDeliveryNumber();

          final newDeliveryData = <String, dynamic>{
            'deliveryNumber': deliveryNumber,
            'customer': customerId,
            'invoices':
                allInvoiceIds, // Multiple relation - all customer invoices
            'hasTrip': false,
            'invoiceStatus': 'truck',
            'created': DateTime.now().toIso8601String(),
            'updated': DateTime.now().toIso8601String(),
          };

          // Add enriched customer data if available
          if (customerRecord != null) {
            newDeliveryData.addAll({
              'storeName': customerRecord.data['name'] ?? '',
              'refID': customerRecord.data['refID'] ?? '',
              'province': customerRecord.data['province'] ?? '',
              'municipality': customerRecord.data['municipality'] ?? '',
              'barangay': customerRecord.data['barangay'] ?? '',
              'paymentMode': customerRecord.data['paymentMode'] ?? '',
              'ownerName': customerRecord.data['ownerName'] ?? '',
              'contactNumber': customerRecord.data['contactNumber'] ?? '',
            });
          }

          final newDelivery = await _pocketBaseClient
              .collection('deliveryData')
              .create(body: newDeliveryData);

          // Update the actual delivery ID to use the newly created one
          actualDeliveryId = newDelivery.id;

          debugPrint(
            '✅ Created new delivery ${newDelivery.id} with ${allInvoiceIds.length} invoices',
          );
        }

        // 6. Update all customer invoices to reference the delivery and create individual invoice status records
        debugPrint(
          '🔄 Creating individual invoiceStatus records for ${allInvoiceIds.length} invoices...',
        );

        for (int i = 0; i < allInvoiceIds.length; i++) {
          final invoiceId = allInvoiceIds[i];

          debugPrint(
            '📝 Processing invoice ${i + 1}/${allInvoiceIds.length}: $invoiceId',
          );

          // Update invoice to reference the delivery
          await _pocketBaseClient
              .collection('invoiceData')
              .update(
                invoiceId,
                body: {
                  'deliveryData': actualDeliveryId,
                  'customer': customerId,
                },
              );

          // Create individual invoice status record for this invoice
          await addInvoiceDataToInvoiceStatus(invoiceId: invoiceId);

          debugPrint('✅ Created invoiceStatus record for invoice $invoiceId');
        }

        debugPrint(
          '✅ Successfully created ${allInvoiceIds.length} individual invoiceStatus records',
        );

        // 7. Collect all invoice items for the invoices and add to delivery
        await _addInvoiceItemsToDelivery(actualDeliveryId, allInvoiceIds);

        debugPrint(
          '✅ Successfully added customer $customerId and ${allInvoiceIds.length} invoices to delivery $actualDeliveryId',
        );
      }

      debugPrint(
        '✅ Completed processing all customers in preset group $presetGroupId',
      );
    } catch (e) {
      debugPrint('❌ Failed to add invoices to delivery: ${e.toString()}');
      throw ServerException(
        message: 'Failed to add invoices to delivery: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  String _generateDeliveryNumber() {
    final random = Random();
    final randomNumber = random.nextInt(99999) + 1; // Generates 1-99999
    final paddedNumber = randomNumber.toString().padLeft(
      5,
      '0',
    ); // Ensures 5 digits
    return 'DEL-$paddedNumber';
  }

  Future<bool> addInvoiceDataToInvoiceStatus({
    required String invoiceId,
    String? invoiceStatusId,
  }) async {
    try {
      // Generate a fixed-length ID if not provided
      final statusId = invoiceStatusId ?? _generateFixedLengthId(15);

      debugPrint('🔄 Adding invoice $invoiceId to invoice status $statusId');

      // First get the invoice data to extract the customer information
      final invoiceRecord = await _pocketBaseClient
          .collection('invoiceData')
          .getOne(invoiceId);

      final customerId = invoiceRecord.data['customer']?.toString();
      debugPrint('🔍 Found customer ID: $customerId for invoice $invoiceId');

      // Create a new invoice status record with customer data
      await _pocketBaseClient
          .collection('invoiceStatus')
          .create(
            body: {
              // Don't specify the ID field - let PocketBase generate it
              'invoiceData': invoiceId,
              'customerData': customerId,
              'status': 'assigned',
              'tripStatus': 'pending',
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

  // Helper method to collect all invoice items for the given invoices and add to delivery
  Future<void> _addInvoiceItemsToDelivery(
    String deliveryId,
    List<String> invoiceIds,
  ) async {
    try {
      debugPrint(
        '🔄 Collecting invoice items for ${invoiceIds.length} invoices...',
      );

      List<String> allInvoiceItemIds = [];

      // For each invoice, find all its invoice items
      for (int i = 0; i < invoiceIds.length; i++) {
        final invoiceId = invoiceIds[i];
        debugPrint(
          '📝 Finding invoice items for invoice ${i + 1}/${invoiceIds.length}: $invoiceId',
        );

        // Query invoice items where invoice matches this invoice ID
        final invoiceItemsResult = await _pocketBaseClient
            .collection('invoiceItems')
            .getFullList(filter: 'invoice = "$invoiceId"', sort: 'created');

        // Collect the invoice item IDs
        final invoiceItemIds =
            invoiceItemsResult.map((item) => item.id).toList();
        allInvoiceItemIds.addAll(invoiceItemIds);

        debugPrint(
          '✅ Found ${invoiceItemIds.length} invoice items for invoice $invoiceId',
        );
      }

      debugPrint(
        '✅ Collected total of ${allInvoiceItemIds.length} invoice items from all invoices',
      );

      // Update the delivery to include all invoice items
      if (allInvoiceItemIds.isNotEmpty) {
        await _pocketBaseClient
            .collection('deliveryData')
            .update(deliveryId, body: {'invoiceItems': allInvoiceItemIds});

        debugPrint(
          '✅ Added ${allInvoiceItemIds.length} invoice items to delivery $deliveryId',
        );
      } else {
        debugPrint('ℹ️ No invoice items found for any of the invoices');
      }
    } catch (e) {
      debugPrint('❌ Failed to add invoice items to delivery: ${e.toString()}');
      throw ServerException(
        message: 'Failed to add invoice items to delivery: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<InvoicePresetGroupModel>> searchPresetGroupByRefId(
    String refId,
  ) async {
    try {
      debugPrint('🔄 Searching invoice preset groups with refId: $refId');

      // Check if the collection name is correct - it might be "invoicePresetGroups" (plural) instead of "invoicePresetGroup"
      // Also, modify the filter syntax to ensure it's correct
      final result = await _pocketBaseClient
          .collection('invoicePresetGroup') // Try with plural form
          .getFullList(
            expand: 'invoices',
            filter:
                'refID ~ "${refId.trim()}"', // Ensure proper formatting and trim input
            sort: '-created',
          );

      debugPrint(
        '✅ Found ${result.length} invoice preset groups matching refId: $refId',
      );

      List<InvoicePresetGroupModel> presetGroups = [];

      for (var record in result) {
        final mappedData = {
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          'refID': record.data['refID'] ?? '',
          'name': record.data['name'] ?? '',
          'description': record.data['description'] ?? '',
          'invoiceCount': record.expand['invoices']?.length ?? 0,
          'created': record.created,
          'updated': record.updated,
          'expand': {'invoices': record.expand['invoices']},
        };

        presetGroups.add(InvoicePresetGroupModel.fromJson(mappedData));
      }

      return presetGroups;
    } catch (e) {
      debugPrint('❌ Failed to search invoice preset groups: ${e.toString()}');

      // Try alternative collection name if the first attempt fails
      try {
        debugPrint('🔄 Retrying with alternative collection name...');

        final result = await _pocketBaseClient
            .collection('invoicePresetGroup') // Try with singular form
            .getFullList(
              expand: 'invoices',
              filter:
                  'refID = "${refId.trim()}"', // Try exact match instead of contains
              sort: '-created',
            );

        debugPrint(
          '✅ Found ${result.length} invoice preset groups matching refId: $refId',
        );

        List<InvoicePresetGroupModel> presetGroups = [];

        for (var record in result) {
          final mappedData = {
            'id': record.id,
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            'refId': record.data['refID'] ?? '',
            'name': record.data['name'] ?? '',
            'description': record.data['description'] ?? '',
            'invoiceCount': record.expand['invoices']?.length ?? 0,
            'created': record.created,
            'updated': record.updated,
            'expand': {'invoices': record.expand['invoices']},
          };

          presetGroups.add(InvoicePresetGroupModel.fromJson(mappedData));
        }

        return presetGroups;
      } catch (retryError) {
        debugPrint('❌ Retry also failed: ${retryError.toString()}');
        throw ServerException(
          message: 'Failed to search invoice preset groups: ${e.toString()}',
          statusCode: '500',
        );
      }
    }
  }
}
