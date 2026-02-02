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
Future<List<InvoicePresetGroupModel>> getAllUnassignedInvoicePresetGroups() async {
  try {
    debugPrint('🔄 Fetching latest unassigned invoice preset groups (PAGED + FAST)');
    await _ensureAuthenticated();

    // ------------------------------------------------------------
    // ✅ 1) Fetch ONLY the latest page of preset groups (NOT full list)
    // ------------------------------------------------------------
    final pgPage = await _pocketBaseClient
        .collection('invoicePresetGroup')
        .getList(
          page: 1,
          perPage: 30, // tune this
          sort: '-created', // or '-updated' if you want “latest updated”
          expand: 'invoices',
          fields: 'id,refID,name,description,created,updated,expand.invoices',
        );

    final presetGroups = pgPage.items;

    debugPrint('✅ Retrieved preset groups (page 1): ${presetGroups.length}');

    if (presetGroups.isEmpty) return [];

    // ------------------------------------------------------------
    // ✅ 2) Collect ONLY invoice IDs inside this page (so we don’t scan all invoiceStatus)
    // ------------------------------------------------------------
    final Set<String> invoiceIdsInPage = <String>{};

    for (final pg in presetGroups) {
      final invoices =
          (pg.expand['invoices'] as List?)?.cast<RecordModel>() ?? const <RecordModel>[];

      for (final inv in invoices) {
        final id = inv.id.trim();
        if (id.isNotEmpty) invoiceIdsInPage.add(id);
      }
    }

    if (invoiceIdsInPage.isEmpty) {
      debugPrint('ℹ️ No invoices found in latest preset groups.');
      return [];
    }

    debugPrint('ℹ️ Invoice IDs in page: ${invoiceIdsInPage.length}');

    // ------------------------------------------------------------
    // ✅ 3) Fetch ONLY invoiceStatus rows that reference invoice IDs in this page
    //    Uses PocketBase relation contains operator: ?=
    //    Chunked to avoid long filter strings
    // ------------------------------------------------------------
    String buildOrFilter(String field, List<String> ids) {
      return ids.map((id) => '$field ?= "$id"').join(' || ');
    }

    final Set<String> assignedInvoiceIds = <String>{};
    final idsList = invoiceIdsInPage.toList(growable: false);

    const int chunkSize = 40; // tune depending on typical ids length + URL limits

    for (int i = 0; i < idsList.length; i += chunkSize) {
      final chunk = idsList.sublist(
        i,
        (i + chunkSize > idsList.length) ? idsList.length : i + chunkSize,
      );

      final filter = buildOrFilter('invoiceData', chunk);

      final statusRows = await _pocketBaseClient
          .collection('invoiceStatus')
          .getFullList(
            filter: filter,
            fields: 'invoiceData', // relation ids only
          );

      for (final statusRecord in statusRows) {
        final v = statusRecord.data['invoiceData'];

        // invoiceData can be String (single rel) or List (multi rel)
        if (v is String) {
          final id = v.trim();
          if (id.isNotEmpty) assignedInvoiceIds.add(id);
        } else if (v is List) {
          for (final e in v) {
            final id = e.toString().trim();
            if (id.isNotEmpty) assignedInvoiceIds.add(id);
          }
        }
      }
    }

    debugPrint('ℹ️ Assigned invoice IDs (in page): ${assignedInvoiceIds.length}');

    // ------------------------------------------------------------
    // ✅ 4) Filter groups → keep only UNASSIGNED invoices
    // ------------------------------------------------------------
    final List<InvoicePresetGroupModel> unassignedPresetGroups = [];

    for (final pg in presetGroups) {
      final invoices =
          (pg.expand['invoices'] as List?)?.cast<RecordModel>() ?? const <RecordModel>[];

      if (invoices.isEmpty) continue;

      final unassignedInvoices = invoices.where((inv) {
        final id = inv.id.trim();
        return id.isNotEmpty && !assignedInvoiceIds.contains(id);
      }).toList(growable: false);

      if (unassignedInvoices.isEmpty) continue;

      final mappedData = <String, dynamic>{
        'id': pg.id,
        'collectionId': pg.collectionId,
        'collectionName': pg.collectionName,
        'refId': pg.data['refID'] ?? '',
        'name': pg.data['name'] ?? '',
        'description': pg.data['description'] ?? '',
        'created': pg.created,
        'updated': pg.updated,
        'expand': {
          'invoices': unassignedInvoices,
        },
      };

      unassignedPresetGroups.add(InvoicePresetGroupModel.fromJson(mappedData));

      debugPrint(
        '✅ PresetGroup ${pg.id}: unassigned invoices=${unassignedInvoices.length}',
      );
    }

    debugPrint('✅ Returning ${unassignedPresetGroups.length} unassigned preset groups');
    return unassignedPresetGroups;
  } catch (e) {
    debugPrint('❌ Failed to fetch unassigned invoice preset groups: $e');
    throw ServerException(
      message: 'Failed to load unassigned invoice preset groups: $e',
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
      final startTime = DateTime.now();
      debugPrint(
        '🔄 (FAST) Adding all invoices from preset group $presetGroupId to deliveries (no invoiceItems step)',
      );

      await _ensureAuthenticated();

      final presetGroupRecord = await _pocketBaseClient
          .collection('invoicePresetGroup')
          .getOne(presetGroupId, expand: 'invoices');

      final invoicesData = presetGroupRecord.expand['invoices'] as List?;
      if (invoicesData == null || invoicesData.isEmpty) {
        debugPrint('⚠️ No invoices in preset group $presetGroupId');
        return;
      }
      debugPrint('✅ Found ${invoicesData.length} invoices');

      // Group invoices by customer
      final Map<String, List<RecordModel>> invoicesByCustomer = {};
      final List<String> allInvoiceIds = [];
      final Map<String, String> invoiceToCustomer = {};

      for (var invoiceData in invoicesData) {
        final invoice = invoiceData as RecordModel;
        final invoiceId = invoice.id;
        final custId = invoice.data['customer']?.toString();
        allInvoiceIds.add(invoiceId);
        if (custId != null && custId.isNotEmpty) {
          invoiceToCustomer[invoiceId] = custId;
          invoicesByCustomer.putIfAbsent(custId, () => []).add(invoice);
        }
      }

      debugPrint('✅ Grouped into ${invoicesByCustomer.length} customers');

      // Fetch customers in chunked batches
      final customerMap = <String, RecordModel?>{};
      final customerIds = invoicesByCustomer.keys.toList();
      if (customerIds.isNotEmpty) {
        const chunkSize = 200; // increase for high-bandwidth
        for (var i = 0; i < customerIds.length; i += chunkSize) {
          final end =
              (i + chunkSize < customerIds.length)
                  ? i + chunkSize
                  : customerIds.length;
          final chunk = customerIds.sublist(i, end);
          final filter = chunk.map((id) => 'id = "$id"').join(' || ');
          final results = await _pocketBaseClient
              .collection('customerData')
              .getFullList(filter: filter)
              .catchError((e) {
                debugPrint('⚠️ Customer chunk fetch failed: $e');
                return <RecordModel>[];
              });
          for (var r in results) customerMap[r.id] = r;
        }
      }

      // Create/update deliveries in parallel per customer
      debugPrint('🚀 Creating/updating deliveries in parallel...');
      final invoiceToDelivery = <String, String>{};
      final customerToDelivery = <String, String>{};

      final deliveryTasks =
          invoicesByCustomer.entries.map((entry) async {
            final custId = entry.key;
            final records = entry.value;
            final custRec = customerMap[custId];
            final invoiceIdsForCustomer = records.map((r) => r.id).toList();

            String actualDeliveryId = deliveryId;
            try {
              // Try updating provided delivery once - keep behavior consistent with prior implementation
              await _pocketBaseClient
                  .collection('deliveryData')
                  .getOne(deliveryId);
              final updateBody = <String, dynamic>{
                'customer': custId,
                'invoices': invoiceIdsForCustomer,
                'updated': DateTime.now().toIso8601String(),
              };
              if (custRec != null) {
                updateBody.addAll({
                  'storeName': custRec.data['name'] ?? '',
                  'province': custRec.data['province'] ?? '',
                  'municipality': custRec.data['municipality'] ?? '',
                  'barangay': custRec.data['barangay'] ?? '',
                  'paymentMode': custRec.data['paymentMode'] ?? '',
                  'ownerName': custRec.data['ownerName'] ?? '',
                  'contactNumber': custRec.data['contactNumber'] ?? '',
                });
              }
              await _pocketBaseClient
                  .collection('deliveryData')
                  .update(deliveryId, body: updateBody);
              debugPrint(
                '✅ Updated provided delivery $deliveryId for customer $custId',
              );
            } catch (_) {
              // Create new delivery for customer
              final newBody = <String, dynamic>{
                'deliveryNumber': _generateDeliveryNumber(),
                'customer': custId,
                'invoices': invoiceIdsForCustomer,
                'hasTrip': false,
                'invoiceStatus': 'truck',
                'created': DateTime.now().toIso8601String(),
                'updated': DateTime.now().toIso8601String(),
              };
              if (custRec != null) {
                newBody.addAll({
                  'storeName': custRec.data['name'] ?? '',
                  'refID': presetGroupRecord.data['refID'] ?? '',
                  'province': custRec.data['province'] ?? '',
                  'municipality': custRec.data['municipality'] ?? '',
                  'barangay': custRec.data['barangay'] ?? '',
                  'paymentMode': custRec.data['paymentMode'] ?? '',
                  'ownerName': custRec.data['ownerName'] ?? '',
                  'contactNumber': custRec.data['contactNumber'] ?? '',
                });
              }
              final newDel = await _pocketBaseClient
                  .collection('deliveryData')
                  .create(body: newBody);
              actualDeliveryId = newDel.id;
              debugPrint(
                '✅ Created delivery $actualDeliveryId for customer $custId',
              );
            }

            for (var id in invoiceIdsForCustomer)
              invoiceToDelivery[id] = actualDeliveryId;
            customerToDelivery[custId] = actualDeliveryId;
          }).toList();

      await Future.wait(deliveryTasks);
      debugPrint('✅ Deliveries ready');

      // -------------------------------------------------------------
// ✅ NEW STEP: Fetch invoiceItems in bulk and attach to deliveryData
// -------------------------------------------------------------
debugPrint('🚀 Fetching invoiceItems in bulk (fast mode)...');

final invoiceToItemIds = await _fetchInvoiceItemIdsByInvoiceIds(allInvoiceIds);

// Build deliveryId -> invoiceItemIds (dedup)
final Map<String, Set<String>> deliveryToItemIds = {};

for (final invId in allInvoiceIds) {
  final delId = invoiceToDelivery[invId];
  if (delId == null || delId.isEmpty) continue;

  final itemIds = invoiceToItemIds[invId];
  if (itemIds == null || itemIds.isEmpty) continue;

  deliveryToItemIds.putIfAbsent(delId, () => <String>{}).addAll(itemIds);
}

debugPrint(
  '✅ invoiceItems grouped → ${deliveryToItemIds.length} deliveries will be updated',
);

// Update deliveryData invoiceItems in big batches (parallel)
const deliveryUpdateBatchSize = 80;

final deliveryIdsToUpdate = deliveryToItemIds.keys.toList();

for (var i = 0; i < deliveryIdsToUpdate.length; i += deliveryUpdateBatchSize) {
  final end = (i + deliveryUpdateBatchSize < deliveryIdsToUpdate.length)
      ? i + deliveryUpdateBatchSize
      : deliveryIdsToUpdate.length;

  final batch = deliveryIdsToUpdate.sublist(i, end);

  final futures = batch.map((delId) {
    final ids = deliveryToItemIds[delId]!.toList();

    return _pocketBaseClient
        .collection('deliveryData')
        .update(
          delId,
          body: {
            // IMPORTANT:
            // If you want replace:
            'invoiceItems': ids,

            // If you want append (PocketBase supports "+"):
            // 'invoiceItems+': ids,
            'updated': DateTime.now().toIso8601String(),
          },
        )
        .catchError((e) {
          debugPrint('⚠️ deliveryData invoiceItems update failed $delId: $e');
          return null;
        });
  }).toList();

  await Future.wait(futures);
  debugPrint('✅ Updated deliveryData invoiceItems batch ${i ~/ deliveryUpdateBatchSize + 1}');
}

debugPrint('✨ invoiceItems attached to deliveryData successfully');


      // Create invoiceStatus in larger batches & parallel
      debugPrint('🚀 Creating invoiceStatus records (big batches)...');
      final invoiceToStatus = <String, String>{};
      const statusBatchSize = 200; // large batch for high bandwidth

      for (var i = 0; i < allInvoiceIds.length; i += statusBatchSize) {
        final end =
            (i + statusBatchSize < allInvoiceIds.length)
                ? i + statusBatchSize
                : allInvoiceIds.length;
        final batch = allInvoiceIds.sublist(i, end);
        final futures =
            batch.map((invId) {
              final custId = invoiceToCustomer[invId];
              final delId = invoiceToDelivery[invId];
              return _pocketBaseClient
                  .collection('invoiceStatus')
                  .create(
                    body: {
                      'invoiceData': invId,
                      'customerData': custId,
                      'deliveryData': [delId],
                      'status': 'assigned',
                      'tripStatus': 'pending',
                    },
                  )
                  .catchError((e) {
                    debugPrint('⚠️ invoiceStatus create failed $invId: $e');
                    return null;
                  });
            }).toList();

        final results = await Future.wait(futures);
        for (var idx = 0; idx < results.length; idx++) {
          final rec = results[idx];
          invoiceToStatus[batch[idx]] = rec.id;
        }
        debugPrint(
          '✅ Created ${results.whereType<RecordModel>().length} statuses for batch ${i ~/ statusBatchSize + 1}',
        );
      }
// Update invoiceData in large parallel batches
debugPrint('🚀 Updating invoiceData records (big batches)...');
const updateBatchSize = 200;

for (var i = 0; i < allInvoiceIds.length; i += updateBatchSize) {
  final end = (i + updateBatchSize < allInvoiceIds.length)
      ? i + updateBatchSize
      : allInvoiceIds.length;

  final batch = allInvoiceIds.sublist(i, end);

  final futures = batch.map((invId) async {
    final statusId = invoiceToStatus[invId];
    final delId = invoiceToDelivery[invId];
    final custId = invoiceToCustomer[invId];

    try {
      await _pocketBaseClient.collection('invoiceData').update(
        invId,
        body: {
          if (delId != null) 'deliveryData': [delId],
          if (custId != null) 'customer': custId,
          if (statusId != null) 'invoiceStatus': [statusId],
        },
      );
      return true; // success marker
    } catch (e) {
      debugPrint('⚠️ invoiceData update failed $invId: $e');
      return false; // failure marker
    }
  }).toList();

  final results = await Future.wait(futures);
  final ok = results.where((x) => x).length;
  final fail = results.length - ok;

  debugPrint('✅ Updated invoiceData batch ${i ~/ updateBatchSize + 1} | ok=$ok fail=$fail');
}


      // NOTE: SKIP invoiceItems fetching/attaching to deliveryData to maximize speed.
      // If required later, re-enable a separate background job to attach invoiceItems.

      final duration = DateTime.now().difference(startTime);
      debugPrint(
        '✨ (FAST) Completed in ${duration.inSeconds}s for ${allInvoiceIds.length} invoices across ${invoicesByCustomer.length} customers',
      );
    } catch (e) {
      debugPrint(
        '❌ (FAST) Failed to add invoices to delivery: ${e.toString()}',
      );
      throw ServerException(
        message: 'Failed to add invoices to delivery: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

Future<Map<String, List<String>>> _fetchInvoiceItemIdsByInvoiceIds(
  List<String> invoiceIds,
) async {
  final Map<String, List<String>> invoiceToItemIds = {};

  if (invoiceIds.isEmpty) return invoiceToItemIds;

  // Chunked to avoid very long filter strings / URL limits
  const chunkSize = 120;

  for (var i = 0; i < invoiceIds.length; i += chunkSize) {
    final end = (i + chunkSize < invoiceIds.length) ? i + chunkSize : invoiceIds.length;
    final chunk = invoiceIds.sublist(i, end);

    // invoice = "id1" || invoice = "id2" ...
    final filter = chunk.map((id) => 'invoice = "$id"').join(' || ');

    final items = await _pocketBaseClient
        .collection('invoiceItems')
        .getFullList(
          filter: filter,
          // optional: fields if your PB client supports it
          // fields: 'id,invoice',
        )
        .catchError((e) {
          debugPrint('⚠️ invoiceItems chunk fetch failed: $e');
          return <RecordModel>[];
        });

    for (final it in items) {
      final invoiceId = it.data['invoice']?.toString().trim() ?? '';
      if (invoiceId.isEmpty) continue;

      invoiceToItemIds.putIfAbsent(invoiceId, () => []).add(it.id);
    }

    debugPrint('✅ invoiceItems fetched chunk ${i ~/ chunkSize + 1} → ${items.length} items');
  }

  return invoiceToItemIds;
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
    required String deliveryDataId, // 👈 Added parameter
    String? invoiceStatusId,
  }) async {
    try {
      // Generate a fixed-length ID if not provided
      final statusId = invoiceStatusId ?? _generateFixedLengthId(15);

      debugPrint('🔄 Adding invoice $invoiceId to invoice status $statusId');
      debugPrint('📦 Linking invoice to deliveryData: $deliveryDataId');

      // 1️⃣ Get invoice data to extract customer info
      final invoiceRecord = await _pocketBaseClient
          .collection('invoiceData')
          .getOne(invoiceId);

      final customerId = invoiceRecord.data['customer']?.toString();
      debugPrint('🔍 Found customer ID: $customerId for invoice $invoiceId');

      // 2️⃣ Create a new invoice status record
      final newStatus = await _pocketBaseClient
          .collection('invoiceStatus')
          .create(
            body: {
              'invoiceData': invoiceId,
              'customerData': customerId,
              'deliveryData': deliveryDataId, // 👈 NEW FIELD
              'status': 'assigned',
              'tripStatus': 'pending',
            },
          );

      debugPrint('✅ Created new invoiceStatus record: ${newStatus.id}');

      // 3️⃣ Update the invoice to reference this invoiceStatus record
      await _pocketBaseClient
          .collection('invoiceData')
          .update(invoiceId, body: {'invoiceStatus': newStatus.id});

      debugPrint(
        '✅ Updated invoice $invoiceId with new status ID: ${newStatus.id}',
      );
      debugPrint(
        '✅ Successfully linked invoice to deliveryData $deliveryDataId',
      );

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
