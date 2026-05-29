import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin UpdateCollectionImpl on CollectionLocalBase {
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

      collectionBox.put(collection);
      debugPrint('✅ LOCAL: Collection updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
