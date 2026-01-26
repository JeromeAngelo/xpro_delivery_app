import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';

import '../../../../../../../errors/exceptions.dart';
import '../../../../trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

abstract class DeliveryStatusChoicesRemoteDataSource {
  Future<List<DeliveryStatusChoicesModel>> syncAllDeliveryStatusChoices();
  Future<List<DeliveryStatusChoicesModel>> getAllAssignedDeliveryStatusChoices(
    String customerId,
  );
  Future<void> setEndDelivery(DeliveryDataEntity deliveryData);

  Future<String> updateCustomerStatus(
    String deliveryDataId, // DeliveryData PB ID
    DeliveryStatusChoicesModel status, // ✅ FULL MODEL
  );

  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds);
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesModel statusId,
  );
}

class DeliveryStatusChoicesRemoteDataSourceImpl
    implements DeliveryStatusChoicesRemoteDataSource {
  final PocketBase _pocketBaseClient;

  const DeliveryStatusChoicesRemoteDataSourceImpl(this._pocketBaseClient);

  @override
  Future<List<DeliveryStatusChoicesModel>>
  syncAllDeliveryStatusChoices() async {
    try {
      debugPrint('🔄 [SYNC] Starting sync of ALL delivery status choices...');

      // 1️⃣ Fetch all records from PocketBase
      final records = await _pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFullList(expand: '');

      if (records.isEmpty) {
        debugPrint('⚠️ No delivery status choices found in remote collection.');
        return [];
      }

      debugPrint('📦 Found ${records.length} delivery status choices.');

      // 2️⃣ Convert each PocketBase record → DeliveryStatusChoicesModel
      final choices =
          records.map((record) {
            final json = record.toJson();

            final model = DeliveryStatusChoicesModel(
              id: json['id']?.toString(),
              collectionId: json['collectionId']?.toString(),
              collectionName:
                  json['collectionName']?.toString() ?? 'deliveryStatusChoices',
              title: json['title']?.toString(),
              subtitle: json['subtitle']?.toString(),
              created:
                  json['created'] != null
                      ? DateTime.tryParse(json['created'])
                      : null,
              updated:
                  json['updated'] != null
                      ? DateTime.tryParse(json['updated'])
                      : null,
            );

            debugPrint(
              '   • Synced Status: ${model.title} | Subtitle: ${model.subtitle} | ID: ${model.id}',
            );

            return model;
          }).toList();

      debugPrint(
        '✅ [SYNC COMPLETE] Synced ${choices.length} delivery status choices.',
      );
      return choices;
    } catch (e) {
      debugPrint('❌ [SYNC ERROR] Failed to sync delivery status choices: $e');
      throw ServerException(
        message: 'Failed to sync delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<DeliveryStatusChoicesModel>> getAllAssignedDeliveryStatusChoices(
    String customerId,
  ) async {
    try {
      debugPrint(
        '🚚 Fetching delivery status choices for customer: $customerId',
      );

      final customerRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(customerId, expand: 'deliveryUpdates');

      final deliveryUpdates = customerRecord.expand['deliveryUpdates'] as List?;
      final latestStatus =
          deliveryUpdates?.isNotEmpty == true
              ? deliveryUpdates!.last.data['title'].toString().toLowerCase()
              : '';

      debugPrint('📍 Latest status for customer $customerId: $latestStatus');

      final allStatuses =
          await _pocketBaseClient
              .collection('deliveryStatusChoices')
              .getFullList();

      // Log available status choices
      for (var status in allStatuses) {
        debugPrint(
          '🏷️ Available Status - ID: ${status.id}, Title: ${status.data['title']}',
        );
      }

      // Apply status rules
      final allowedTitles = <String>[];
      switch (latestStatus) {
        case 'in transit':
          allowedTitles.addAll(['arrived', 'mark as undelivered']);
          break;
        case 'waiting for customer':
          allowedTitles.addAll([
            'unloading',
            'mark as undelivered',
            'invoices in queue',
          ]);
          break;
        case 'invoices in queue':
          allowedTitles.addAll(['unloading', 'mark as undelivered']);
          break;
        case 'unloading':
          allowedTitles.addAll(['mark as received']);
          break;
        case 'mark as received':
          allowedTitles.addAll(['end delivery']);
          break;
        case 'arrived':
          allowedTitles.addAll([
            'unloading',
            'mark as undelivered',
            'waiting for customer',
            'invoices in queue',
          ]);
          break;
        case 'mark as undelivered':
        case 'end delivery':
          return [];
      }

      final assignedTitles =
          deliveryUpdates
              ?.map((record) => record.data['title'].toString().toLowerCase())
              .toSet() ??
          {};

      debugPrint('📋 Already assigned titles: $assignedTitles');

      // Filter allowed and not assigned yet
      final filteredStatuses =
          allStatuses
              .where(
                (status) => allowedTitles.contains(
                  status.data['title'].toString().toLowerCase(),
                ),
              )
              .where(
                (status) =>
                    !assignedTitles.contains(
                      status.data['title'].toString().toLowerCase(),
                    ),
              )
              .map((record) {
                final statusId = record.id;
                debugPrint(
                  '🏷️ Processing status - ID: $statusId, Title: ${record.data['title']}',
                );

                return DeliveryStatusChoicesModel(
                  id: statusId,
                  title: record.data['title'],
                  subtitle: record.data['subtitle'],
                  collectionId: record.collectionId,
                  collectionName: record.collectionName,
                );
              })
              .toList();

      return filteredStatuses;
    } catch (e) {
      debugPrint('❌ Error fetching delivery status choices: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<String> updateCustomerStatus(
    String deliveryDataId,
    DeliveryStatusChoicesModel status,
  ) async {
    try {
      debugPrint(
        '🔄 Processing status update - DeliveryData: $deliveryDataId, '
        'Status: ${status.title} (${status.id})',
      );

      // ---------------------------------------------------
      // 0️⃣ VALIDATE
      // ---------------------------------------------------
      if (status.id!.isEmpty) {
        debugPrint('⚠️ Invalid status PB ID provided');
        throw const ServerException(
          message: 'Invalid status ID',
          statusCode: '400',
        );
      }

      // ---------------------------------------------------
      // 1️⃣ CREATE DeliveryUpdate (COPY DATA)
      // ---------------------------------------------------
      final currentTime = DateTime.now().toIso8601String();

      final deliveryUpdateRecord = await _pocketBaseClient
          .collection('deliveryUpdate')
          .create(
            body: {
              'deliveryData': deliveryDataId,
              'status': status.id, // 🔑 PB relation
              'title': status.title, // 📋 copied
              'subtitle': status.subtitle, // 📋 copied
              'created': currentTime,
              'time': currentTime,
              'isAssigned': true,
            },
          );

      debugPrint('📝 Created delivery update: ${deliveryUpdateRecord.id}');

      // ---------------------------------------------------
      // 2️⃣ ATTACH DeliveryUpdate → DeliveryData
      // ---------------------------------------------------
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Successfully updated deliveryData');

      // ---------------------------------------------------
      // 3️⃣ CREATE NOTIFICATION (REMOTE ONLY)
      // ---------------------------------------------------
      final deliveryDataRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryDataId);

      final tripId = deliveryDataRecord.data['trip'];

      debugPrint('📦 Found trip for notification: $tripId');

      await _pocketBaseClient
          .collection('notifications')
          .create(
            body: {
              'delivery': deliveryDataRecord.id,
              'status': deliveryUpdateRecord.id,
              'trip': tripId,
              'type': 'deliveryUpdate',
              'created': currentTime,
            },
          );

      debugPrint('✅ Successfully created notification');

      // Return created delivery update id to caller so local records can be reconciled
      return deliveryUpdateRecord.id;
    } catch (e) {
      debugPrint('❌ Operation failed: ${e.toString()}');
      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Operation failed: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  @override
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    DeliveryStatusChoicesModel statusId,
  ) {
    // delegate to async implementation
    return _bulkUpdateDeliveryStatusImpl(customerIds, statusId);
  }

  @override
  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  getAllBulkDeliveryStatusChoices(List<String> customerIds) {
    return _getAllBulkDeliveryStatusChoicesImpl(customerIds);
  }

  // Implementation helpers
  Future<Map<String, List<DeliveryStatusChoicesModel>>>
  _getAllBulkDeliveryStatusChoicesImpl(List<String> customerIds) async {
    final Map<String, List<DeliveryStatusChoicesModel>> result = {};

    try {
      debugPrint(
        '🚚 Fetching bulk delivery status choices for customers: $customerIds',
      );

      // Fetch all status choices once
      final allStatuses =
          await _pocketBaseClient
              .collection('deliveryStatusChoices')
              .getFullList();

      for (final customerId in customerIds) {
        try {
          final customerRecord = await _pocketBaseClient
              .collection('deliveryData')
              .getOne(customerId, expand: 'deliveryUpdates');

          final deliveryUpdates =
              customerRecord.expand['deliveryUpdates'] as List?;
          final latestStatus =
              deliveryUpdates?.isNotEmpty == true
                  ? deliveryUpdates!.last.data['title'].toString().toLowerCase()
                  : '';

          debugPrint(
            '📍 Latest status for customer $customerId: $latestStatus',
          );

          final allowedTitles = <String>[];
          switch (latestStatus) {
            case 'in transit':
              allowedTitles.addAll(['arrived', ]);
              break;
            case 'waiting for customer':
              allowedTitles.addAll([
                'unloading',
                
                'invoices in queue',
              ]);
              break;
            case 'invoices in queue':
              allowedTitles.addAll(['unloading', ]);
              break;
            case 'unloading':
              allowedTitles.addAll(['mark as received']);
              break;
            case 'mark as received':
              allowedTitles.addAll(['']);
              break;
            case 'arrived':
              allowedTitles.addAll([
                'unloading',
                'mark as undelivered',
                'waiting for customer',
                'invoices in queue',
              ]);
              break;
            case 'mark as undelivered':
            case 'end delivery':
              result[customerId] = [];
              continue;
          }

          final assignedTitles =
              deliveryUpdates
                  ?.map(
                    (record) => record.data['title'].toString().toLowerCase(),
                  )
                  .toSet() ??
              {};

          debugPrint('📋 Already assigned titles: $assignedTitles');

          final filteredStatuses =
              allStatuses
                  .where(
                    (status) => allowedTitles.contains(
                      status.data['title'].toString().toLowerCase(),
                    ),
                  )
                  .where(
                    (status) =>
                        !assignedTitles.contains(
                          status.data['title'].toString().toLowerCase(),
                        ),
                  )
                  .map(
                    (record) => DeliveryStatusChoicesModel(
                      id: record.id,
                      title: record.data['title'],
                      subtitle: record.data['subtitle'],
                      collectionId: record.collectionId,
                      collectionName: record.collectionName,
                    ),
                  )
                  .toList();

          result[customerId] = filteredStatuses;
          debugPrint(
            '✅ Prepared ${filteredStatuses.length} choices for $customerId',
          );
        } catch (e) {
          debugPrint('❌ Failed to fetch statuses for $customerId: $e');
          result[customerId] = [];
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error in bulk status fetch: ${e.toString()}');
      throw ServerException(
        message:
            'Failed to fetch bulk delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  Future<void> _bulkUpdateDeliveryStatusImpl(
    List<String> customerIds,
    DeliveryStatusChoicesModel status,
  ) async {
    try {
      debugPrint(
        '🔄 Processing bulk status update - Customers: $customerIds, Status: ${status.id}',
      );

      if (status.id == null || status.id!.isEmpty) {
        debugPrint('⚠️ Invalid status ID provided');
        throw const ServerException(
          message: 'Invalid status ID',
          statusCode: '400',
        );
      }

      final currentTime = DateTime.now().toIso8601String();

      for (final customerId in customerIds) {
        try {
          debugPrint('➡️ Updating customer: $customerId');

          final deliveryUpdateRecord = await _pocketBaseClient
              .collection('deliveryUpdate')
              .create(
                body: {
                  'deliveryData': customerId,
                  'status': status.id,
                  'title': status.title,
                  'subtitle': status.subtitle,
                  'created': currentTime,
                  'time': currentTime,
                  'isAssigned': true,
                },
              );

          debugPrint(
            '📝 Created delivery update: ${deliveryUpdateRecord.id} for $customerId',
          );

          await _pocketBaseClient
              .collection('deliveryData')
              .update(
                customerId,
                body: {
                  'deliveryUpdates+': [deliveryUpdateRecord.id],
                },
              );

          debugPrint('✅ Attached update to deliveryData for $customerId');

          // Create notification
          final deliveryDataRecord = await _pocketBaseClient
              .collection('deliveryData')
              .getOne(customerId);
          final tripId = deliveryDataRecord.data['trip'];

          await _pocketBaseClient
              .collection('notifications')
              .create(
                body: {
                  'delivery': deliveryDataRecord.id,
                  'status': deliveryUpdateRecord.id,
                  'trip': tripId,
                  'type': 'deliveryUpdate',
                  'created': currentTime,
                },
              );

          debugPrint('✅ Notification created for $customerId');
        } catch (e) {
          debugPrint('⚠️ Failed to update customer $customerId: $e');
          // continue to next customer
        }
      }

      debugPrint(
        '🎉 Bulk update completed for ${customerIds.length} customers',
      );
    } catch (e) {
      debugPrint('❌ Bulk operation failed: ${e.toString()}');
      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Bulk operation failed: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }
  @override
Future<void> setEndDelivery(DeliveryDataEntity deliveryData) async {
  try {
    debugPrint(
      '🔄 Processing delivery completion for delivery data: ${deliveryData.id}',
    );

    // ---------------------------------------------------
    // 0️⃣ Validate Delivery ID
    // ---------------------------------------------------
    final deliveryDataId = deliveryData.id;
    if (deliveryDataId == null || deliveryDataId.isEmpty) {
      throw const ServerException(
        message: 'Invalid delivery data ID',
        statusCode: '400',
      );
    }

    // ---------------------------------------------------
    // 1️⃣ Resolve Trip ID (REQUIRED)
    // ---------------------------------------------------
    final tripId = deliveryData.trip.target?.id;
    if (tripId == null || tripId.isEmpty) {
      throw const ServerException(
        message: 'Trip ID not found for delivery data',
        statusCode: '404',
      );
    }

    debugPrint('🚛 Found trip ID: $tripId');

    // ---------------------------------------------------
    // 2️⃣ Create "End Delivery" delivery update (REQUIRED)
    // ---------------------------------------------------
    debugPrint('📝 Adding "End Delivery" status');

    final endDeliveryStatus = await _pocketBaseClient
        .collection('deliveryStatusChoices')
        .getFirstListItem('title = "End Delivery"');

    final now = DateTime.now().toIso8601String();

    final deliveryUpdateRecord = await _pocketBaseClient
        .collection('deliveryUpdate')
        .create(
      body: {
        'deliveryData': deliveryDataId,
        'status': endDeliveryStatus.id,
        'title': endDeliveryStatus.data['title'],
        'subtitle': endDeliveryStatus.data['subtitle'],
        'created': now,
        'time': now,
        'isAssigned': true,
      },
    );

    debugPrint('✅ End Delivery update created → ${deliveryUpdateRecord.id}');

    await _pocketBaseClient.collection('deliveryData').update(
      deliveryDataId,
      body: {
        'invoiceStatus': 'delivered',
        'deliveryUpdates+': [deliveryUpdateRecord.id],
      },
    );

    // ---------------------------------------------------
    // 3️⃣ Delivery Receipt (OPTIONAL — NON-BLOCKING)
    // ---------------------------------------------------
    String? deliveryReceiptId;

    try {
      debugPrint('🔍 Looking for delivery receipt');

      final receiptRecords = await _pocketBaseClient
          .collection('deliveryReceipt')
          .getList(filter: 'deliveryData = "$deliveryDataId"');

      if (receiptRecords.items.isNotEmpty) {
        deliveryReceiptId = receiptRecords.items.first.id;
        debugPrint('🧾 Delivery receipt found → $deliveryReceiptId');
      } else {
        debugPrint('⚠️ No delivery receipt found (continuing)');
      }
    } catch (e) {
      debugPrint('⚠️ Delivery receipt lookup failed (ignored): $e');
    }

    // ---------------------------------------------------
    // 4️⃣ Resolve Customer & Invoices (REQUIRED)
    // ---------------------------------------------------
    final customerId = deliveryData.customer.target?.id;
    final invoiceIds =
        deliveryData.invoices.map((invoice) => invoice.id).toList();

    if (customerId == null || customerId.isEmpty) {
      throw const ServerException(
        message: 'Customer ID not found in delivery data',
        statusCode: '404',
      );
    }

    if (invoiceIds.isEmpty) {
      throw const ServerException(
        message: 'No invoices found in delivery data',
        statusCode: '404',
      );
    }

    // ---------------------------------------------------
    // 5️⃣ Create Delivery Collection (REQUIRED)
    // ---------------------------------------------------
    final deliveryCollectionRecord = await _pocketBaseClient
        .collection('deliveryCollection')
        .create(
      body: {
        'deliveryData': deliveryDataId,
        'trip': tripId,
        'deliveryReceipt': deliveryReceiptId, // ✅ can be null
        'customer': customerId,
        'invoice': invoiceIds.first,
        'invoices': invoiceIds,
        'invoiceStatus': 'completed',
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'status': 'completed',
      },
    );

    debugPrint(
      '✅ Delivery collection created → ${deliveryCollectionRecord.id}',
    );

    // ---------------------------------------------------
    // 6️⃣ Update User Performance (OPTIONAL — NON-BLOCKING)
    // ---------------------------------------------------
    try {
      debugPrint('📊 Updating user performance');

      final tripTicket = await _pocketBaseClient
          .collection('tripticket')
          .getOne(tripId);

      final userId = tripTicket.data['user'];

      if (userId != null && userId.toString().isNotEmpty) {
        final perfRecords = await _pocketBaseClient
            .collection('userPerformance')
            .getList(filter: 'user = "$userId"');

        if (perfRecords.items.isNotEmpty) {
          final perf = perfRecords.items.first;

          final success =
              int.tryParse(perf.data['successfulDeliveries']?.toString() ?? '0') ?? 0;
          final total =
              int.tryParse(perf.data['totalDeliveries']?.toString() ?? '0') ?? 0;

          final newSuccess = success + 1;
          final successRate =
              total > 0 ? (newSuccess / total) * 100 : 0;

          await _pocketBaseClient.collection('userPerformance').update(
            perf.id,
            body: {
              'successfulDeliveries': newSuccess.toString(),
              'successRate': successRate.toStringAsFixed(2),
              'updated': DateTime.now().toIso8601String(),
            },
          );

          debugPrint('✅ User performance updated');
        } else {
          debugPrint('⚠️ No user performance record found');
        }
      }
    } catch (e) {
      debugPrint('⚠️ User performance update failed (ignored): $e');
    }

    // ---------------------------------------------------
    // 7️⃣ Update Delivery Team (REQUIRED)
    // ---------------------------------------------------
    final teamRecords = await _pocketBaseClient
        .collection('deliveryTeam')
        .getList(filter: 'tripTicket = "$tripId"');

    if (teamRecords.items.isEmpty) {
      throw const ServerException(
        message: 'Delivery team not found for this trip',
        statusCode: '404',
      );
    }

    final team = teamRecords.items.first;

    final active =
        int.tryParse(team.data['activeDeliveries']?.toString() ?? '0') ?? 0;
    final total =
        int.tryParse(team.data['totalDelivered']?.toString() ?? '0') ?? 0;

    await _pocketBaseClient.collection('deliveryTeam').update(
      team.id,
      body: {
        'activeDeliveries': (active - 1).clamp(0, 999999).toString(),
        'totalDelivered': (total + 1).toString(),
        'updated': DateTime.now().toUtc().toIso8601String(),
      },
    );

    // ---------------------------------------------------
    // 8️⃣ Update Trip Ticket (REQUIRED)
    // ---------------------------------------------------
    await _pocketBaseClient.collection('tripticket').update(
      tripId,
      body: {
        'deliveryCollection+': [deliveryCollectionRecord.id],
        'updated': DateTime.now().toUtc().toIso8601String(),
      },
    );

    debugPrint('🎉 DELIVERY COMPLETED SUCCESSFULLY');
  } catch (e) {
    debugPrint('❌ Failed to complete delivery: $e');
    throw ServerException(
      message: 'Failed to complete delivery: $e',
      statusCode: '500',
    );
  }
}

}
