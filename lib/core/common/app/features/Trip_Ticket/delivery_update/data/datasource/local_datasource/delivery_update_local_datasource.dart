import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class DeliveryUpdateLocalDatasource {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(String customerId);
  Future<void> updateDeliveryStatus(String customerId, String statusId);
  Future<void> completeDelivery(
    String customerId, {
    required List<InvoiceModel> invoices,
    required List<TransactionModel> transactions,
    required List<ReturnModel> returns,
    required List<DeliveryUpdateModel> deliveryStatus,
  });
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
 Future<DataMap> checkEndDeliverStatus(String tripId);
  Future<void> initializePendingStatus(List<String> customerIds);
}

class DeliveryUpdateLocalDatasourceImpl
    implements DeliveryUpdateLocalDatasource {
  final Box<DeliveryUpdateModel> _deliveryUpdateBox;
  final Box<CustomerModel> _customerBox;

  DeliveryUpdateLocalDatasourceImpl(this._deliveryUpdateBox, this._customerBox);

  Future<void> _autoSave(DeliveryUpdateModel update) async {
    try {
      if (update.title == null || update.pocketbaseId.isEmpty) {
        debugPrint('⚠️ Skipping invalid delivery update');
        return;
      }

      debugPrint(
          '🔍 Processing update: ${update.title} (ID: ${update.pocketbaseId})');

      final existingUpdate = _deliveryUpdateBox
          .query(DeliveryUpdateModel_.pocketbaseId.equals(update.pocketbaseId))
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
      String customerId) async {
    try {
      final updates = _deliveryUpdateBox
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
  Future<void> updateDeliveryStatus(String customerId, String statusId) async {
    try {
      debugPrint('💾 Updating delivery status for customer: $customerId');
      debugPrint('   🏷️ New Status ID: $statusId');

      final query = _deliveryUpdateBox
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
  Future<void> completeDelivery(
    String customerId, {
    required List<InvoiceModel> invoices,
    required List<TransactionModel> transactions,
    required List<ReturnModel> returns,
    required List<DeliveryUpdateModel> deliveryStatus,
  }) async {
    try {
      debugPrint('💾 Storing completed delivery data locally');

      // Store only delivery status updates
      for (var status in deliveryStatus) {
        await _autoSave(status);
      }

      debugPrint('✅ Completed delivery status stored locally');
    } catch (e) {
      debugPrint('❌ Local storage error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
@override
Future<DataMap> checkEndDeliverStatus(String tripId) async {
  try {
    debugPrint('🔍 LOCAL: Checking end delivery status for trip: $tripId');

    // Get customers filtered by trip ID
    final customers = _customerBox
        .query(CustomerModel_.tripId.equals(tripId))
        .build()
        .find();
        
    final totalCustomers = customers.length;

    final completedDeliveries = customers.where((customer) {
      return customer.deliveryStatus.any((status) {
        final statusTitle = status.title?.toLowerCase().trim();
        return statusTitle == 'end delivery' || statusTitle == 'mark as undelivered';
      });
    }).length;

    debugPrint('📊 LOCAL: Delivery Status Summary for Trip: $tripId');
    debugPrint('   - Total Customers: $totalCustomers');
    debugPrint('   - Completed Deliveries: $completedDeliveries');
    debugPrint('   - Pending Deliveries: ${totalCustomers - completedDeliveries}');

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
        final customer = _customerBox
            .query(CustomerModel_.pocketbaseId.equals(customerId))
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
          customer.deliveryStatus.add(pendingStatus);
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
          '💾 LOCAL: Creating delivery status for customer: $customerId');

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
      final customer = _customerBox
          .query(CustomerModel_.pocketbaseId.equals(customerId))
          .build()
          .findFirst();

      if (customer != null) {
        customer.deliveryStatus.add(newStatus);
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
    String customerId,
    String queueCount,
  ) async {
    try {
      debugPrint('💾 LOCAL: Updating queue remarks');

      final newStatus = DeliveryUpdateModel(
        title: 'Arrived',
        subtitle: 'Arrived at customer location',
        remarks: 'Queue Count: $queueCount trucks',
        time: DateTime.now(),
        isAssigned: true,
        customer: customerId,
      );

      await _autoSave(newStatus);

      final customer = _customerBox
          .query(CustomerModel_.pocketbaseId.equals(customerId))
          .build()
          .findFirst();

      if (customer != null) {
        customer.deliveryStatus.add(newStatus);
        _customerBox.put(customer);
      }

      debugPrint('✅ LOCAL: Queue remarks updated successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to update queue remarks: $e');
      throw CacheException(message: e.toString());
    }
  }
}
