import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class DeliveryUpdateDatasource {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(String customerId);
  Future<void> updateDeliveryStatus(String customerId, String statusId);
  Future<void> completeDelivery(
    String customerId, {
    required List<InvoiceModel> invoices,
    required List<TransactionModel> transactions,
    required List<ReturnModel> returns,
    required List<DeliveryUpdateModel> deliveryStatus,
  });
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
  Future<void> updateQueueRemarks(
    String customerId,
    String queueCount,
  );
}

class DeliveryUpdateDatasourceImpl implements DeliveryUpdateDatasource {
  const DeliveryUpdateDatasourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  @override
  Future<void> updateQueueRemarks(
    String customerId,
    String queueCount,
  ) async {
    try {
      debugPrint('🔄 Updating queue remarks for customer: $customerId');

      // Update customer record
      await _pocketBaseClient.collection('customers').update(
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
      String customerId) async {
    try {
      debugPrint(
          '🚚 Fetching delivery status choices for customer: $customerId');

      final customerRecord =
          await _pocketBaseClient.collection('customers').getOne(
                customerId,
                expand: 'deliveryStatus',
              );

      final deliveryUpdates = customerRecord.expand['deliveryStatus'] as List?;
      final latestStatus = deliveryUpdates?.isNotEmpty == true
          ? deliveryUpdates!.last.data['title'].toString().toLowerCase()
          : '';

      debugPrint('📍 Latest status for customer $customerId: $latestStatus');

      final allStatuses = await _pocketBaseClient
          .collection('delivery_status_choices')
          .getFullList();

      // Log available status choices
      for (var status in allStatuses) {
        debugPrint(
            '🏷️ Available Status - ID: ${status.id}, Title: ${status.data['title']}');
      }

      // Handle In Transit status
      if (latestStatus == 'in transit') {
        final allowedTitles = ['mark as undelivered', 'arrived'];
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
        final allowedTitles = [
          'mark as undelivered',
          'unloading',
          'waiting for customer'
        ];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      if (latestStatus == 'mark as undelivered') {
        return [];
      }

      if (latestStatus == 'end delivery') {
        return [];
      }

      final assignedTitles = deliveryUpdates
              ?.map((record) => record.data['title'].toString().toLowerCase())
              .toSet() ??
          {};

      debugPrint('📋 Already assigned titles: $assignedTitles');

      return allStatuses
          .where((status) => !assignedTitles
              .contains(status.data['title'].toString().toLowerCase()))
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
      List<RecordModel> allStatuses, List<String> allowedTitles) {
    return allStatuses
        .where((status) => allowedTitles
            .contains(status.data['title'].toString().toLowerCase()))
        .map((record) {
      final statusId = record.id;
      debugPrint(
          '🏷️ Processing status - ID: $statusId, Title: ${record.data['title']}');

      return DeliveryUpdateModel.fromJson({
        'id': statusId, // Explicit ID assignment
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'title': record.data['title'],
        'subtitle': record.data['subtitle'],
      });
    }).toList();
  }

  @override
  Future<void> updateDeliveryStatus(String customerId, String statusId) async {
    try {
      debugPrint(
          '🔄 Processing status update - Customer: $customerId, Status: $statusId');

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
      final deliveryUpdateRecord =
          await _pocketBaseClient.collection('delivery_update').create(body: {
        'customer': customerId,
        'status': statusId,
        'title': statusRecord.data['title'],
        'subtitle': statusRecord.data['subtitle'],
        'created': currentTime,
        'time': currentTime,
        'isAssigned': true,
      });

      debugPrint('📝 Created delivery update: ${deliveryUpdateRecord.id}');

      // Update customer record
      await _pocketBaseClient.collection('customers').update(
        customerId,
        body: {
          'deliveryStatus+': [deliveryUpdateRecord.id],
        },
      );

      debugPrint('✅ Successfully updated customer status');
    } catch (e) {
      debugPrint('❌ Operation failed: ${e.toString()}');
      throw ServerException(
        message: e is ServerException
            ? e.message
            : 'Operation failed: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  @override
  Future<void> completeDelivery(
    String customerId, {
    required List<InvoiceModel> invoices,
    required List<TransactionModel> transactions,
    required List<ReturnModel> returns,
    required List<DeliveryUpdateModel> deliveryStatus,
  }) async {
    try {
      debugPrint('🔄 Processing end delivery for customer: $customerId');

      final customerRecord = await _pocketBaseClient
          .collection('customers')
          .getOne(customerId, expand: 'trip');

      final tripId = customerRecord.expand['trip']?[0].id;
      if (tripId == null) {
        throw const ServerException(
          message: 'Trip ID not found for customer',
          statusCode: '404',
        );
      }

      // Get delivery team using explicit filter
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

      final currentActiveDeliveries = int.tryParse(
              deliveryTeamRecord.data['activeDeliveries']?.toString() ?? '0') ??
          0;
      final currentTotalDelivered = int.tryParse(
              deliveryTeamRecord.data['totalDelivered']?.toString() ?? '0') ??
          0;

      // Update delivery team stats
      await _pocketBaseClient.collection('delivery_team').update(
        deliveryTeamRecord.id,
        body: {
          'activeDeliveries': (currentActiveDeliveries - 1).toString(),
          'totalDelivered': (currentTotalDelivered + 1).toString(),
        },
      );

      // Inside completeDelivery method
      debugPrint('📝 Recording transactions for customer: $customerId');
      debugPrint('💰 Total transactions to record: ${transactions.length}');

// First fetch the latest transactions for this customer
      final customerTransactions = await _pocketBaseClient
          .collection('transactions')
          .getList(filter: 'customer = "$customerId"');

      debugPrint(
          '📊 Found ${customerTransactions.items.length} transactions for customer');

      final transactionIds =
          customerTransactions.items.map((t) => t.id).toList();

      final returnIds = (customerRecord.expand['returnList'] as List?)
              ?.map((r) => r.id)
              .whereType<String>()
              .toList() ??
          [];

      // Get payment method from transactions
      final paymentMode = customerTransactions.items.isNotEmpty
          ? customerTransactions.items.first.data['modeOfPayment']
          : 'cashOnDelivery';
      final completedCustomerData = {
        'deliveryNumber': customerRecord.data['deliveryNumber'],
        'storeName': customerRecord.data['storeName'],
        'ownerName': customerRecord.data['ownerName'],
        'contactNumber': customerRecord.data['contactNumber'],
        'address': customerRecord.data['address'],
        'municipality': customerRecord.data['municipality'],
        'province': customerRecord.data['province'],
        'modeOfPayment': customerRecord.data['modeOfPayment'],
        'timeCompleted': DateTime.now().toUtc().toIso8601String(),
        'totalAmount': customerRecord
            .data['confirmedTotalPayment'], // Use confirmed total payment
        'invoices':
            invoices.map((invoice) => invoice.id).whereType<String>().toList(),
        'transactions': transactionIds,
        'returns': returnIds,
        'deliveryStatus':
            deliveryStatus.map((d) => d.id).whereType<String>().toList(),
        'customer': customerId,
        'trip': tripId,
        'payment_selection': paymentMode,
      };

      final completedCustomerRecord = await _pocketBaseClient
          .collection('completedCustomer')
          .create(body: completedCustomerData);

      debugPrint(
          '✅ Created completed customer record: ${completedCustomerRecord.id}');

      // Update each transaction with completed customer relation
      for (final transactionId in transactionIds) {
        await _pocketBaseClient.collection('transactions').update(
          transactionId,
          body: {
            'completedCustomer': completedCustomerRecord.id,
          },
        );
        debugPrint(
            '✅ Updated transaction $transactionId with completed customer relation');
      }
      debugPrint('✅ Successfully linked all transactions');
      // Update tripticket with completed customer
      await _pocketBaseClient.collection('tripticket').update(
        tripId,
        body: {
          'completedCustomer+': [completedCustomerRecord.id],
        },
      );
      debugPrint('✅ Updated trip ticket with completed customer');

      debugPrint('✅ Successfully completed delivery process');
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
    final customerRecords = await _pocketBaseClient.collection('customers').getFullList(
      filter: 'trip = "$actualTripId"',
      expand: 'deliveryStatus',
    );

    final totalCustomers = customerRecords.length;
    debugPrint('📦 Total customers in trip: $totalCustomers');

   final completedDeliveries = customerRecords.where((customer) {
  final deliveryStatuses = customer.expand['deliveryStatus'] as List? ?? [];
  final hasEndDelivery = deliveryStatuses.any((status) {
    final title = status.data['title'].toString().toLowerCase();
    if (title == 'end delivery') {
      debugPrint('   ✅ Customer ${customer.data['storeName']} has End Delivery status');
      return true;
    }
    if (title == 'mark as undelivered') {
      debugPrint('   ⚠️ Customer ${customer.data['storeName']} is marked Undelivered');
      return true;
    }
    return false;
  });
  return hasEndDelivery;
}).length;


    debugPrint('📊 Delivery Status Summary:');
    debugPrint('   - Total Customers: $totalCustomers');
    debugPrint('   - Completed Deliveries: $completedDeliveries');
    debugPrint('   - Pending Deliveries: ${totalCustomers - completedDeliveries}');

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
        final hasPendingStatus =
            existingStatuses.any((status) => status.data['title'] == 'Pending');

        if (!hasPendingStatus) {
          final currentTime = DateTime.now().toIso8601String();
          final deliveryUpdateRecord = await _pocketBaseClient
              .collection('delivery_update')
              .create(body: {
            'customer': customerId,
            'status': pendingStatus.id,
            'title': pendingStatus.data['title'],
            'subtitle': pendingStatus.data['subtitle'],
            'created': currentTime,
            'time': currentTime,
            'isAssigned': true,
          });

          await _pocketBaseClient.collection('customers').update(
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

      final deliveryUpdateRecord =
          await _pocketBaseClient.collection('delivery_update').create(
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

      await _pocketBaseClient.collection('customers').update(
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
