import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_impl/collection_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin DeleteCollectionImpl on CollectionRemoteBase {
  Future<bool> deleteCollection(String collectionId) async {
    try {
      debugPrint('🔄 Deleting collection: $collectionId');

      await pocketBaseClient
          .collection('deliveryCollection')
          .delete(collectionId);

      debugPrint('✅ Successfully deleted collection: $collectionId');
      return true;
    } catch (e) {
      debugPrint('❌ Collection deletion failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete collection: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
