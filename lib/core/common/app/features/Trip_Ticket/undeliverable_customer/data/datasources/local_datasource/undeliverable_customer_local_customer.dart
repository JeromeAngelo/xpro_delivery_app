import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/model/undeliverable_customer_model.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';


abstract class UndeliverableCustomerLocalDataSource {
  Future<List<UndeliverableCustomerModel>> getUndeliverableCustomers(String tripId);
  Future<UndeliverableCustomerModel> getUndeliverableCustomerById(String customerId);
  Future<UndeliverableCustomerModel> createUndeliverableCustomer(
    UndeliverableCustomerModel undeliverableCustomer,
    String customerId);
  Future<void> saveUndeliverableCustomer(
    UndeliverableCustomerModel undeliverableCustomer,
    String customerId);
 Future<void> updateUndeliverableCustomer(
    UndeliverableCustomerModel undeliverableCustomer,
    String tripId);
  Future<void> deleteUndeliverableCustomer(String undeliverableCustomerId);
  Future<void> setUndeliverableReason(String customerId, UndeliverableReason reason);
}

class UndeliverableCustomerLocalDataSourceImpl implements UndeliverableCustomerLocalDataSource {
  const UndeliverableCustomerLocalDataSourceImpl(this._box);

  final Box<UndeliverableCustomerModel> _box;

  @override
  Future<List<UndeliverableCustomerModel>> getUndeliverableCustomers(String tripId) async {
    try {
      debugPrint('🔄 LOCAL: Fetching undeliverable customers for trip: $tripId');
      final customers = _box
          .query(UndeliverableCustomerModel_.tripId.equals(tripId))
          .build()
          .find();
      debugPrint('✅ LOCAL: Retrieved ${customers.length} undeliverable customers');
      return customers;
    } catch (e) {
      debugPrint('❌ LOCAL: Error fetching undeliverable customers - $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<UndeliverableCustomerModel> getUndeliverableCustomerById(String customerId) async {
    try {
      debugPrint('🔄 LOCAL: Fetching undeliverable customer: $customerId');
      final customer = _box
          .query(UndeliverableCustomerModel_.pocketbaseId.equals(customerId))
          .build()
          .findFirst();
      
      if (customer != null) {
        debugPrint('✅ LOCAL: Found undeliverable customer');
        return customer;
      }
      throw const CacheException(message: 'Undeliverable customer not found in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Error fetching undeliverable customer - $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<UndeliverableCustomerModel> createUndeliverableCustomer(
    UndeliverableCustomerModel undeliverableCustomer,
    String customerId) async {
    try {
      debugPrint('🔄 LOCAL: Creating undeliverable customer for ID: $customerId');
      undeliverableCustomer.customerId = customerId;
      _box.put(undeliverableCustomer);
      debugPrint('✅ LOCAL: Undeliverable customer created');
      return undeliverableCustomer;
    } catch (e) {
      debugPrint('❌ LOCAL: Error creating undeliverable customer - $e');
      throw CacheException(message: e.toString());
    }
  }

 @override
Future<void> saveUndeliverableCustomer(
    UndeliverableCustomerModel undeliverableCustomer,
    String customerId) async {
  try {
    debugPrint('🔄 LOCAL: Saving undeliverable customer for ID: $customerId');
    undeliverableCustomer.customerId = customerId;
    _box.put(undeliverableCustomer);
    debugPrint('✅ LOCAL: Undeliverable customer saved');
  } catch (e) {
    debugPrint('❌ LOCAL: Error saving undeliverable customer - $e');
    throw CacheException(message: e.toString());
  }
}

@override
Future<void> updateUndeliverableCustomer(
    UndeliverableCustomerModel undeliverableCustomer,
    String tripId) async {
  try {
    debugPrint('🔄 LOCAL: Updating undeliverable customer for trip: $tripId');
    undeliverableCustomer.tripId = tripId;
    _box.put(undeliverableCustomer);
    debugPrint('✅ LOCAL: Undeliverable customer updated');
  } catch (e) {
    debugPrint('❌ LOCAL: Error updating undeliverable customer - $e');
    throw CacheException(message: e.toString());
  }
}


  @override
  Future<void> deleteUndeliverableCustomer(String undeliverableCustomerId) async {
    try {
      debugPrint('🔄 LOCAL: Deleting undeliverable customer');
      final customer = _box.query(UndeliverableCustomerModel_.pocketbaseId.equals(undeliverableCustomerId)).build().findFirst();
      if (customer != null) {
        _box.remove(customer.objectBoxId);
        debugPrint('✅ LOCAL: Undeliverable customer deleted');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Error deleting undeliverable customer - $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> setUndeliverableReason(String customerId, UndeliverableReason reason) async {
    try {
      debugPrint('🔄 LOCAL: Setting undeliverable reason');
      final customer = _box.query(UndeliverableCustomerModel_.pocketbaseId.equals(customerId)).build().findFirst();
      if (customer != null) {
        customer.reason = reason;
        _box.put(customer);
        debugPrint('✅ LOCAL: Undeliverable reason updated');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Error setting undeliverable reason - $e');
      throw CacheException(message: e.toString());
    }
  }
}
