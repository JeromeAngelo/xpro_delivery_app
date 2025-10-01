import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../enums/invoice_status.dart';

abstract class DeliveryDataRemoteDataSource {
  // Add this new method
  Future<List<DeliveryDataModel>> syncDeliveryDataByTripId(String tripId);

  // Get all delivery data
  Future<List<DeliveryDataModel>> getAllDeliveryData();

  // Get all delivery data by trip ID
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId);

  // Get delivery data by ID
  Future<DeliveryDataModel> getDeliveryDataById(String id);

  Future<bool> deleteDeliveryData(String id);

  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId);

  Future<DeliveryDataModel> setInvoiceIntoUnloading(String deliveryDataId);

  Future<DeliveryDataModel> setInvoiceIntoUnloaded(String deliveryDataId);

  Future<DeliveryDataModel> setInvoiceIntoCompleted(String deliveryDataId);

  Future<DeliveryDataModel> updateDeliveryLocation(String id, double latitude, double longitude);
}

class DeliveryDataRemoteDataSourceImpl implements DeliveryDataRemoteDataSource {
  const DeliveryDataRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<DeliveryDataModel>> syncDeliveryDataByTripId(
    String tripId,
  ) async {
    try {
      debugPrint('🔄 Syncing delivery data for trip ID: $tripId');

      final result = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            expand:
                'customer,customer.invoices,customer.deliveryStatus,'
                'invoice,invoice.products,invoice.customer,'
                'invoices,invoices.products,invoices.customer,'
                'trip,trip.deliveryTeam,trip.personels,'
                'deliveryUpdates,deliveryUpdates.customer,'
                'invoiceItems,invoiceItems.invoice',
            filter: 'trip = "$tripId"',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${result.length} delivery data records for sync');

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(_processDeliveryDataRecord(record));
      }

      debugPrint(
        '✅ Successfully synced ${deliveryDataList.length} delivery data records',
      );

      return deliveryDataList;
    } catch (e) {
      debugPrint('❌ Failed to sync delivery data by trip ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to sync delivery data by trip ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<DeliveryDataModel>> getAllDeliveryData() async {
    try {
      debugPrint('🔄 Fetching all delivery data');

      final result = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            filter: 'hasTrip = false',
            expand: 'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${result.length} delivery data records');

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(_processDeliveryDataRecord(record));
      }

      return deliveryDataList;
    } catch (e) {
      debugPrint('❌ Failed to fetch delivery data: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load delivery data: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId) async {
    try {
      debugPrint('🔄 Fetching delivery data for trip ID: $tripId');

      final result = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            expand: 'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
            filter: 'trip = "$tripId"',
            sort: 'customer.name',
          );

      debugPrint(
        '✅ Retrieved ${result.length} delivery data records for trip ID: $tripId',
      );

      List<DeliveryDataModel> deliveryDataList = [];

      for (var record in result) {
        deliveryDataList.add(_processDeliveryDataRecord(record));
      }

      return deliveryDataList;
    } catch (e) {
      debugPrint('❌ Failed to fetch delivery data by trip ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load delivery data by trip ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<DeliveryDataModel> getDeliveryDataById(String id) async {
    try {
      debugPrint('🔄 Fetching delivery data with ID: $id');

      final record = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            id,
            expand: 'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      debugPrint('✅ Retrieved delivery data with ID: $id');

      return _processDeliveryDataRecord(record);
    } catch (e) {
      debugPrint('❌ Failed to fetch delivery data by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load delivery data by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteDeliveryData(String id) async {
    try {
      debugPrint('🔄 Deleting delivery data with ID: $id');

      // First, get the delivery data to check its relationships
      final record = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(id);

      // Check if this delivery data is associated with a trip
      if (record.data['trip'] != null && record.data['trip'] != '') {
        debugPrint('⚠️ Cannot delete delivery data that is assigned to a trip');
        throw ServerException(
          message:
              'Cannot delete delivery data that is assigned to a trip. Please unassign it first.',
          statusCode: '400',
        );
      }

      // Delete the delivery data
      await _pocketBaseClient.collection('deliveryData').delete(id);

      debugPrint('✅ Successfully deleted delivery data with ID: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete delivery data: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete delivery data: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  @override
  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId) async {
    try {
      debugPrint('⏱️ Calculating delivery time for delivery data: $deliveryId');

      final record = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(deliveryId, expand: 'deliveryUpdates');

      final deliveryUpdates = record.expand['deliveryUpdates'] as List? ?? [];
      if (deliveryUpdates.isEmpty) {
        debugPrint(
          '⚠️ No delivery updates found for delivery data: $deliveryId',
        );

        // Update with 0 time
        await _updateDeliveryDataTotalTime(deliveryId, 0);
        return 0;
      }

      final sortedUpdates =
          deliveryUpdates.map((update) {
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
        (update) => update.title?.toLowerCase().trim() == 'arrived',
      );

      if (arrivedIndex == -1) {
        debugPrint(
          '⚠️ No "arrived" status found for delivery data: $deliveryId',
        );

        // Update with 0 time
        await _updateDeliveryDataTotalTime(deliveryId, 0);
        return 0;
      }

      // Check for undelivered status
      final undeliveredIndex = sortedUpdates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as undelivered',
      );

      // Get end delivery status
      final endDeliveryIndex = sortedUpdates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'end delivery',
      );

      // Get mark as received status
      final receivedIndex = sortedUpdates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as received',
      );

      // Determine relevant updates based on delivery scenario
      List<DeliveryUpdateModel> relevantUpdates;
      if (undeliveredIndex != -1) {
        // Undelivered scenario - calculate until mark as undelivered
        relevantUpdates = sortedUpdates.sublist(
          arrivedIndex,
          undeliveredIndex + 1,
        );
        debugPrint('📊 Calculating time for undelivered scenario');
      } else if (receivedIndex != -1) {
        // Received scenario - calculate until mark as received
        relevantUpdates = sortedUpdates.sublist(
          arrivedIndex,
          receivedIndex + 1,
        );
        debugPrint('📊 Calculating time for received scenario');
      } else if (endDeliveryIndex != -1) {
        // Normal delivery - include end delivery
        relevantUpdates = sortedUpdates.sublist(
          arrivedIndex,
          endDeliveryIndex + 1,
        );
        debugPrint('📊 Calculating time for normal delivery scenario');
      } else {
        // Fallback to all updates from arrived
        relevantUpdates = sortedUpdates.sublist(arrivedIndex);
        debugPrint('📊 Calculating time for ongoing delivery scenario');
      }

      int totalSeconds = 0;
      for (int i = 0; i < relevantUpdates.length - 1; i++) {
        final currentTime = relevantUpdates[i].time!;
        final nextTime = relevantUpdates[i + 1].time!;
        final diffInSeconds = nextTime.difference(currentTime).inSeconds;
        totalSeconds += diffInSeconds;

        debugPrint(
          'Status: ${relevantUpdates[i].title} -> ${relevantUpdates[i + 1].title}',
        );
        debugPrint(
          'Time: ${_formatTime(currentTime)} -> ${_formatTime(nextTime)}',
        );
        debugPrint(
          'Difference: ${diffInSeconds ~/ 60} minutes ${diffInSeconds % 60} seconds\n',
        );
      }

      final totalMinutes = (totalSeconds / 60).round();

      debugPrint(
        '✅ Total delivery time calculated: $totalMinutes minutes ($totalSeconds seconds)',
      );

      // Update the deliveryData record with the calculated time
      await _updateDeliveryDataTotalTime(deliveryId, totalSeconds);

      return totalMinutes;
    } catch (e) {
      debugPrint('❌ Failed to calculate delivery time: $e');
      throw ServerException(
        message: 'Failed to calculate delivery time: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  /// Update delivery data with total delivery time
  Future<void> _updateDeliveryDataTotalTime(
    String deliveryId,
    int totalSeconds,
  ) async {
    try {
      final timeText = _formatDeliveryTime(totalSeconds);
      debugPrint(
        '💾 Updating delivery data $deliveryId with total time: $timeText',
      );

      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryId,
            body: {
              'totalDeliveryTime': timeText,
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Successfully updated delivery data with total time');
    } catch (e) {
      debugPrint('⚠️ Failed to update delivery data with total time: $e');
      // Don't throw here to avoid breaking the main calculation
    }
  }

  @override
  Future<DeliveryDataModel> setInvoiceIntoUnloading(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 Setting invoice to unloading for delivery data: $deliveryDataId',
      );

      // Step 1: Get delivery data with invoices to extract invoice IDs
      final deliveryRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand: 'invoices',
          );

      // Step 2: Extract invoice IDs from the delivery data
      List<String> invoiceIds = [];
      if (deliveryRecord.expand['invoices'] != null) {
        final invoicesData = deliveryRecord.expand['invoices'];
        if (invoicesData is List) {
          invoiceIds = invoicesData!.map((invoice) => invoice.id).toList();
          debugPrint('📋 Found ${invoiceIds.length} invoices: $invoiceIds');
        }
      }

      if (invoiceIds.isEmpty) {
        debugPrint('⚠️ No invoices found for delivery data: $deliveryDataId');
      } else {
        // Step 3: Update invoiceStatus collection for all matching invoices
        for (String invoiceId in invoiceIds) {
          debugPrint('🔄 Updating invoiceStatus for invoice: $invoiceId');
          
          try {
            // Find invoiceStatus records where invoiceData field matches this invoice ID
            final invoiceStatusRecords = await _pocketBaseClient
                .collection('invoiceStatus')
                .getFullList(
                  filter: 'invoiceData = "$invoiceId"',
                );

            debugPrint('📊 Found ${invoiceStatusRecords.length} invoiceStatus records for invoice: $invoiceId');

            // Update all matching invoiceStatus records
            for (var statusRecord in invoiceStatusRecords) {
              await _pocketBaseClient
                  .collection('invoiceStatus')
                  .update(
                    statusRecord.id,
                    body: {
                      'tripStatus': 'unloading',
                      'updated': DateTime.now().toUtc().toIso8601String(),
                    },
                  );
              
              debugPrint('✅ Updated invoiceStatus record: ${statusRecord.id} to unloading');
            }
          } catch (e) {
            debugPrint('❌ Error updating invoiceStatus for invoice $invoiceId: $e');
            // Continue with other invoices even if one fails
          }
        }
      }

      // Step 4: Update the delivery data with unloading status
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'invoiceStatus': 'unloading',
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Successfully set delivery data invoice status to unloading');

      // Step 5: Get the updated record with expanded relations
      final updatedRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand: 'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      return _processDeliveryDataRecord(updatedRecord);
    } catch (e) {
      debugPrint('❌ Failed to set invoice to unloading: ${e.toString()}');
      throw ServerException(
        message: 'Failed to set invoice to unloading: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<DeliveryDataModel> setInvoiceIntoUnloaded(
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '🔄 Setting invoice to unloaded for delivery data: $deliveryDataId',
      );

      // Step 1: Get delivery data with invoices to extract invoice IDs
      final deliveryRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand: 'invoices',
          );

      // Step 2: Extract invoice IDs from the delivery data
      List<String> invoiceIds = [];
      if (deliveryRecord.expand['invoices'] != null) {
        final invoicesData = deliveryRecord.expand['invoices'];
        if (invoicesData is List) {
          invoiceIds = invoicesData!.map((invoice) => invoice.id).toList();
          debugPrint('📋 Found ${invoiceIds.length} invoices: $invoiceIds');
        }
      }

      if (invoiceIds.isEmpty) {
        debugPrint('⚠️ No invoices found for delivery data: $deliveryDataId');
      } else {
        // Step 3: Update invoiceStatus collection for all matching invoices
        for (String invoiceId in invoiceIds) {
          debugPrint('🔄 Updating invoiceStatus for invoice: $invoiceId');
          
          try {
            // Find invoiceStatus records where invoiceData field matches this invoice ID
            final invoiceStatusRecords = await _pocketBaseClient
                .collection('invoiceStatus')
                .getFullList(
                  filter: 'invoiceData = "$invoiceId"',
                );

            debugPrint('📊 Found ${invoiceStatusRecords.length} invoiceStatus records for invoice: $invoiceId');

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
          } catch (e) {
            debugPrint('❌ Error updating invoiceStatus for invoice $invoiceId: $e');
            // Continue with other invoices even if one fails
          }
        }
      }

      // Step 4: Update the delivery data with unloaded status
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'invoiceStatus': 'unloaded',
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Successfully set delivery data invoice status to unloaded');

      // Step 5: Get the updated record with expanded relations
      final updatedRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand: 'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      return _processDeliveryDataRecord(updatedRecord);
    } catch (e) {
      debugPrint('❌ Failed to set invoice to unloaded: ${e.toString()}');
      throw ServerException(
        message: 'Failed to set invoice to unloaded: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<DeliveryDataModel> setInvoiceIntoCompleted(String deliveryDataId) async {
   try {
      debugPrint(
        '🔄 Setting invoice to unloaded for delivery data: $deliveryDataId',
      );

      // Step 1: Get delivery data with invoices to extract invoice IDs
      final deliveryRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand: 'invoices',
          );

      // Step 2: Extract invoice IDs from the delivery data
      List<String> invoiceIds = [];
      if (deliveryRecord.expand['invoices'] != null) {
        final invoicesData = deliveryRecord.expand['invoices'];
        if (invoicesData is List) {
          invoiceIds = invoicesData!.map((invoice) => invoice.id).toList();
          debugPrint('📋 Found ${invoiceIds.length} invoices: $invoiceIds');
        }
      }

      if (invoiceIds.isEmpty) {
        debugPrint('⚠️ No invoices found for delivery data: $deliveryDataId');
      } else {
        // Step 3: Update invoiceStatus collection for all matching invoices
        for (String invoiceId in invoiceIds) {
          debugPrint('🔄 Updating invoiceStatus for invoice: $invoiceId');
          
          try {
            // Find invoiceStatus records where invoiceData field matches this invoice ID
            final invoiceStatusRecords = await _pocketBaseClient
                .collection('invoiceStatus')
                .getFullList(
                  filter: 'invoiceData = "$invoiceId"',
                );

            debugPrint('📊 Found ${invoiceStatusRecords.length} invoiceStatus records for invoice: $invoiceId');

            // Update all matching invoiceStatus records
            for (var statusRecord in invoiceStatusRecords) {
              await _pocketBaseClient
                  .collection('invoiceStatus')
                  .update(
                    statusRecord.id,
                    body: {
                      'tripStatus': 'delivered',
                      'updated': DateTime.now().toUtc().toIso8601String(),
                    },
                  );
              
              debugPrint('✅ Updated invoiceStatus record: ${statusRecord.id} to unloaded');
            }
          } catch (e) {
            debugPrint('❌ Error updating invoiceStatus for invoice $invoiceId: $e');
            // Continue with other invoices even if one fails
          }
        }
      }

      // Step 4: Update the delivery data with unloaded status
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'invoiceStatus': 'completed',
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Successfully set delivery data invoice status to unloaded');

      // Step 5: Get the updated record with expanded relations
      final updatedRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            deliveryDataId,
            expand: 'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      return _processDeliveryDataRecord(updatedRecord);
    } catch (e) {
      debugPrint('❌ Failed to set invoice to unloaded: ${e.toString()}');
      throw ServerException(
        message: 'Failed to set invoice to unloaded: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  /// Format seconds into readable time format
  String _formatDeliveryTime(int totalSeconds) {
    if (totalSeconds <= 0) {
      return '0 secs';
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add('$hours hr${hours > 1 ? 's' : ''}');
    }

    if (minutes > 0) {
      parts.add('$minutes min${minutes > 1 ? 's' : ''}');
    }

    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds sec${seconds > 1 ? 's' : ''}');
    }

    return parts.join(' and ');
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  // Helper method to process a delivery data record
  DeliveryDataModel _processDeliveryDataRecord(RecordModel record) {
    // Process customer data
    CustomerDataModel? customerModel;
    if (record.expand['customer'] != null) {
      final customerData = record.expand['customer'];
      if (customerData is List && customerData!.isNotEmpty) {
        final customerRecord = customerData[0];
        customerModel = CustomerDataModel.fromJson({
          'id': customerRecord.id,
          'collectionId': customerRecord.collectionId,
          'collectionName': customerRecord.collectionName,
          ...customerRecord.data,
        });
      }
    } else if (record.data['customer'] != null) {
      customerModel = CustomerDataModel(id: record.data['customer'].toString());
    }

    // Process invoice data
    InvoiceDataModel? invoiceModel;
    if (record.expand['invoice'] != null) {
      final invoiceData = record.expand['invoice'];
      if (invoiceData is List && invoiceData!.isNotEmpty) {
        final invoiceRecord = invoiceData[0];
        invoiceModel = InvoiceDataModel.fromJson({
          'id': invoiceRecord.id,
          'collectionId': invoiceRecord.collectionId,
          'collectionName': invoiceRecord.collectionName,
          ...invoiceRecord.data,
        });
      }
    } else if (record.data['invoice'] != null) {
      invoiceModel = InvoiceDataModel(id: record.data['invoice'].toString());
    }

    // Process invoices data (multiple)
    List<InvoiceDataModel> invoicesList = [];
    if (record.expand['invoices'] != null) {
      final invoicesData = record.expand['invoices'];
      if (invoicesData is List) {
        invoicesList = invoicesData!.map((invoice) {
          return InvoiceDataModel.fromJson({
            'id': invoice.id,
            'collectionId': invoice.collectionId,
            'collectionName': invoice.collectionName,
            ...invoice.data,
            'expand': invoice.expand,
          });
        }).toList();
      }
    } else if (record.data['invoices'] != null &&
        record.data['invoices'] is List) {
      invoicesList = (record.data['invoices'] as List)
          .map((id) => InvoiceDataModel(id: id.toString()))
          .toList();
    }

    // Process trip data
    TripModel? tripModel;
    if (record.expand['trip'] != null) {
      final tripData = record.expand['trip'];
      if (tripData is List && tripData!.isNotEmpty) {
        final tripRecord = tripData[0];
        tripModel = TripModel.fromJson({
          'id': tripRecord.id,
          'collectionId': tripRecord.collectionId,
          'collectionName': tripRecord.collectionName,
          'tripNumberId': tripRecord.data['tripNumberId'],
          'qrCode': tripRecord.data['qrCode'],
          'isAccepted': tripRecord.data['isAccepted'],
          'isEndTrip': tripRecord.data['isEndTrip'],
        });
      }
    } else if (record.data['trip'] != null) {
      tripModel = TripModel(id: record.data['trip'].toString());
    }

    // Process delivery updates
    List<DeliveryUpdateModel> deliveryUpdatesList = [];
    if (record.expand['deliveryUpdates'] != null) {
      final deliveryUpdatesData = record.expand['deliveryUpdates'];
      if (deliveryUpdatesData is List) {
        deliveryUpdatesList =
            deliveryUpdatesData!.map((update) {
              return DeliveryUpdateModel.fromJson({
                'id': update.id,
                'collectionId': update.collectionId,
                'collectionName': update.collectionName,
                'title': update.data['title'],
                'subtitle': update.data['subtitle'],
                'time': update.data['time'],
                'customer': update.data['customer'],
                'isAssigned': update.data['isAssigned'],
                'deliveryNumber': update.data['deliveryNumber'],
              });
            }).toList();
      }
    } else if (record.data['deliveryUpdates'] != null &&
        record.data['deliveryUpdates'] is List) {
      deliveryUpdatesList =
          (record.data['deliveryUpdates'] as List)
              .map((id) => DeliveryUpdateModel(id: id.toString()))
              .toList();
    }

    List<InvoiceItemsModel> invoiceItemsList = [];
    if (record.expand['invoiceItems'] != null) {
      final invoiceItemsData = record.expand['invoiceItems'];
      if (invoiceItemsData is List) {
        invoiceItemsList =
            invoiceItemsData!.map((item) {
              return InvoiceItemsModel.fromJson({
                'id': item.id,
                'collectionId': item.collectionId,
                'collectionName': item.collectionName,
                ...item.data,
              });
            }).toList();
      }
    } else if (record.data['invoiceItems'] != null &&
        record.data['invoiceItems'] is List) {
      invoiceItemsList =
          (record.data['invoiceItems'] as List)
              .map((id) => InvoiceItemsModel(id: id.toString()))
              .toList();
    }

    // UPDATED: Process invoice status with proper enum conversion
    InvoiceStatus? invoiceStatus;
    final invoiceStatusString = record.data['invoiceStatus'];
    if (invoiceStatusString != null && invoiceStatusString is String) {
      try {
        // Convert string to enum
        invoiceStatus = _parseInvoiceStatus(invoiceStatusString);
        debugPrint('✅ Parsed invoice status: ${invoiceStatus.name}');
      } catch (e) {
        debugPrint(
          '⚠️ Failed to parse invoice status "$invoiceStatusString": $e',
        );
        invoiceStatus = InvoiceStatus.none; // Default fallback
      }
    }

    return DeliveryDataModel(
      id: record.id,
      collectionId: record.collectionId,
      collectionName: record.collectionName,
      deliveryNumber: record.data['deliveryNumber'],
      invoiceStatus: invoiceStatus, // Now properly converted to enum
      customer: customerModel,
      invoiceItems: invoiceItemsList,
      invoice: invoiceModel,
      invoices: invoicesList,
      trip: tripModel,
      deliveryUpdates: deliveryUpdatesList,
      paymentMode: record.data['paymentMode']?.toString(),
      storeName: record.data['storeName']?.toString(),
      ownerName: record.data['ownerName']?.toString(),
      contactNumber: record.data['contactNumber']?.toString(),
      barangay: record.data['barangay']?.toString(),
      municipality: record.data['municipality']?.toString(),
      province: record.data['province']?.toString(),
      refID: record.data['refID']?.toString(),
      totalDeliveryTime: record.data['totalDeliveryTime']?.toString(),
      hasTrip: record.data['hasTrip'] as bool? ?? false,
      created: _parseDate(record.data['created']),
      updated: _parseDate(record.data['updated']),
    );
  }

  // ADDED: Helper method to parse invoice status string to enum
  InvoiceStatus _parseInvoiceStatus(String statusString) {
    final normalizedStatus = statusString.toLowerCase().trim();

    switch (normalizedStatus) {
      case 'none':
      case 'pending':
      case '':
        return InvoiceStatus.none;
      case 'truck':
      case 'in_truck':
      case 'intruck':
        return InvoiceStatus.truck;
      case 'unloading':
        return InvoiceStatus.unloading;
      case 'unloaded':
        return InvoiceStatus.unloaded;
      case 'completed':
      case 'complete':
        return InvoiceStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return InvoiceStatus.cancelled;
      default:
        debugPrint(
          '⚠️ Unknown invoice status: "$statusString", defaulting to none',
        );
        return InvoiceStatus.none;
    }
  }

  // ADDED: Helper method to parse date strings
  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('⚠️ Failed to parse date "$value": $e');
      return null;
    }
  }

  @override
  Future<DeliveryDataModel> updateDeliveryLocation(String id, double latitude, double longitude) async {
    try {
      debugPrint('🔄 Updating delivery location for ID: $id');
      debugPrint('📍 Coordinates: Lat: $latitude, Long: $longitude');

      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            id,
            body: {
              'pinLang': latitude,
              'pinLong': longitude,
            },
          );

      debugPrint('✅ Successfully updated delivery location for ID: $id');

      // Get the full record with expanded relationships
      final fullRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(
            id,
            expand: 'customer,invoice,invoices,invoices.products,invoices.customer,trip,deliveryUpdates,invoiceItems',
          );

      return _processDeliveryDataRecord(fullRecord);
    } catch (e) {
      debugPrint('❌ Failed to update delivery location: ${e.toString()}');
      throw ServerException(
        message: 'Failed to update delivery location: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
  
  
}

