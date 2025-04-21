import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class CustomerLocalDatasource {
  Future<List<CustomerModel>> getCustomers(String tripId);
  Future<CustomerModel> getCustomerLocation(String customerId);
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> cacheCustomers(List<CustomerModel> customers);
  Future<String> calculateCustomerTotalTime(String customerId);
}

class CustomerLocalDatasourceImpl implements CustomerLocalDatasource {
  final Box<CustomerModel> _customerBox;
  List<CustomerModel>? _cachedCustomers;

  CustomerLocalDatasourceImpl(this._customerBox);
  @override
  Future<String> calculateCustomerTotalTime(String customerId) async {
    try {
      debugPrint('📱 LOCAL: Calculating total time for customer: $customerId');

      final customer = _customerBox
          .query(CustomerModel_.pocketbaseId.equals(customerId))
          .build()
          .findFirst();

      if (customer == null) {
        throw const CacheException(
            message: 'Customer not found in local storage');
      }

      final updates = customer.deliveryStatus.toList();
      if (updates.isEmpty) return '0h 0m';

      updates.sort((a, b) => a.time!.compareTo(b.time!));

      final firstUpdate = updates.first.time!;
      final lastUpdate = updates.last.time!;

      final difference = lastUpdate.difference(firstUpdate);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      final totalTime = '${hours}h ${minutes}m';
      customer.totalTime = totalTime;
      _customerBox.put(customer);

      debugPrint('✅ LOCAL: Total time calculated: $totalTime');
      return totalTime;
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to calculate total time: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<CustomerModel>> getCustomers(String tripId) async {
    try {
      debugPrint('🔍 Querying local customers for trip: $tripId');

      final query = _customerBox.query(CustomerModel_.tripId.equals(tripId));
      final customers = query.build().find();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored customers: ${_customerBox.count()}');
      debugPrint('Found customers for trip: ${customers.length}');

      _cachedCustomers = customers;
      return customers;
    } catch (e) {
      debugPrint('❌ Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<CustomerModel> getCustomerLocation(String customerId) async {
    try {
      final customer = _customerBox
          .query(CustomerModel_.pocketbaseId.equals(customerId))
          .build()
          .findFirst();

      if (customer != null) {
        debugPrint('✅ Found customer in local storage');
        return customer;
      }
      throw const CacheException(
          message: 'Customer not found in local storage');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      customer.tripId = customer.trip.target?.id;
      _customerBox.put(customer);
      debugPrint('✅ Customer updated in local storage');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupCustomers() async {
    try {
      debugPrint('🧹 Starting customer cleanup process');
      final allCustomers = _customerBox.getAll();

      // Create a map to track unique customers by their PocketBase ID
      final Map<String?, CustomerModel> uniqueCustomers = {};

      for (var customer in allCustomers) {
        // Only keep valid customers with required fields
        if (_isValidCustomer(customer)) {
          // If duplicate found, keep the most recently updated one
          final existingCustomer = uniqueCustomers[customer.pocketbaseId];
          if (existingCustomer == null ||
              (customer.updated
                      ?.isAfter(existingCustomer.updated ?? DateTime(0)) ??
                  false)) {
            uniqueCustomers[customer.pocketbaseId] = customer;
          }
        }
      }

      // Clear all and save only valid unique customers
      _customerBox.removeAll();
      _customerBox.putMany(uniqueCustomers.values.toList());

      debugPrint('✨ Cleanup complete:');
      debugPrint('📊 Original count: ${allCustomers.length}');
      debugPrint('📊 After cleanup: ${uniqueCustomers.length}');
    } catch (e) {
      debugPrint('❌ Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidCustomer(CustomerModel customer) {
    return customer.deliveryNumber != null &&
        customer.storeName != null &&
        customer.tripId != null;
  }

  @override
  Future<void> cacheCustomers(List<CustomerModel> customers) async {
    try {
      debugPrint('💾 Starting customer caching process...');
      debugPrint('📥 Received ${customers.length} customers to cache');

      await _cleanupCustomers();
      await _autoSave(customers);

      final cachedCount = _customerBox.count();
      debugPrint('✅ Cache verification: $cachedCount customers stored');

      _cachedCustomers = customers;
      debugPrint('🔄 Cache memory updated');
    } catch (e) {
      debugPrint('❌ Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _autoSave(List<CustomerModel> customers) async {
    try {
      debugPrint('🔍 Processing ${customers.length} customers');

      final validCustomers = customers.map((customer) {
        customer.tripId = customer.trip.target?.id;
        return customer;
      }).toList();

      _customerBox.putMany(validCustomers);
      _cachedCustomers = validCustomers;

      debugPrint('📊 Storage Stats:');
      debugPrint('Total Customers: ${validCustomers.length}');
      debugPrint(
          'Valid Customers: ${validCustomers.where((c) => c.id != null).length}');
      debugPrint(
          'With Delivery Numbers: ${validCustomers.where((c) => c.deliveryNumber != null).length}');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
