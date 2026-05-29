import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';

mixin WatchAllCollectionsImpl on CollectionLocalBase {
  Stream<List<CollectionModel>> watchAllCollections() async* {
    debugPrint('👀 LOCAL: Watching ALL collections');

    final query = collectionBox.query().build();

    await for (final _ in query.stream()) {
      try {
        final allCollections = collectionBox.getAll();

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
}
