import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetAllCollectionsImpl on CollectionLocalBase {
  Future<List<CollectionModel>> getAllCollections() async {
    try {
      debugPrint('📱 LOCAL: Fetching all collections');

      final collections = collectionBox.getAll();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored collections: ${collectionBox.count()}');
      debugPrint('Found collections: ${collections.length}');

      // Debug each collection
      for (var collection in collections) {
        debugPrint(
          '📋 Collection: ${collection.pocketbaseId} - Customer: ${collection.customer.target?.name ?? "null"}',
        );
      }

      cachedCollectionsList = collections;
      return collections;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
