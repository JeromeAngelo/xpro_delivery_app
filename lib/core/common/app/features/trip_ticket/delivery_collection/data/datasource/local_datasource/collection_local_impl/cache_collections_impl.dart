import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheCollectionsImpl on CollectionLocalBase {
  Future<void> cacheCollections(List<CollectionModel> collections) async {
    try {
      debugPrint('💾 LOCAL: Starting collection caching process...');
      debugPrint(
        '📥 LOCAL: Received ${collections.length} collections to cache',
      );

      // Debug incoming collections
      for (var collection in collections) {
        debugPrint('🔍 Incoming Collection: ${collection.pocketbaseId}');
        debugPrint('   - Collection ID: ${collection.collectionId}');
        debugPrint('   - Collection Name: ${collection.collectionName}');
        debugPrint('   - Total Amount: ${collection.totalAmount}');
        debugPrint(
          '   - Delivery Data Target: ${collection.deliveryData.target?.id}',
        );
        debugPrint('   - Trip Target: ${collection.trip.target?.id}');
        debugPrint('   - Customer Target: ${collection.customer.target?.id}');
        debugPrint('   - Invoice Target: ${collection.invoice.target?.id}');
      }

      await cleanupCollections();
      await autoSave(collections);

      final cachedCount = collectionBox.count();
      debugPrint(
        '✅ LOCAL: Cache verification: $cachedCount collections stored',
      );

      cachedCollectionsList = collections;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
