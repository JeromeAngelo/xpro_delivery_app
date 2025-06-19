import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/data/model/return_items_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../enums/product_return_reason.dart';
import '../../../../trip/data/models/trip_models.dart';
import '../../../../delivery_data/data/model/delivery_data_model.dart';
import '../../../../invoice_items/data/model/invoice_items_model.dart';
import '../../../../invoice_data/data/model/invoice_data_model.dart';

abstract class ReturnItemsLocalDataSource {
  // Sync return items by trip ID
  Future<void> syncReturnItemsByTripId(String tripId, List<ReturnItemsModel> returnItems);

  // Get all return items
  Future<List<ReturnItemsModel>> getAllReturnItems();

  // Get all return items by trip ID
  Future<List<ReturnItemsModel>> getReturnItemsByTripId(String tripId);

  // Get return item by ID
  Future<ReturnItemsModel> getReturnItemById(String id);

  // Cache return items
  Future<void> cacheReturnItems(List<ReturnItemsModel> returnItems);

  // Update return item
  Future<void> updateReturnItem(ReturnItemsModel returnItem);

  // Delete return item
  Future<bool> deleteReturnItem(String id);

  // Add return item
  Future<ReturnItemsModel> addReturnItem(ReturnItemsModel returnItem);
}

class ReturnItemsLocalDataSourceImpl implements ReturnItemsLocalDataSource {
  final Box<ReturnItemsModel> _returnItemsBox;
  List<ReturnItemsModel>? _cachedReturnItems;
  final Store _store; // Add Store reference

  ReturnItemsLocalDataSourceImpl(this._returnItemsBox, this._store);

  @override
  Future<List<ReturnItemsModel>> getReturnItemsByTripId(String tripId) async {
    try {
      debugPrint('📱 LOCAL: Fetching return items for trip ID: $tripId');

      final query = _returnItemsBox.query(ReturnItemsModel_.tripId.equals(tripId));
      final returnItemsList = query.build().find();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored return items: ${_returnItemsBox.count()}');
      debugPrint('Found return items for trip: ${returnItemsList.length}');

      // Process each return item to ensure all relationships are loaded
      final processedReturnItems = <ReturnItemsModel>[];

      for (var returnItem in returnItemsList) {
        // Check if return item has valid ID before processing
        if (returnItem.id == null || returnItem.id!.isEmpty) {
          debugPrint('⚠️ Skipping return item with null/empty ID');
          continue;
        }

        final processedData = await _loadCompleteReturnItem(returnItem);
        processedReturnItems.add(processedData);

        debugPrint('🔍 Return Item ${processedReturnItems.length}:');
        debugPrint('   📦 ID: ${processedData.id}');
        debugPrint('   📦 ObjectBox ID: ${processedData.objectBoxId}');
        debugPrint('   🚚 Trip Target: ${processedData.trip.target != null ? "Loaded" : "null"}');
        debugPrint('   📦 Delivery Target: ${processedData.deliveryData.target != null ? "Loaded" : "null"}');
        debugPrint('   📄 Invoice Item Target: ${processedData.invoiceItem.target != null ? "Loaded" : "null"}');
        debugPrint('   📋 Invoice Data Target: ${processedData.invoiceData.target != null ? "Loaded" : "null"}');
        debugPrint('   🔢 Ref ID: ${processedData.refId ?? "null"}');
        debugPrint('   📊 Quantity: ${processedData.quantity ?? "null"}');
        debugPrint('   📏 UOM: ${processedData.uom ?? "null"}');
        debugPrint('   ❓ Reason: ${processedData.reason?.name ?? "null"}');
      }

      _cachedReturnItems = processedReturnItems;
      return processedReturnItems;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> syncReturnItemsByTripId(String tripId, List<ReturnItemsModel> returnItems) async {
    try {
      debugPrint('💾 LOCAL: Starting return items sync for trip: $tripId');
      debugPrint('📥 LOCAL: Received ${returnItems.length} return items to sync');

      // Clear existing return items for this trip
      await _cleanupReturnItemsByTripId(tripId);

      // Prepare return items for storage
      final validReturnItems = returnItems.map((item) {
        // Ensure tripId is set if trip is assigned
        if (item.trip.target != null) {
          item.tripId = item.trip.target?.id;
        } else {
          item.tripId = tripId; // Set tripId directly if trip target is null
        }
        return item;
      }).toList();

      // Store synced return items
      _returnItemsBox.putMany(validReturnItems);

      final cachedCount = _returnItemsBox
          .query(ReturnItemsModel_.tripId.equals(tripId))
          .build()
          .count();

      debugPrint('✅ LOCAL: Sync verification: $cachedCount return items stored for trip: $tripId');
      debugPrint('📊 LOCAL: Sync Stats:');
      debugPrint('   📦 Total synced: ${validReturnItems.length}');
      debugPrint('   ✅ Successfully stored: $cachedCount');
      debugPrint('   🎫 Trip ID: $tripId');

      // Update cached data
      _cachedReturnItems = _returnItemsBox.getAll();
      debugPrint('🔄 LOCAL: Cache memory updated with synced data');
    } catch (e) {
      debugPrint('❌ LOCAL: Sync failed for trip $tripId: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupReturnItemsByTripId(String tripId) async {
    try {
      debugPrint('🧹 LOCAL: Cleaning up existing return items for trip: $tripId');

      final existingData = _returnItemsBox
          .query(ReturnItemsModel_.tripId.equals(tripId))
          .build()
          .find();

      if (existingData.isNotEmpty) {
        final idsToRemove = existingData.map((data) => data.objectBoxId).toList();
        _returnItemsBox.removeMany(idsToRemove);
        debugPrint('🗑️ LOCAL: Removed ${existingData.length} existing return items for trip: $tripId');
      } else {
        debugPrint('ℹ️ LOCAL: No existing return items found for trip: $tripId');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed for trip $tripId: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<ReturnItemsModel>> getAllReturnItems() async {
    try {
      debugPrint('📱 LOCAL: Fetching all return items');

      final query = _returnItemsBox
          .query(ReturnItemsModel_.pocketbaseId.equals('id'))
          .build();
      final returnItems = query.find();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored return items: ${_returnItemsBox.count()}');
      debugPrint('Found unassigned return items: ${returnItems.length}');

      _cachedReturnItems = returnItems;
      return returnItems;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<ReturnItemsModel> _loadCompleteReturnItem(ReturnItemsModel returnItem) async {
    try {
      debugPrint('🔄 Loading complete return item data for: ${returnItem.id}');

      // Load trip data if not already loaded
      if (returnItem.trip.target == null && returnItem.trip.targetId > 0) {
        final tripBox = _store.box<TripModel>();
        final trip = tripBox.get(returnItem.trip.targetId);
        if (trip != null) {
          returnItem.trip.target = trip;
          debugPrint('✅ Loaded trip: ${trip.tripNumberId}');
        } else {
          debugPrint('⚠️ Trip not found in local storage: ${returnItem.trip.targetId}');
        }
      } else if (returnItem.trip.targetId <= 0) {
        debugPrint('⚠️ Invalid trip targetId: ${returnItem.trip.targetId}');
      }

      // Load delivery data if not already loaded
      if (returnItem.deliveryData.target == null && returnItem.deliveryData.targetId > 0) {
        final deliveryBox = _store.box<DeliveryDataModel>();
        final delivery = deliveryBox.get(returnItem.deliveryData.targetId);
        if (delivery != null) {
          returnItem.deliveryData.target = delivery;
          debugPrint('✅ Loaded delivery data: ${delivery.id}');
        } else {
          debugPrint('⚠️ Delivery data not found in local storage: ${returnItem.deliveryData.targetId}');
        }
      } else if (returnItem.deliveryData.targetId <= 0) {
        debugPrint('⚠️ Invalid delivery data targetId: ${returnItem.deliveryData.targetId}');
      }

      // Load invoice item if not already loaded
      if (returnItem.invoiceItem.target == null && returnItem.invoiceItem.targetId > 0) {
        final invoiceItemBox = _store.box<InvoiceItemsModel>();
        final invoiceItem = invoiceItemBox.get(returnItem.invoiceItem.targetId);
        if (invoiceItem != null) {
          returnItem.invoiceItem.target = invoiceItem;
          debugPrint('✅ Loaded invoice item: ${invoiceItem.id}');
        } else {
          debugPrint('⚠️ Invoice item not found in local storage: ${returnItem.invoiceItem.targetId}');
        }
      } else if (returnItem.invoiceItem.targetId <= 0) {
        debugPrint('⚠️ Invalid invoice item targetId: ${returnItem.invoiceItem.targetId}');
      }

      // Load invoice data if not already loaded
      if (returnItem.invoiceData.target == null && returnItem.invoiceData.targetId > 0) {
        final invoiceDataBox = _store.box<InvoiceDataModel>();
        final invoiceData = invoiceDataBox.get(returnItem.invoiceData.targetId);
        if (invoiceData != null) {
          returnItem.invoiceData.target = invoiceData;
          debugPrint('✅ Loaded invoice data: ${invoiceData.id}');
        } else {
          debugPrint('⚠️ Invoice data not found in local storage: ${returnItem.invoiceData.targetId}');
        }
      } else if (returnItem.invoiceData.targetId <= 0) {
        debugPrint('⚠️ Invalid invoice data targetId: ${returnItem.invoiceData.targetId}');
      }

      // Set default reason if missing
      if (returnItem.reason == null) {
        // Don't set a default reason as it should be explicitly chosen
        debugPrint('ℹ️ Return item has no reason specified: ${returnItem.id}');
      }

      // Save the updated return item only if it has a valid objectBoxId
      if (returnItem.objectBoxId > 0) {
        _returnItemsBox.put(returnItem);
        debugPrint('✅ Updated return item saved to ObjectBox');
      } else {
        debugPrint('⚠️ Cannot save return item with invalid objectBoxId: ${returnItem.objectBoxId}');
      }

      debugPrint('✅ Complete return item data loaded for: ${returnItem.id}');
      return returnItem;
    } catch (e) {
      debugPrint('❌ Failed to load complete return item data: $e');
      debugPrint('   - Return Item ID: ${returnItem.id}');
      debugPrint('   - ObjectBox ID: ${returnItem.objectBoxId}');
      debugPrint('   - Trip targetId: ${returnItem.trip.targetId}');
      debugPrint('   - Delivery targetId: ${returnItem.deliveryData.targetId}');
      debugPrint('   - Invoice Item targetId: ${returnItem.invoiceItem.targetId}');
      debugPrint('   - Invoice Data targetId: ${returnItem.invoiceData.targetId}');

      // Return original data if loading fails to prevent crashes
      return returnItem;
    }
  }

  @override
  Future<ReturnItemsModel> getReturnItemById(String id) async {
    try {
      debugPrint('📱 LOCAL: Fetching return item with ID: $id');

      final returnItem = _returnItemsBox
          .query(ReturnItemsModel_.pocketbaseId.equals(id))
          .build()
          .findFirst();

      if (returnItem != null) {
        debugPrint('✅ LOCAL: Found return item in local storage');
        return await _loadCompleteReturnItem(returnItem);
      }

      throw const CacheException(
        message: 'Return item not found in local storage',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheReturnItems(List<ReturnItemsModel> returnItems) async {
    try {
      debugPrint('💾 LOCAL: Starting return items caching process...');
      debugPrint('📥 LOCAL: Received ${returnItems.length} return items to cache');

      await _cleanupReturnItems();
      await _autoSave(returnItems);

      final cachedCount = _returnItemsBox.count();
      debugPrint('✅ LOCAL: Cache verification: $cachedCount return items stored');

      _cachedReturnItems = returnItems;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateReturnItem(ReturnItemsModel returnItem) async {
    try {
      debugPrint('📱 LOCAL: Updating return item: ${returnItem.id}');

      // Ensure tripId is set if trip is assigned
           if (returnItem.trip.target != null) {
        returnItem.tripId = returnItem.trip.target?.id;
      }

      _returnItemsBox.put(returnItem);

      // Update cached data
      if (_cachedReturnItems != null) {
        final index = _cachedReturnItems!.indexWhere((item) => item.id == returnItem.id);
        if (index != -1) {
          _cachedReturnItems![index] = returnItem;
        }
      }

      debugPrint('✅ LOCAL: Return item updated successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteReturnItem(String id) async {
    try {
      debugPrint('📱 LOCAL: Deleting return item with ID: $id');

      final returnItem = _returnItemsBox
          .query(ReturnItemsModel_.pocketbaseId.equals(id))
          .build()
          .findFirst();

      if (returnItem != null) {
        _returnItemsBox.remove(returnItem.objectBoxId);

        // Update cached data
        if (_cachedReturnItems != null) {
          _cachedReturnItems!.removeWhere((item) => item.id == id);
        }

        debugPrint('✅ LOCAL: Return item deleted successfully');
        return true;
      }

      debugPrint('⚠️ LOCAL: Return item not found for deletion');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: Delete failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<ReturnItemsModel> addReturnItem(ReturnItemsModel returnItem) async {
    try {
      debugPrint('📱 LOCAL: Adding new return item: ${returnItem.id}');

      // Ensure tripId is set if trip is assigned
      if (returnItem.trip.target != null) {
        returnItem.tripId = returnItem.trip.target?.id;
      }

      // Set creation timestamp if not set
      if (returnItem.created == null) {
        returnItem = returnItem.copyWith(created: DateTime.now());
      }

      // Set update timestamp
      returnItem = returnItem.copyWith(updated: DateTime.now());

      final savedId = _returnItemsBox.put(returnItem);
      returnItem.objectBoxId = savedId;

      // Update cached data
      if (_cachedReturnItems != null) {
        _cachedReturnItems!.add(returnItem);
      }

      debugPrint('✅ LOCAL: Return item added successfully with ObjectBox ID: $savedId');
      return returnItem;
    } catch (e) {
      debugPrint('❌ LOCAL: Add failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupReturnItems() async {
    try {
      debugPrint('🧹 LOCAL: Cleaning up existing return items');

      final existingData = _returnItemsBox.getAll();
      if (existingData.isNotEmpty) {
        _returnItemsBox.removeAll();
        debugPrint('🗑️ LOCAL: Removed ${existingData.length} existing return items');
      } else {
        debugPrint('ℹ️ LOCAL: No existing return items found');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _autoSave(List<ReturnItemsModel> returnItems) async {
    try {
      debugPrint('💾 LOCAL: Auto-saving ${returnItems.length} return items');

      // Prepare return items for storage
      final validReturnItems = returnItems.map((item) {
        // Ensure tripId is set if trip is assigned
        if (item.trip.target != null) {
          item.tripId = item.trip.target?.id;
        }
        return item;
      }).toList();

      _returnItemsBox.putMany(validReturnItems);

      debugPrint('✅ LOCAL: Auto-save completed');
      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('   📦 Total saved: ${validReturnItems.length}');
      debugPrint('   💾 Total in storage: ${_returnItemsBox.count()}');
    } catch (e) {
      debugPrint('❌ LOCAL: Auto-save failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  // Helper method to get return items count by trip
  Future<int> getReturnItemsCountByTrip(String tripId) async {
    try {
      final count = _returnItemsBox
          .query(ReturnItemsModel_.tripId.equals(tripId))
          .build()
          .count();

      debugPrint('📊 LOCAL: Return items count for trip $tripId: $count');
      return count;
    } catch (e) {
      debugPrint('❌ LOCAL: Count query failed: ${e.toString()}');
      return 0;
    }
  }

  // Helper method to get return items by reason
  Future<List<ReturnItemsModel>> getReturnItemsByReason(ProductReturnReason reason) async {
    try {
      debugPrint('📱 LOCAL: Fetching return items by reason: ${reason.name}');

      // Since ObjectBox doesn't directly support enum queries, we'll filter in memory
      final allReturnItems = _returnItemsBox.getAll();
      final filteredItems = allReturnItems.where((item) => item.reason == reason).toList();

      debugPrint('✅ LOCAL: Found ${filteredItems.length} return items with reason: ${reason.name}');
      return filteredItems;
    } catch (e) {
      debugPrint('❌ LOCAL: Reason query failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  // Helper method to get return items by delivery ID
  Future<List<ReturnItemsModel>> getReturnItemsByDeliveryId(String deliveryId) async {
    try {
      debugPrint('📱 LOCAL: Fetching return items for delivery ID: $deliveryId');

      // Get all return items and filter by delivery data target
      final allReturnItems = _returnItemsBox.getAll();
      final filteredItems = <ReturnItemsModel>[];

      for (var item in allReturnItems) {
        await _loadCompleteReturnItem(item);
        if (item.deliveryData.target?.id == deliveryId) {
          filteredItems.add(item);
        }
      }

      debugPrint('✅ LOCAL: Found ${filteredItems.length} return items for delivery: $deliveryId');
      return filteredItems;
    } catch (e) {
      debugPrint('❌ LOCAL: Delivery query failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  // Helper method to clear all cached data
  Future<void> clearCache() async {
    try {
      debugPrint('🧹 LOCAL: Clearing all return items cache');

      _returnItemsBox.removeAll();
      _cachedReturnItems = null;

      debugPrint('✅ LOCAL: Cache cleared successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Cache clear failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  // Helper method to get cache statistics
  Map<String, dynamic> getCacheStats() {
    try {
      final totalCount = _returnItemsBox.count();
      final memoryCount = _cachedReturnItems?.length ?? 0;

      final stats = {
        'total_stored': totalCount,
        'memory_cached': memoryCount,
        'storage_size_mb': (_returnItemsBox.count() * 1024) / (1024 * 1024), // Rough estimate
        'last_updated': DateTime.now().toIso8601String(),
      };

      debugPrint('📊 LOCAL: Cache Stats: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ LOCAL: Stats query failed: ${e.toString()}');
      return {'error': e.toString()};
    }
  }
}

