import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_impl/collection_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetCollectionsByTripIdImpl on CollectionRemoteBase {
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId) async {
    try {
      final records = await pocketBaseClient
          .collection('deliveryCollection')
          .getFullList(
            filter: 'trip = "$tripId"',
            expand:
                'deliveryData,trip,customer,invoice,invoices,invoices.products,invoices.customer',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} collections from API');

      List<CollectionModel> collections = [];

      for (var record in records) {
        collections.add(processCollectionRecord(record));
      }

      debugPrint('✨ Successfully processed ${collections.length} collections');
      return collections;
    } catch (e) {
      debugPrint('❌ Collections fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load collections: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
