import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../delivery_data/customer_data/data/model/customer_data_model.dart';
import '../../../../../delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import '../../../../../delivery_data/invoice_data/data/model/invoice_data_model.dart';
import '../../../../delivery_data/data/model/delivery_data_model.dart';
import '../../../../trip/data/models/trip_models.dart';

abstract class CollectionLocalDataSource {
  // Get all collections
  Future<List<CollectionModel>> getAllCollections();

  // Get collections by trip ID
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId);

  // Get collection by ID
 Future<CollectionModel?> getCollectionById(String collectionId);

  // Cache collections
  Future<void> cacheCollections(List<CollectionModel> collections);

  // Update collection
  Future<void> updateCollection(CollectionModel collection);

  // Delete collection
  Future<bool> deleteCollection(String collectionId);

  // Save collection
  Future<CollectionModel> saveCollection(CollectionModel collection);
  Stream<List<CollectionModel>> watchAllCollections();
   Stream<CollectionModel?> watchCollectionById(String collectionId);

}

class CollectionLocalDataSourceImpl implements CollectionLocalDataSource {
   Box<CollectionModel> get _collectionBox => objectBoxStore.deliveryCollectonBox;
    Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;
  Box<DeliveryReceiptModel> get deliveryReceiptBox => objectBoxStore.deliveryReceiptBox;

  List<CollectionModel>? _cachedCollections;
final ObjectBoxStore objectBoxStore;
  CollectionLocalDataSourceImpl( this.objectBoxStore);

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
    debugPrint("📥 LOCAL getCollectionsByTripId() tripId = $tripId");

    // -------------------------------------------------------------
    // 1️⃣ Find the trip first
    // -------------------------------------------------------------
    final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
    final trip = tripQuery.findFirst();
    tripQuery.close();

    if (trip == null) {
      debugPrint("⚠️ Trip not found in local DB for tripId: $tripId");
      return [];
    }

    // -------------------------------------------------------------
    // 2️⃣ Get Collections linked to this trip
    // -------------------------------------------------------------
    final collectionSet = <String, CollectionModel>{}; // dedupe by PB ID

    for (final c in trip.deliveryCollection) {
      final fullCollection = _collectionBox.get(c.objectBoxId);
      if (fullCollection != null) {
        collectionSet[fullCollection.id ?? ""] = fullCollection;
      }
    }

    if (collectionSet.isEmpty) {
      debugPrint("⚠️ No collections found for trip: ${trip.name}");
      return [];
    }

    final output = <CollectionModel>[];

    // -------------------------------------------------------------
    // 3️⃣ Load nested relations safely
    // -------------------------------------------------------------
    for (final collection in collectionSet.values) {
      debugPrint("📄 Loading relations for Collection → ${collection.id}");

      // 👤 Customer
      final customer = collection.customer.target;
      if (customer != null) {
        final fullCustomer = customerBox.get(customer.objectBoxId);
        if (fullCustomer != null) {
          collection.customer.target = fullCustomer;
          debugPrint("👤 Customer loaded → ${fullCustomer.name}");
        }
      }

      // 🚚 Delivery Data
      final dd = collection.deliveryData.target;
      if (dd != null) {
        final fullDD = deliveryDataBox.get(dd.objectBoxId);
        if (fullDD != null) {
          collection.deliveryData.target = fullDD;
          debugPrint("🚚 DeliveryData loaded → ${fullDD.id}");
        }
      }

      // 🧾 Invoices
      final invoiceList = <InvoiceDataModel>[];
      for (final inv in collection.invoices) {
        final fullInv = invoiceBox.get(inv.objectBoxId);
        if (fullInv != null) invoiceList.add(fullInv);
      }
      collection.invoices
        ..clear()
        ..addAll(invoiceList);

      // 🧾 Delivery Receipt (optional)
      final receipt = collection.deliveryReceipt.target;
      if (receipt != null) {
        final fullReceipt = deliveryReceiptBox.get(receipt.objectBoxId);
        if (fullReceipt != null) {
          collection.deliveryReceipt.target = fullReceipt;
        }
      }

      debugPrint(
        "✅ Collection ready → ${collection.id} "
        "Invoices: ${collection.invoices.length}",
      );

      output.add(collection);
    }

    debugPrint(
      "📦 Found ${output.length} collections linked to trip: ${trip.name}",
    );

    return output;
  } catch (e, st) {
    debugPrint("❌ getCollectionsByTripId ERROR: $e\n$st");
    throw CacheException(message: e.toString());
  }
}

@override
Future<CollectionModel?> getCollectionById(String collectionId) async {
  try {
    debugPrint('📱 LOCAL: Fetching collection by ID: $collectionId');

    // -----------------------------------------------------
    // 1️⃣ Query Collection by PocketBase ID
    // -----------------------------------------------------
    final query = _collectionBox
        .query(CollectionModel_.pocketbaseId.equals(collectionId))
        .build();
    final collection = query.findFirst();
    query.close();

    if (collection == null) {
      debugPrint('⚠️ Collection not found for ID: $collectionId');
      return null;
    }

    debugPrint('📦 Collection found → ${collection.pocketbaseId}');

    // -----------------------------------------------------
    // 2️⃣ Load Customer (ToOne)
    // -----------------------------------------------------
    final customerRef = collection.customer.target;
    if (customerRef != null) {
      final fullCustomer = customerBox.get(customerRef.objectBoxId);
      if (fullCustomer != null) {
        collection.customer.target = fullCustomer;
        debugPrint('👤 Customer loaded → ${fullCustomer.name}');
      } else {
        debugPrint(
          '⚠️ Customer reference exists but cannot load full object',
        );
      }
    } else {
      debugPrint('⚠️ No customer assigned to this collection');
    }

    // -----------------------------------------------------
    // 3️⃣ Load Delivery Data (ToOne)
    // -----------------------------------------------------
    final deliveryDataRef = collection.deliveryData.target;
    if (deliveryDataRef != null) {
      final fullDeliveryData = deliveryDataBox.get(deliveryDataRef.objectBoxId);
      if (fullDeliveryData != null) {
        collection.deliveryData.target = fullDeliveryData;
        debugPrint('🚚 DeliveryData loaded → ${fullDeliveryData.id}');
      } else {
        debugPrint(
          '⚠️ DeliveryData reference exists but cannot load full object',
        );
      }
    } else {
      debugPrint('⚠️ No delivery data assigned to this collection');
    }

    // -----------------------------------------------------
    // 4️⃣ Load Trip (ToOne)
    // -----------------------------------------------------
    final tripRef = collection.trip.target;
    if (tripRef != null) {
      final fullTrip = tripBox.get(tripRef.objectBoxId);
      if (fullTrip != null) {
        collection.trip.target = fullTrip;
        debugPrint('🗺 Trip loaded → ${fullTrip.name}');
      } else {
        debugPrint('⚠️ Trip reference exists but cannot load full object');
      }
    } else {
      debugPrint('⚠️ No trip assigned to this collection');
    }

    // -----------------------------------------------------
    // 5️⃣ Load Invoices (ToMany)
    // -----------------------------------------------------
    final invoices = collection.invoices;
    if (invoices.isNotEmpty) {
      for (var i = 0; i < invoices.length; i++) {
        final inv = invoices[i];
        final fullInv = invoiceBox.get(inv.objectBoxId);
        if (fullInv != null) {
          invoices[i] = fullInv;
          debugPrint('📄 Invoice loaded → ${fullInv.name}');
        } else {
          debugPrint('⚠️ Invoice not found → OBX ID: ${inv.objectBoxId}');
        }
      }
    } else {
      debugPrint('⚠️ No invoices for this collection');
    }

    // -----------------------------------------------------
    // 6️⃣ Load Delivery Receipt (ToOne)
    // -----------------------------------------------------
    final receiptRef = collection.deliveryReceipt.target;
    if (receiptRef != null) {
      final fullReceipt = deliveryReceiptBox.get(receiptRef.objectBoxId);
      if (fullReceipt != null) {
        collection.deliveryReceipt.target = fullReceipt;
        debugPrint('📜 DeliveryReceipt loaded → ${fullReceipt.id}');
      } else {
        debugPrint('⚠️ DeliveryReceipt reference exists but cannot load object');
      }
    } else {
      debugPrint('⚠️ No delivery receipt assigned to this collection');
    }

    debugPrint('✅ Collection fully loaded with nested relations');
    return collection;
  } catch (e, st) {
    debugPrint('❌ LOCAL: getCollectionById error: $e\n$st');
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
  
 @override
Stream<List<CollectionModel>> watchAllCollections() async* {
  debugPrint('👀 LOCAL: Watching ALL collections');

  final query = _collectionBox.query().build();

  await for (final _ in query.stream()) {
    try {
      final allCollections = _collectionBox.getAll();

      if (allCollections.isEmpty) {
        debugPrint('⚠️ LOCAL: No collections found');
        yield <CollectionModel>[];
        continue;
      }

      final output = <CollectionModel>[];
      final seenIds = <String>{};

      for (final col in allCollections) {
        // Avoid duplicates by PocketBase ID
        final id = col.pocketbaseId;
        if (seenIds.contains(id)) continue;
        seenIds.add(id);

        // ------------------------- Customer -------------------------
        final customerRef = col.customer.target;
        if (customerRef != null) {
          final fullCustomer = customerBox.get(customerRef.objectBoxId);
          if (fullCustomer != null) {
            col.customer.target = fullCustomer;
            col.customer.targetId = fullCustomer.objectBoxId;
          }
        }

        // ------------------------- (Optional) Other relations -------------------------
        // Example:
        // if (col.payments.isNotEmpty) {
        //   final paymentsList = col.payments
        //       .map((p) => paymentBox.get(p.objectBoxId) ?? p)
        //       .toList();
        //   col.payments
        //     ..clear()
        //     ..addAll(paymentsList);
        // }

        output.add(col);
      }

      debugPrint('✅ LOCAL: Stream emitted ${output.length} collections');
      yield output;
    } catch (e, st) {
      debugPrint('❌ watchAllCollections ERROR: $e\n$st');
      yield <CollectionModel>[];
    }
  }
}

  @override
Stream<CollectionModel?> watchCollectionById(String collectionId) {
  debugPrint('👀 LOCAL: Watching collection by ID: $collectionId');

  final query =
      _collectionBox
          .query(CollectionModel_.pocketbaseId.equals(collectionId))
          .build();

  return query.stream().asyncMap((_) async {
    try {
      final collection = await getCollectionById(collectionId);

      debugPrint(
        '📦 LOCAL: Stream emitted collection ID=$collectionId '
        'Customer=${collection?.customer.target?.name ?? "null"} '
        'Amount=${collection?.totalAmount}',
      );

      return collection;
    } catch (e, st) {
      debugPrint(
        '❌ watchCollectionById ERROR ID=$collectionId → $e\n$st',
      );
      return null;
    }
  });
}

}
