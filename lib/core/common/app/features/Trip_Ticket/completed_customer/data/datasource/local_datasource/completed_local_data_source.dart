import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/models/completed_customer_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class CompletedCustomerLocalDatasource {
  Future<List<CompletedCustomerModel>> getCompletedCustomers(String tripId);
  Future<CompletedCustomerModel> getCompletedCustomerById(String customerId);
  Future<void> updateCompletedCustomer(CompletedCustomerModel customer);
  Future<void> cacheCompletedCustomers(List<CompletedCustomerModel> customers);
}

class CompletedCustomerLocalDatasourceImpl
    implements CompletedCustomerLocalDatasource {
  final Box<CompletedCustomerModel> _completedCustomerBox;

  CompletedCustomerLocalDatasourceImpl(this._completedCustomerBox);
  Future<void> _autoSave(List<CompletedCustomerModel> customers) async {
    try {
      debugPrint('🔍 Processing ${customers.length} completed customers');

      // Clear existing data
      _completedCustomerBox.removeAll();
      debugPrint('🧹 Cleared previous completed customers');

      // Filter out duplicates by ID
      final uniqueCustomers = customers
          .fold<Map<String, CompletedCustomerModel>>(
            {},
            (map, customer) {
              if (customer.id != null &&
                  customer.storeName != null &&
                  customer.deliveryNumber != null) {
                map[customer.id!] = customer;
              }
              return map;
            },
          )
          .values
          .toList();

      _completedCustomerBox.putMany(uniqueCustomers);

      debugPrint(
          '📊 Stored ${uniqueCustomers.length} unique valid completed customers');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> cleanupInvalidEntries() async {
    final invalidCustomers = _completedCustomerBox
        .getAll()
        .where((c) => c.storeName == null || c.pocketbaseId.isEmpty)
        .toList();

    if (invalidCustomers.isNotEmpty) {
      debugPrint(
          '🧹 Removing ${invalidCustomers.length} invalid completed customers');
      _completedCustomerBox
          .removeMany(invalidCustomers.map((c) => c.objectBoxId).toList());
    }
  }

@override
Future<List<CompletedCustomerModel>> getCompletedCustomers(String tripId) async {
  try {
    debugPrint('🔍 Querying local completed customers for trip: $tripId');

    // // First check if box is open and accessible
    // if (!_completedCustomerBox.isOpen) {
    //   debugPrint('⚠️ Box not open, attempting to reopen');
    //   // Handle box reopening if needed
    // }

    // Build and execute query
    final query = _completedCustomerBox
        .query(CompletedCustomerModel_.tripId.equals(tripId))
        .build();
        
    final customers = query.find();
    query.close();

    debugPrint('📊 Local Storage Stats:');
    debugPrint('Total stored completed customers: ${_completedCustomerBox.count()}');
    debugPrint('Found completed customers for trip: ${customers.length}');

    // Verify data integrity
    for (final customer in customers) {
      debugPrint('   🏪 Store: ${customer.storeName}');
      debugPrint('   📦 Delivery Status: ${customer.deliveryStatus.length}');
      debugPrint('   🧾 Invoices: ${customer.invoicesList.length}');
    }

    return customers;
  } catch (e) {
    debugPrint('❌ Local query error: ${e.toString()}');
    throw CacheException(message: e.toString());
  }
}



  @override
  Future<CompletedCustomerModel> getCompletedCustomerById(
      String customerId) async {
    try {
      debugPrint('🔍 Fetching completed customer: $customerId');

      final query = _completedCustomerBox
          .query(CompletedCustomerModel_.pocketbaseId.equals(customerId))
          .build();

      final customer = query.findFirst();
      query.close();

      if (customer != null) {
        debugPrint('✅ Found completed customer: ${customer.storeName}');
        debugPrint('   📦 Updates: ${customer.deliveryStatus.length}');
        debugPrint('   🧾 Invoices: ${customer.invoicesList.length}');
        return customer;
      }

      throw const CacheException(message: 'Completed customer not found');
    } catch (e) {
      debugPrint('❌ Fetch operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateCompletedCustomer(CompletedCustomerModel customer) async {
    try {
      debugPrint('🔍 Processing completed customer: ${customer.storeName}');

      // Store using pocketbaseId as the key
      final existingCustomer = _completedCustomerBox
          .query(CompletedCustomerModel_.pocketbaseId.equals(customer.id ?? ''))
          .build()
          .findFirst();

      if (existingCustomer != null) {
        customer.objectBoxId = existingCustomer.objectBoxId;
        debugPrint('🔄 Updating existing customer: ${customer.storeName}');
      }

      // Ensure all required fields are present
      if (customer.id != null && customer.storeName != null) {
        _completedCustomerBox.put(customer);
        debugPrint('✅ Stored completed customer: ${customer.storeName}');
        debugPrint('   📦 Delivery Updates: ${customer.deliveryStatus.length}');
        debugPrint('   🧾 Invoices: ${customer.invoicesList.length}');
      }
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheCompletedCustomers(
      List<CompletedCustomerModel> customers) async {
    try {
      debugPrint('💾 Caching completed customers from remote');
      await _autoSave(customers);
      debugPrint('✅ Completed customers cached successfully');
    } catch (e) {
      debugPrint('❌ Failed to cache completed customers: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
