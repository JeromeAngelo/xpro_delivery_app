import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class DeliveryUpdateLocalDatasource {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(String customerId);
  Future<void> updateDeliveryStatus(String customerId, String statusId);
  Future<void> completeDelivery(DeliveryDataEntity deliveryData);
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  );
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  );
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  });
  Future<void> updateQueueRemarks(
  String statusId,
  String remarks,
  String image,
) ;
  Future<DataMap> checkEndDeliverStatus(String tripId);
  Future<void> initializePendingStatus(List<String> customerIds);
}

class DeliveryUpdateLocalDatasourceImpl
    implements DeliveryUpdateLocalDatasource {
  final Box<DeliveryUpdateModel> _deliveryUpdateBox;
  final Box<DeliveryDataModel> _customerBox;

  DeliveryUpdateLocalDatasourceImpl(this._deliveryUpdateBox, this._customerBox);

  Future<void> _autoSave(DeliveryUpdateModel update) async {
    try {
      if (update.title == null || update.pocketbaseId.isEmpty) {
        debugPrint('⚠️ Skipping invalid delivery update');
        return;
      }

      debugPrint(
        '🔍 Processing update: ${update.title} (ID: ${update.pocketbaseId})',
      );

      final existingUpdate =
          _deliveryUpdateBox
              .query(
                DeliveryUpdateModel_.pocketbaseId.equals(update.pocketbaseId),
              )
              .build()
              .findFirst();

      if (existingUpdate != null) {
        debugPrint('🔄 Updating existing status: ${update.title}');
        update.objectBoxId = existingUpdate.objectBoxId;
      } else {
        debugPrint('➕ Adding new status: ${update.title}');
      }

      _deliveryUpdateBox.put(update);
      final totalUpdates = _deliveryUpdateBox.count();
      debugPrint('📊 Current total valid updates: $totalUpdates');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(
    String customerId,
  ) async {
    try {
      final updates =
          _deliveryUpdateBox
              .query(DeliveryUpdateModel_.customer.equals(customerId))
              .build()
              .find();

      debugPrint('📊 Delivery Updates for Customer $customerId:');
      debugPrint('   📦 Total Updates: ${updates.length}');
      debugPrint('   📝 Status Timeline:');
      for (var update in updates) {
        debugPrint('      ${update.title}: ${update.created}');
      }

      return updates;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  ) async {
    final Map<String, List<DeliveryUpdateModel>> result = {};

    try {
      debugPrint('📦 Fetching bulk delivery status choices from local DB...');

      for (final customerId in customerIds) {
        try {
          final updates =
              _deliveryUpdateBox
                  .query(DeliveryUpdateModel_.customer.equals(customerId))
                  .build()
                  .find();

          debugPrint('📊 Delivery Updates for Customer $customerId:');
          debugPrint('   📦 Total Updates: ${updates.length}');
          debugPrint('   📝 Status Timeline:');
          for (var update in updates) {
            debugPrint('      ${update.title}: ${update.created}');
          }

          result[customerId] = updates;
        } catch (e) {
          debugPrint('❌ Failed to fetch local statuses for $customerId: $e');
          result[customerId] = [];
        }
      }

      return result;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateDeliveryStatus(String customerId, String statusId) async {
    try {
      debugPrint('💾 Updating delivery status for customer: $customerId');
      debugPrint('   🏷️ New Status ID: $statusId');

      final query =
          _deliveryUpdateBox
              .query(DeliveryUpdateModel_.customer.equals(customerId))
              .build();

      final updates = query.find();
      query.close();

      for (var update in updates) {
        update.isAssigned = true;
        await _autoSave(update);
      }

      debugPrint('✅ Status update completed');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  ) async {
    try {
      debugPrint('💾 Bulk updating delivery status');
      debugPrint('   📦 Customers: $customerIds');
      debugPrint('   🏷️ New Status ID: $statusId');

      // Iterate through each customer
      for (final customerId in customerIds) {
        try {
          final query =
              _deliveryUpdateBox
                  .query(DeliveryUpdateModel_.customer.equals(customerId))
                  .build();

          final updates = query.find();
          query.close();

          for (var update in updates) {
            update.isAssigned = true;
            update.id = statusId; // ✅ update status field locally
            await _autoSave(update);
          }

          debugPrint('✅ Local status updated for customer: $customerId');
        } catch (e) {
          debugPrint('⚠️ Failed to update local status for $customerId: $e');
          // continue updating next customer
        }
      }

      debugPrint(
        '🎉 Local bulk update completed for ${customerIds.length} customers',
      );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> completeDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint(
        '💾 LOCAL: Processing delivery completion for delivery data: ${deliveryData.id}',
      );

      // Extract delivery data ID
      final deliveryDataId = deliveryData.id;
      if (deliveryDataId == null || deliveryDataId.isEmpty) {
        debugPrint('❌ LOCAL: Invalid delivery data ID');
        throw const CacheException(message: 'Invalid delivery data ID');
      }

      // Get trip ID from delivery data
      final tripId = deliveryData.trip.target?.id;
      if (tripId == null) {
        debugPrint('❌ LOCAL: Trip ID not found for delivery data');
        throw const CacheException(
          message: 'Trip ID not found for delivery data',
        );
      }

      debugPrint('🚛 LOCAL: Found trip ID: $tripId');

      // Create a "Mark as Received" delivery status update for local storage
      final receivedStatus = DeliveryUpdateModel(
        title: 'End Deliver',
        subtitle: 'Delivery Completed',
        time: DateTime.now(),
        isAssigned: true,
        customer: deliveryDataId,
        created: DateTime.now(),
        updated: DateTime.now(),
        //remarks: 'Delivery completed - package marked as received',
      );

      // Store the delivery status update locally
      await _autoSave(receivedStatus);

      // Update customer's delivery status relation if customer exists in local storage
      final customer =
          _customerBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataId))
              .build()
              .findFirst();

      if (customer != null) {
        customer.deliveryUpdates.add(receivedStatus);
        _customerBox.put(customer);
        debugPrint('✅ LOCAL: Updated customer delivery status');
      } else {
        debugPrint(
          '⚠️ LOCAL: Customer not found in local storage for delivery data: $deliveryDataId',
        );
      }

      debugPrint('✅ LOCAL: Successfully processed delivery completion');
      debugPrint(
        '📊 LOCAL: Delivery marked as completed with "Mark as Received" status',
      );
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Error processing delivery completion: ${e.toString()}',
      );
      throw CacheException(
        message: 'Failed to complete delivery locally: ${e.toString()}',
      );
    }
  }

  @override
  Future<DataMap> checkEndDeliverStatus(String tripId) async {
    try {
      debugPrint('🔍 LOCAL: Checking end delivery status for trip: $tripId');

      // Get customers filtered by trip ID
      final customers =
          _customerBox
              .query(DeliveryDataModel_.tripId.equals(tripId))
              .build()
              .find();

      final totalCustomers = customers.length;

      final completedDeliveries =
          customers.where((customer) {
            return customer.deliveryUpdates.any((status) {
              final statusTitle = status.title?.toLowerCase().trim();
              return statusTitle == 'end delivery' ||
                  statusTitle == 'mark as undelivered';
            });
          }).length;

      debugPrint('📊 LOCAL: Delivery Status Summary for Trip: $tripId');
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
      debugPrint('❌ LOCAL: Error checking end delivery status - $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> initializePendingStatus(List<String> customerIds) async {
    try {
      debugPrint('🔄 LOCAL: Initializing pending status');

      for (final customerId in customerIds) {
        final customer =
            _customerBox
                .query(DeliveryDataModel_.pocketbaseId.equals(customerId))
                .build()
                .findFirst();

        if (customer != null) {
          final pendingStatus = DeliveryUpdateModel(
            title: 'Pending',
            subtitle: 'Waiting for delivery',
            isAssigned: true,
            customer: customerId,
            created: DateTime.now(),
          );

          await _autoSave(pendingStatus);
          customer.deliveryUpdates.add(pendingStatus);
          _customerBox.put(customer);
        }
      }

      debugPrint('✅ LOCAL: Successfully initialized pending status');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to initialize pending status - $e');
      throw CacheException(message: e.toString());
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
      debugPrint(
        '💾 LOCAL: Creating delivery status for customer: $customerId',
      );

      final newStatus = DeliveryUpdateModel(
        title: title,
        subtitle: subtitle,
        time: time,
        isAssigned: true,
        customer: customerId,
        image: image,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      await _autoSave(newStatus);

      // Update customer's delivery status relation
      final customer =
          _customerBox
              .query(DeliveryDataModel_.pocketbaseId.equals(customerId))
              .build()
              .findFirst();

      if (customer != null) {
        customer.deliveryUpdates.add(newStatus);
        _customerBox.put(customer);
      }

      debugPrint('✅ LOCAL: Successfully created delivery status');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to create delivery status - $e');
      throw CacheException(message: e.toString());
    }
  }

 @override
Future<void> updateQueueRemarks(
  String statusId,
  String remarks,
  String image,
) async {
  try {
    debugPrint('💾 LOCAL: Updating queue remarks for status: $statusId');

    // 🔎 Find existing status by ID
    final query = _deliveryUpdateBox
        .query(DeliveryUpdateModel_.pocketbaseId.equals(statusId))
        .build();
    final existingStatus = query.findFirst();
    query.close();

    if (existingStatus == null) {
      throw CacheException(message: 'Status with ID $statusId not found locally');
    }

    // 📝 Update fields
    existingStatus.remarks = remarks;
    existingStatus.time = DateTime.now();
    if (image.isNotEmpty) {
      existingStatus.image = image; // just store path locally
    }

    await _autoSave(existingStatus);

    // 🔄 Update customer relationship if needed
    final customer = _customerBox
        .query(DeliveryDataModel_.pocketbaseId.equals(existingStatus.customer ?? ''))
        .build()
        .findFirst();

    if (customer != null) {
      final index = customer.deliveryUpdates.indexWhere(
        (u) => u.id == statusId,
      );
      if (index != -1) {
        customer.deliveryUpdates[index] = existingStatus;
        _customerBox.put(customer);
      }
    }

    debugPrint('✅ LOCAL: Queue remarks updated successfully');
  } catch (e) {
    debugPrint('❌ LOCAL: Failed to update queue remarks: $e');
    throw CacheException(message: e.toString());
  }
}

}
