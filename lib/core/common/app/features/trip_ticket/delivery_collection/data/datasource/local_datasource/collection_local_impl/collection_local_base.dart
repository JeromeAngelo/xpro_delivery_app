import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';

abstract class CollectionLocalBase {
  final ObjectBoxStore objectBoxStore;
  List<CollectionModel>? cachedCollectionsList;

  CollectionLocalBase(this.objectBoxStore);

  // ================================================================
  // BOX GETTERS
  // ================================================================
  Box<CollectionModel> get collectionBox => objectBoxStore.deliveryCollectonBox;
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;
  Box<DeliveryReceiptModel> get deliveryReceiptBox =>
      objectBoxStore.deliveryReceiptBox;

  // ================================================================
  // ABSTRACT METHODS (called by other mixins)
  // ================================================================

  /// Required by watchCollectionById mixin
  Future<CollectionModel?> getCollectionById(String collectionId);

  // ================================================================
  // HELPER METHODS (formerly private, now public for mixin access)
  // ================================================================

  Future<void> cleanupCollections() async {
    try {
      debugPrint('🧹 LOCAL: Starting collection cleanup process');
      final allCollections = collectionBox.getAll();

      // Create a map to track unique collections by their PocketBase ID
      final Map<String?, CollectionModel> uniqueCollections = {};

      for (var collection in allCollections) {
        debugPrint('🔍 Validating collection: ${collection.pocketbaseId}');
        debugPrint('   - Collection ID: ${collection.collectionId}');
        debugPrint('   - Collection Name: ${collection.collectionName}');
        debugPrint('   - Total Amount: ${collection.totalAmount}');
        debugPrint('   - Is Valid: ${isValidCollection(collection)}');

        // Only keep valid collections with required fields
        if (isValidCollection(collection)) {
          // If duplicate found, keep the most recently updated one
          final existingCollection = uniqueCollections[collection.pocketbaseId];
          if (existingCollection == null ||
              (collection.updated?.isAfter(
                    existingCollection.updated ?? DateTime(0),
                  ) ??
                  false)) {
            uniqueCollections[collection.pocketbaseId] = collection;
            debugPrint('   ✅ Collection kept');
          } else {
            debugPrint('   🔄 Collection replaced with newer version');
          }
        } else {
          debugPrint(
            '   ⚠️ Collection has validation issues but will be kept for data integrity',
          );
          // Keep collections even if they have validation issues to prevent data loss
          uniqueCollections[collection.pocketbaseId] = collection;
        }
      }

      // Clear all and save only unique collections
      collectionBox.removeAll();
      collectionBox.putMany(uniqueCollections.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allCollections.length}');
      debugPrint('📊 After cleanup: ${uniqueCollections.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool isValidCollection(CollectionModel collection) {
    // Relaxed validation - only check for essential PocketBase ID
    final hasValidId = collection.pocketbaseId.isNotEmpty;

    // Generate missing fields if needed
    if (collection.collectionId == null || collection.collectionId!.isEmpty) {
      collection.collectionId = 'collection_${collection.pocketbaseId}';
      debugPrint('🔧 Generated collectionId: ${collection.collectionId}');
    }

    if (collection.collectionName == null ||
        collection.collectionName!.isEmpty) {
      collection.collectionName = 'deliveryCollection';
      debugPrint('🔧 Generated collectionName: ${collection.collectionName}');
    }

    debugPrint('🔍 Validation details:');
    debugPrint(
      '   - PocketBase ID: "${collection.pocketbaseId}" (empty: ${collection.pocketbaseId.isEmpty})',
    );
    debugPrint(
      '   - Collection ID: "${collection.collectionId}" (null: ${collection.collectionId == null})',
    );
    debugPrint('   - Collection Name: "${collection.collectionName}"');
    debugPrint('   - Total Amount: ${collection.totalAmount}');
    debugPrint('   - Final validation result: $hasValidId');

    return hasValidId;
  }

  Future<void> autoSave(List<CollectionModel> collections) async {
    try {
      debugPrint('🔍 LOCAL: Processing ${collections.length} collections');

      final validCollections =
          collections.map((collection) {
            debugPrint(
              '🔧 Setting relations for collection: ${collection.pocketbaseId}',
            );

            // Ensure collection has required fields
            if (collection.collectionId == null ||
                collection.collectionId!.isEmpty) {
              collection.collectionId = 'collection_${collection.pocketbaseId}';
              debugPrint(
                '🔧 Generated collectionId: ${collection.collectionId}',
              );
            }

            if (collection.collectionName == null ||
                collection.collectionName!.isEmpty) {
              collection.collectionName = 'deliveryCollection';
              debugPrint(
                '🔧 Generated collectionName: ${collection.collectionName}',
              );
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

      collectionBox.putMany(validCollections);
      cachedCollectionsList = validCollections;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Collections: ${validCollections.length}');
      debugPrint(
        'Valid Collections: ${validCollections.where((c) => c.objectBoxId != 0).length}',
      );
      debugPrint(
        'With Delivery Data: ${validCollections.where((c) => c.deliveryDataId != null).length}',
      );
      debugPrint(
        'With Trip Data: ${validCollections.where((c) => c.tripId != null).length}',
      );
      debugPrint(
        'With Customer Data: ${validCollections.where((c) => c.customerId != null).length}',
      );
      debugPrint(
        'With Invoice Data: ${validCollections.where((c) => c.invoiceId != null).length}',
      );
      debugPrint(
        'With Total Amount: ${validCollections.where((c) => c.totalAmount != null && c.totalAmount! > 0).length}',
      );

      // Debug each saved collection
      for (var collection in validCollections) {
        debugPrint(
          '💾 Saved: ${collection.pocketbaseId} - Trip: ${collection.tripId} - Customer: ${collection.customerId} - Invoice: ${collection.invoiceId} - Amount: ${collection.totalAmount}',
        );
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
