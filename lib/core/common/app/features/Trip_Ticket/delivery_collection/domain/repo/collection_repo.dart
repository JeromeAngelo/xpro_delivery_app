import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class CollectionRepo {
  const CollectionRepo();

  /// Load collections by trip ID from remote
  ResultFuture<List<CollectionEntity>> getCollectionsByTripId(String tripId);

  /// Load collections by trip ID from local storage
  ResultFuture<List<CollectionEntity>> getLocalCollectionsByTripId(String tripId);

  /// Load collection by ID from remote
  ResultFuture<CollectionEntity> getCollectionById(String collectionId);

  /// Load collection by ID from local storage
  ResultFuture<CollectionEntity> getLocalCollectionById(String collectionId);

  /// Delete collection
  ResultFuture<bool> deleteCollection(String collectionId);

 
}
