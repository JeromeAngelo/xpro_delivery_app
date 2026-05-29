import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_impl/collection_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetCollectionByIdImpl on CollectionRemoteBase {
  Future<CollectionModel> getCollectionById(String collectionId) async {
    try {
      debugPrint('🔄 Fetching collection by ID: $collectionId');

      final record = await pocketBaseClient
          .collection('deliveryCollection')
          .getOne(
            collectionId,
            expand:
                'deliveryData,trip,customer,invoice,invoices,invoices.products,invoices.customer',
          );

      debugPrint('✅ Retrieved collection from API: ${record.id}');

      return processCollectionRecord(record);
    } catch (e) {
      debugPrint('❌ Collection fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load collection: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
