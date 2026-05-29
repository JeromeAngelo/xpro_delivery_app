import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin WatchCollectionByIdImpl on CollectionLocalBase {
  Stream<CollectionModel?> watchCollectionById(String collectionId) {
    debugPrint('👀 LOCAL: Watching collection by ID: $collectionId');

    final query =
        collectionBox
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
        debugPrint('❌ watchCollectionById ERROR ID=$collectionId → $e\n$st');
        return null;
      }
    });
  }
}
