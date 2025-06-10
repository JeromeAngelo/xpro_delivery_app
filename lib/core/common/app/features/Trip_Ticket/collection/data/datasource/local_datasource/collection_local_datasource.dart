import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class CollectionLocalDataSource {
  // Get all collections
  Future<List<CollectionModel>> getAllCollections();

  // Get collections by trip ID
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId);

  // Get collection by ID
  Future<CollectionModel> getCollectionById(String collectionId);

  // Cache collections
  Future<void> cacheCollections(List<CollectionModel> collections);

  // Update collection
  Future<void> updateCollection(CollectionModel collection);

  // Delete collection
  Future<bool> deleteCollection(String collectionId);

  // Save collection
  Future<CollectionModel> saveCollection(CollectionModel collection);
}

class CollectionLocalDataSourceImpl implements CollectionLocalDataSource {
  final Box<CollectionModel> _collectionBox;
  List<CollectionModel>? _cachedCollections;

  CollectionLocalDataSourceImpl(this._collectionBox);

  @override
  Future<List<CollectionModel>> getAllCollections() async {
    try {
      debugPrint('📱 LOCAL: Fetching all collections');

      final collections = _collectionBox.getAll();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored collections: ${_collectionBox.count()}');
      debugPrint('Found collections: ${collections.length}');

      // Debug each collection
      for (var collection in collections) {
        debugPrint('📋 Collection: ${collection.pocketbaseId} - Customer: ${collection.customer.target?.name ?? "null"}');
      }

      _cachedCollections = collections;
      return collections;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId) async {
    try {
      debugPrint('📱 LOCAL: Fetching collections for trip ID: $tripId');

      final query = _collectionBox.query(CollectionModel_.tripId.equals(tripId));
      final collections = query.build().find();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored collections: ${_collectionBox.count()}');
      debugPrint('Found collections for trip: ${collections.length}');

      // Debug each collection
      for (var collection in collections) {
        debugPrint('📋 Collection: ${collection.pocketbaseId} - Trip: ${collection.tripId} - Customer: ${collection.customer.target?.name ?? "null"}');
      }

      _cachedCollections = collections;
      return collections;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<CollectionModel> getCollectionById(String collectionId) async {
    try {
      debugPrint('📱 LOCAL: Fetching collection with ID: $collectionId');

      final collection = _collectionBox
          .query(CollectionModel_.pocketbaseId.equals(collectionId))
          .build()
          .findFirst();

      if (collection != null) {
        debugPrint('✅ LOCAL: Found collection in local storage');
        debugPrint('📋 Collection details: ${collection.pocketbaseId} - Customer: ${collection.customer.target?.name ?? "null"} - Amount: ${collection.totalAmount}');
        return collection;
      }

      throw const CacheException(
        message: 'Collection not found in local storage',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Collection fetch error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheCollections(List<CollectionModel> collections) async {
    try {
      debugPrint('💾 LOCAL: Starting collection caching process...');
      debugPrint('📥 LOCAL: Received ${collections.length} collections to cache');

      // Debug incoming collections
      for (var collection in collections) {
        debugPrint('🔍 Incoming Collection: ${collection.pocketbaseId}');
        debugPrint('   - Collection ID: ${collection.collectionId}');
        debugPrint('   - Collection Name: ${collection.collectionName}');
        debugPrint('   - Total Amount: ${collection.totalAmount}');
        debugPrint('   - Delivery Data Target: ${collection.deliveryData.target?.id}');
        debugPrint('   - Trip Target: ${collection.trip.target?.id}');
        debugPrint('   - Customer Target: ${collection.customer.target?.id}');
        debugPrint('   - Invoice Target: ${collection.invoice.target?.id}');
      }

      await _cleanupCollections();
      await _autoSave(collections);

      final cachedCount = _collectionBox.count();
      debugPrint('✅ LOCAL: Cache verification: $cachedCount collections stored');

      _cachedCollections = collections;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateCollection(CollectionModel collection) async {
    try {
      debugPrint('📱 LOCAL: Updating collection: ${collection.pocketbaseId}');

      // Set relation IDs for ObjectBox
      if (collection.deliveryData.target != null) {
        collection.deliveryDataId = collection.deliveryData.target?.id;
      }
      if (collection.trip.target != null) {
        collection.tripId = collection.trip.target?.id;
      }
      if (collection.customer.target != null) {
        collection.customerId = collection.customer.target?.id;
      }
      if (collection.invoice.target != null) {
        collection.invoiceId = collection.invoice.target?.id;
      }

      _collectionBox.put(collection);
      debugPrint('✅ LOCAL: Collection updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteCollection(String collectionId) async {
    try {
      debugPrint('📱 LOCAL: Deleting collection with ID: $collectionId');

      final collection = _collectionBox
          .query(CollectionModel_.pocketbaseId.equals(collectionId))
          .build()
          .findFirst();

      if (collection == null) {
        throw const CacheException(
          message: 'Collection not found in local storage',
        );
      }

      _collectionBox.remove(collection.objectBoxId);
      debugPrint('✅ LOCAL: Successfully deleted collection');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<CollectionModel> saveCollection(CollectionModel collection) async {
    try {
      debugPrint('📱 LOCAL: Saving collection: ${collection.pocketbaseId}');

      // Set relation IDs for ObjectBox
      if (collection.deliveryData.target != null) {
        collection.deliveryDataId = collection.deliveryData.target?.id;
      }
      if (collection.trip.target != null) {
        collection.tripId = collection.trip.target?.id;
      }
      if (collection.customer.target != null) {
        collection.customerId = collection.customer.target?.id;
      }
      if (collection.invoice.target != null) {
        collection.invoiceId = collection.invoice.target?.id;
      }

      _collectionBox.put(collection);
      debugPrint('✅ LOCAL: Collection saved to local storage');
      return collection;
    } catch (e) {
      debugPrint('❌ LOCAL: Save failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupCollections() async {
    try {
      debugPrint('🧹 LOCAL: Starting collection cleanup process');
      final allCollections = _collectionBox.getAll();

      // Create a map to track unique collections by their PocketBase ID
      final Map<String?, CollectionModel> uniqueCollections = {};

      for (var collection in allCollections) {
        debugPrint('🔍 Validating collection: ${collection.pocketbaseId}');
        debugPrint('   - Collection ID: ${collection.collectionId}');
        debugPrint('   - Collection Name: ${collection.collectionName}');
        debugPrint('   - Total Amount: ${collection.totalAmount}');
        debugPrint('   - Is Valid: ${_isValidCollection(collection)}');
        
        // Only keep valid collections with required fields
        if (_isValidCollection(collection)) {
          // If duplicate found, keep the most recently updated one
          final existingCollection = uniqueCollections[collection.pocketbaseId];
          if (existingCollection == null ||
              (collection.updated?.isAfter(existingCollection.updated ?? DateTime(0)) ?? false)) {
            uniqueCollections[collection.pocketbaseId] = collection;
            debugPrint('   ✅ Collection kept');
          } else {
            debugPrint('   🔄 Collection replaced with newer version');
          }
        } else {
          debugPrint('   ⚠️ Collection has validation issues but will be kept for data integrity');
          // Keep collections even if they have validation issues to prevent data loss
          uniqueCollections[collection.pocketbaseId] = collection;
        }
      }

      // Clear all and save only unique collections
      _collectionBox.removeAll();
      _collectionBox.putMany(uniqueCollections.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allCollections.length}');
      debugPrint('📊 After cleanup: ${uniqueCollections.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidCollection(CollectionModel collection) {
    // Relaxed validation - only check for essential PocketBase ID
    final hasValidId = collection.pocketbaseId.isNotEmpty;
    
    // Generate missing fields if needed
    if (collection.collectionId == null || collection.collectionId!.isEmpty) {
      collection.collectionId = 'collection_${collection.pocketbaseId}';
      debugPrint('🔧 Generated collectionId: ${collection.collectionId}');
    }
    
    if (collection.collectionName == null || collection.collectionName!.isEmpty) {
      collection.collectionName = 'deliveryCollection';
      debugPrint('🔧 Generated collectionName: ${collection.collectionName}');
    }
    
    debugPrint('🔍 Validation details:');
    debugPrint('   - PocketBase ID: "${collection.pocketbaseId}" (empty: ${collection.pocketbaseId.isEmpty})');
    debugPrint('   - Collection ID: "${collection.collectionId}" (null: ${collection.collectionId == null})');
    debugPrint('   - Collection Name: "${collection.collectionName}"');
    debugPrint('   - Total Amount: ${collection.totalAmount}');
    debugPrint('   - Final validation result: $hasValidId');
    
    return hasValidId;
  }

  Future<void> _autoSave(List<CollectionModel> collections) async {
    try {
      debugPrint('🔍 LOCAL: Processing ${collections.length} collections');

      final validCollections = collections.map((collection) {
        debugPrint('🔧 Setting relations for collection: ${collection.pocketbaseId}');
        
        // Ensure collection has required fields
        if (collection.collectionId == null || collection.collectionId!.isEmpty) {
          collection.collectionId = 'collection_${collection.pocketbaseId}';
          debugPrint('🔧 Generated collectionId: ${collection.collectionId}');
        }
        
        if (collection.collectionName == null || collection.collectionName!.isEmpty) {
          collection.collectionName = 'deliveryCollection';
          debugPrint('🔧 Generated collectionName: ${collection.collectionName}');
        }
        
        // Set relation IDs for ObjectBox
        final deliveryDataId = collection.deliveryData.target?.id;
        final tripId = collection.trip.target?.id;
        final customerId = collection.customer.target?.id;
        final invoiceId = collection.invoice.target?.id;
        
        collection.deliveryDataId = deliveryDataId;
        collection.tripId = tripId;
        collection.customerId = customerId;
        collection.invoiceId = invoiceId;
        
        debugPrint('   - Delivery Data ID set to: $deliveryDataId');
        debugPrint('   - Trip ID set to: $tripId');
        debugPrint('   - Customer ID set to: $customerId');
        debugPrint('   - Invoice ID set to: $invoiceId');
        debugPrint('   - Total Amount: ${collection.totalAmount}');
        
        return collection;
      }).toList();

      _collectionBox.putMany(validCollections);
      _cachedCollections = validCollections;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Collections: ${validCollections.length}');
      debugPrint('Valid Collections: ${validCollections.where((c) => c.objectBoxId != 0).length}');
      debugPrint('With Delivery Data: ${validCollections.where((c) => c.deliveryDataId != null).length}');
      debugPrint('With Trip Data: ${validCollections.where((c) => c.tripId != null).length}');
      debugPrint('With Customer Data: ${validCollections.where((c) => c.customerId != null).length}');
      debugPrint('With Invoice Data: ${validCollections.where((c) => c.invoiceId != null).length}');
      debugPrint('With Total Amount: ${validCollections.where((c) => c.totalAmount != null && c.totalAmount! > 0).length}');
      
      // Debug each saved collection
      for (var collection in validCollections) {
        debugPrint('💾 Saved: ${collection.pocketbaseId} - Trip: ${collection.tripId} - Customer: ${collection.customerId} - Invoice: ${collection.invoiceId} - Amount: ${collection.totalAmount}');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
