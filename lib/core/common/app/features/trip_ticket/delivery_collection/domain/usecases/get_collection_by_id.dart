import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/repo/collection_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetCollectionById extends UsecaseWithParams<CollectionEntity, String> {
  const GetCollectionById(this._repo);

  final CollectionRepo _repo;

  @override
  ResultFuture<CollectionEntity> call(String collectionId) {
    return _repo.getCollectionById(collectionId);
  }

  /// Load from local storage only
  ResultFuture<CollectionEntity> loadFromLocal(String collectionId) {
    return _repo.getLocalCollectionById(collectionId);
  }
}
