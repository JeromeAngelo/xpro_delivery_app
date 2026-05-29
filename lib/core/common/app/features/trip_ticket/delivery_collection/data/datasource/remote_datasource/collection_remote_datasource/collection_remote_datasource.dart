import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_impl/collection_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_impl/get_collections_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_impl/get_collection_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/remote_datasource/collection_remote_impl/delete_collection_impl.dart';

abstract class CollectionRemoteDataSource {
  /// Load collections by trip ID from remote
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId);

  /// Load collection by ID from remote
  Future<CollectionModel> getCollectionById(String collectionId);

  /// Delete collection from remote
  Future<bool> deleteCollection(String collectionId);
}

class CollectionRemoteDataSourceImpl extends CollectionRemoteBase
    with GetCollectionsByTripIdImpl, GetCollectionByIdImpl, DeleteCollectionImpl
    implements CollectionRemoteDataSource {
  const CollectionRemoteDataSourceImpl({required super.pocketBaseClient});
}
