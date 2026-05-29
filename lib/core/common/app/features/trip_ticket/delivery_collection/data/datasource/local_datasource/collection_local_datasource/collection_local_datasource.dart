import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/get_all_collections_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/get_collections_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/get_collection_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/cache_collections_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/update_collection_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/delete_collection_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/save_collection_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/watch_all_collections_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/watch_collection_by_id_impl.dart';

abstract class CollectionLocalDataSource {
  // Get all collections
  Future<List<CollectionModel>> getAllCollections();

  // Get collections by trip ID
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId);

  // Get collection by ID
  Future<CollectionModel?> getCollectionById(String collectionId);

  // Cache collections
  Future<void> cacheCollections(List<CollectionModel> collections);

  // Update collection
  Future<void> updateCollection(CollectionModel collection);

  // Delete collection
  Future<bool> deleteCollection(String collectionId);

  // Save collection
  Future<CollectionModel> saveCollection(CollectionModel collection);
  Stream<List<CollectionModel>> watchAllCollections();
  Stream<CollectionModel?> watchCollectionById(String collectionId);
}

class CollectionLocalDataSourceImpl extends CollectionLocalBase
    with
        GetAllCollectionsImpl,
        GetCollectionsByTripIdImpl,
        GetCollectionByIdImpl,
        CacheCollectionsImpl,
        UpdateCollectionImpl,
        DeleteCollectionImpl,
        SaveCollectionImpl,
        WatchAllCollectionsImpl,
        WatchCollectionByIdImpl
    implements CollectionLocalDataSource {
  CollectionLocalDataSourceImpl(super.objectBoxStore);
}
