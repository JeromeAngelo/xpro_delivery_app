import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin DeleteCollectionImpl on CollectionLocalBase {
  Future<bool> deleteCollection(String collectionId) async {
    try {
      debugPrint('📱 LOCAL: Deleting collection with ID: $collectionId');

      final collection =
          collectionBox
              .query(CollectionModel_.pocketbaseId.equals(collectionId))
              .build()
              .findFirst();

      if (collection == null) {
        throw const CacheException(
          message: 'Collection not found in local storage',
        );
      }

      collectionBox.remove(collection.objectBoxId);
      debugPrint('✅ LOCAL: Successfully deleted collection');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
