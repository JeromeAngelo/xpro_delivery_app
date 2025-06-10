import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class DeliveryUpdateDatasource {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(String customerId);
  Future<void> updateDeliveryStatus(String customerId, String statusId);
  Future<void> completeDelivery(DeliveryDataEntity deliveryData);
  Future<DataMap> checkEndDeliverStatus(String tripId);
  Future<void> initializePendingStatus(List<String> customerIds);
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  });
  Future<void> updateQueueRemarks(String customerId, String queueCount);
}

class DeliveryUpdateDatasourceImpl implements DeliveryUpdateDatasource {
  const DeliveryUpdateDatasourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  @override
  Future<void> updateQueueRemarks(String customerId, String queueCount) async {
    try {
      debugPrint('🔄 Updating queue remarks for customer: $customerId');

      // Update customer record
      await _pocketBaseClient
          .collection('customers')
          .update(
            customerId,
            body: {
              'remarks': queueCount,
              'updated': DateTime.now().toIso8601String(),
            },
          );

      ;

      debugPrint('✅ Queue remarks updated across all collections');
    } catch (e) {
      debugPrint('❌ Failed to update queue remarks: $e');
      throw ServerException(message: e.toString(), statusCode: '404');
    }
  }

  @override
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(
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
              .collection('delivery_status_choices')
              .getFullList();

      // Log available status choices
      for (var status in allStatuses) {
        debugPrint(
          '🏷️ Available Status - ID: ${status.id}, Title: ${status.data['title']}',
        );
      }

      // Handle In Transit status
      if (latestStatus == 'in transit') {
        final allowedTitles = ['arrived', 'mark as undelivered'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      // Handle Waiting for customers

      // Handle Unloading
      if (latestStatus == 'unloading') {
        final allowedTitles = ['mark as received'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      if (latestStatus == 'mark as received') {
        final allowedTitles = ['end delivery'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      // Handle Arrived status
      if (latestStatus == 'arrived') {
        final allowedTitles = ['unloading', 'mark as undelivered'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      if (latestStatus == 'mark as undelivered') {
        return [];
      }

      if (latestStatus == 'end delivery') {
        return [];
      }

      final assignedTitles =
          deliveryUpdates
              ?.map((record) => record.data['title'].toString().toLowerCase())
              .toSet() ??
          {};

      debugPrint('📋 Already assigned titles: $assignedTitles');

      return allStatuses
          .where(
            (status) =>
                !assignedTitles.contains(
                  status.data['title'].toString().toLowerCase(),
                ),
          )
          .map((record) => DeliveryUpdateModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching delivery status choices: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  List<DeliveryUpdateModel> _filterStatusChoices(
    List<RecordModel> allStatuses,
    List<String> allowedTitles,
  ) {
    return allStatuses
        .where(
          (status) => allowedTitles.contains(
            status.data['title'].toString().toLowerCase(),
          ),
        )
        .map((record) {
          final statusId = record.id;
          debugPrint(
            '🏷️ Processing status - ID: $statusId, Title: ${record.data['title']}',
          );

          return DeliveryUpdateModel.fromJson({
            'id': statusId, // Explicit ID assignment
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            'title': record.data['title'],
            'subtitle': record.data['subtitle'],
          });
        })
        .toList();
  }

  @override
  Future<void> updateDeliveryStatus(String customerId, String statusId) async {
    try {
      debugPrint(
        '🔄 Processing status update - Customer: $customerId, Status: $statusId',
      );

      // Validate status ID
      if (statusId.isEmpty) {
        debugPrint('⚠️ Invalid status ID provided');
        throw const ServerException(
          message: 'Invalid status ID',
          statusCode: '400',
        );
      }

      // Get the status record
      final statusRecord = await _pocketBaseClient
          .collection('delivery_status_choices')
          .getOne(statusId);

      debugPrint('✅ Retrieved status: ${statusRecord.data['title']}');

      // Create delivery update with validated data
      final currentTime = DateTime.now().toIso8601String();
      final deliveryUpdateRecord = await _pocketBaseClient
          .collection('delivery_update')
          .create(
            body: {
              // 'customer': customerId,
              'deliveryData': customerId,
              'status': statusId,
              'title': statusRecord.data['title'],
              'subtitle': statusRecord.data['subtitle'],
              'created': currentTime,
              'time': currentTime,
              'isAssigned': true,
            },
          );

      debugPrint('📝 Created delivery update: ${deliveryUpdateRecord.id}');

      // Update customer record
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            customerId,
            body: {
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Successfully updated customer status');
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
  Future<void> completeDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint(
        '🔄 Processing delivery completion for delivery data: ${deliveryData.id}',
      );

      // Extract delivery data ID
      final deliveryDataId = deliveryData.id;
      if (deliveryDataId == null || deliveryDataId.isEmpty) {
        throw const ServerException(
          message: 'Invalid delivery data ID',
          statusCode: '400',
        );
      }

      // Get trip ID from delivery data
      final tripId = deliveryData.trip.target?.id;
      if (tripId == null) {
        throw const ServerException(
          message: 'Trip ID not found for delivery data',
          statusCode: '404',
        );
      }

      debugPrint('🚛 Found trip ID: $tripId');

      // Step 1: Add "End Delivery" status to delivery updates
      debugPrint('📝 Adding "End Delivery" status to delivery updates');

      // Get the "End Delivery" status from delivery_status_choices
      final endDeliveryStatus = await _pocketBaseClient
          .collection('delivery_status_choices')
          .getFirstListItem('title = "End Delivery"');

      // Create delivery update with "End Delivery" status
      final currentTime = DateTime.now().toIso8601String();
      final deliveryUpdateRecord = await _pocketBaseClient
          .collection('delivery_update')
          .create(
            body: {
              'deliveryData': deliveryDataId,
              'status': endDeliveryStatus.id,
              'title': endDeliveryStatus.data['title'],
              'subtitle': endDeliveryStatus.data['subtitle'],
              'created': currentTime,
              'time': currentTime,
              'isAssigned': true,
            },
          );

      debugPrint('✅ Created "End Delivery" update: ${deliveryUpdateRecord.id}');

      // Update delivery data with the new delivery update
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'invoiceStatus': 'delivered',
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Updated delivery data with "End Delivery" status');

      // Step 2: Find delivery receipt for this delivery data
      debugPrint(
        '🔍 Looking for delivery receipt with delivery data: $deliveryDataId',
      );

      final deliveryReceiptRecords = await _pocketBaseClient
          .collection('deliveryReceipt')
          .getList(filter: 'deliveryData = "$deliveryDataId"');

      if (deliveryReceiptRecords.items.isEmpty) {
        throw const ServerException(
          message: 'Delivery receipt not found for this delivery data',
          statusCode: '404',
        );
      }

      final deliveryReceiptRecord = deliveryReceiptRecords.items.first;
      debugPrint('✅ Found delivery receipt: ${deliveryReceiptRecord.id}');

      // Step 3: Extract customer and invoice IDs from delivery data
      debugPrint('🔍 Extracting customer and invoice data from delivery data');

      final customerId = deliveryData.customer.target?.id;
      final invoiceId = deliveryData.invoice.target?.id;

      debugPrint('👤 Customer ID: $customerId');
      debugPrint('📄 Invoice ID: $invoiceId');

      if (customerId == null || customerId.isEmpty) {
        throw const ServerException(
          message: 'Customer ID not found in delivery data',
          statusCode: '404',
        );
      }

      if (invoiceId == null || invoiceId.isEmpty) {
        throw const ServerException(
          message: 'Invoice ID not found in delivery data',
          statusCode: '404',
        );
      }

      // Step 4: Create record in deliveryCollection with customer and invoice
      debugPrint(
        '📝 Creating delivery collection record with customer and invoice',
      );

      final deliveryCollectionData = {
        'deliveryData': deliveryDataId,
        'trip': tripId,
        'deliveryReceipt': deliveryReceiptRecord.id,
        'customer': customerId,
        'invoice': invoiceId,
        'invoiceStatus': 'completed',
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'status': 'completed',
      };

      debugPrint('📋 Delivery collection data:');
      debugPrint('   - Delivery Data: $deliveryDataId');
      debugPrint('   - Trip: $tripId');
      debugPrint('   - Delivery Receipt: ${deliveryReceiptRecord.id}');
      debugPrint('   - Customer: $customerId');
      debugPrint('   - Invoice: $invoiceId');
      debugPrint('   - Status: completed');

      final deliveryCollectionRecord = await _pocketBaseClient
          .collection('deliveryCollection')
          .create(body: deliveryCollectionData);

      debugPrint(
        '✅ Created delivery collection record: ${deliveryCollectionRecord.id}',
      );

      // Step 5: Update delivery team stats
      debugPrint('🔄 Updating delivery team statistics');

      // Get delivery team using trip ID
      final deliveryTeamRecords = await _pocketBaseClient
          .collection('delivery_team')
          .getList(filter: 'tripTicket = "$tripId"');

      if (deliveryTeamRecords.items.isEmpty) {
        throw const ServerException(
          message: 'Delivery team not found for this trip',
          statusCode: '404',
        );
      }

      final deliveryTeamRecord = deliveryTeamRecords.items.first;
      debugPrint('✅ Found delivery team: ${deliveryTeamRecord.id}');

      // Calculate new stats
      final currentActiveDeliveries =
          int.tryParse(
            deliveryTeamRecord.data['activeDeliveries']?.toString() ?? '0',
          ) ??
          0;

      final currentTotalDelivered =
          int.tryParse(
            deliveryTeamRecord.data['totalDelivered']?.toString() ?? '0',
          ) ??
          0;

      final newActiveDeliveries =
          (currentActiveDeliveries - 1).clamp(0, double.infinity).toInt();
      final newTotalDelivered = currentTotalDelivered + 1;

      debugPrint('📊 Delivery team stats update:');
      debugPrint(
        '   - Active deliveries: $currentActiveDeliveries -> $newActiveDeliveries',
      );
      debugPrint(
        '   - Total delivered: $currentTotalDelivered -> $newTotalDelivered',
      );

      // Update delivery team stats
      await _pocketBaseClient
          .collection('delivery_team')
          .update(
            deliveryTeamRecord.id,
            body: {
              'activeDeliveries': newActiveDeliveries.toString(),
              'totalDelivered': newTotalDelivered.toString(),
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Updated delivery team statistics');

      // Step 6: Update trip ticket with completed delivery collection
      debugPrint('🔄 Updating trip ticket with completed delivery');

      await _pocketBaseClient
          .collection('tripticket')
          .update(
            tripId,
            body: {
              'deliveryCollection+': [deliveryCollectionRecord.id],
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Updated trip ticket with delivery collection');
      debugPrint(
        '🎉 Successfully completed delivery process with customer and invoice data',
      );
    } catch (e) {
      debugPrint('❌ Failed to complete delivery: ${e.toString()}');
      throw ServerException(
        message: 'Failed to complete delivery: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<DataMap> checkEndDeliverStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end delivery status for trip: $tripId');

      // Extract trip ID if received as JSON
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      // Get customers using trip ID
      final customerRecords = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'deliveryUpdates',
          );

      final totalCustomers = customerRecords.length;
      debugPrint('📦 Total customers in trip: $totalCustomers');

      final completedDeliveries =
          customerRecords.where((customer) {
            final deliveryStatuses =
                customer.expand['deliveryUpdates'] as List? ?? [];
            final hasEndDelivery = deliveryStatuses.any((status) {
              final title = status.data['title'].toString().toLowerCase();
              if (title == 'end delivery') {
                debugPrint(
                  '   ✅ Customer ${customer.data['storeName']} has End Delivery status',
                );
                return true;
              }
              if (title == 'mark as undelivered') {
                debugPrint(
                  '   ⚠️ Customer ${customer.data['storeName']} is marked Undelivered',
                );
                return true;
              }
              return false;
            });
            return hasEndDelivery;
          }).length;

      debugPrint('📊 Delivery Status Summary:');
      debugPrint('   - Total Customers: $totalCustomers');
      debugPrint('   - Completed Deliveries: $completedDeliveries');
      debugPrint(
        '   - Pending Deliveries: ${totalCustomers - completedDeliveries}',
      );

      return {
        'total': totalCustomers,
        'completed': completedDeliveries,
        'pending': totalCustomers - completedDeliveries,
      };
    } catch (e) {
      debugPrint('❌ Error checking end delivery status: $e');
      throw ServerException(
        message: 'Failed to check end delivery status: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> initializePendingStatus(List<String> customerIds) async {
    try {
      debugPrint('🔄 Initializing pending status for customers');

      final pendingStatus = await _pocketBaseClient
          .collection('delivery_status_choices')
          .getFirstListItem('title = "Pending"');

      for (final customerId in customerIds) {
        // Check if customer already has a pending status
        final customerRecord = await _pocketBaseClient
            .collection('customers')
            .getOne(customerId, expand: 'deliveryStatus');

        final existingStatuses =
            customerRecord.expand['deliveryStatus'] as List? ?? [];
        final hasPendingStatus = existingStatuses.any(
          (status) => status.data['title'] == 'Pending',
        );

        if (!hasPendingStatus) {
          final currentTime = DateTime.now().toIso8601String();
          final deliveryUpdateRecord = await _pocketBaseClient
              .collection('delivery_update')
              .create(
                body: {
                  'customer': customerId,
                  'deliveryData': customerId,
                  'status': pendingStatus.id,
                  'title': pendingStatus.data['title'],
                  'subtitle': pendingStatus.data['subtitle'],
                  'created': currentTime,
                  'time': currentTime,
                  'isAssigned': true,
                },
              );

          await _pocketBaseClient
              .collection('deliveryData')
              .update(
                customerId,
                body: {
                  'deliveryStatus': [deliveryUpdateRecord.id],
                },
              );
        }
      }

      debugPrint('✅ Successfully initialized pending status');
    } catch (e) {
      debugPrint('❌ Failed to initialize pending status: $e');
      throw ServerException(
        message: 'Failed to initialize pending status: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  }) async {
    try {
      debugPrint('📝 Creating delivery status for customer: $customerId');

      final files = <String, MultipartFile>{};

      if (image.isNotEmpty) {
        final imageBytes = await File(image).readAsBytes();
        files['image'] = MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'delivery_status_image.jpg',
        );
      }

      final deliveryUpdateRecord = await _pocketBaseClient
          .collection('delivery_update')
          .create(
            body: {
              'customer': customerId,
              'title': title,
              'subtitle': subtitle,
              'time': time.toIso8601String(),
              'isAssigned': true,
            },
            files: files.values.toList(),
          );

      debugPrint('✅ Created delivery status: ${deliveryUpdateRecord.id}');

      await _pocketBaseClient
          .collection('customers')
          .update(
            customerId,
            body: {
              'deliveryStatus+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Updated customer with new delivery status');
    } catch (e) {
      debugPrint('❌ Failed to create delivery status: $e');
      throw ServerException(
        message: 'Failed to create delivery status: $e',
        statusCode: '500',
      );
    }
  }
}
