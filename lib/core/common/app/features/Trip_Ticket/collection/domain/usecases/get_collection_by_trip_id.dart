import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/domain/repo/collection_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetCollectionsByTripId extends UsecaseWithParams<List<CollectionEntity>, String> {
  const GetCollectionsByTripId(this._repo);

  final CollectionRepo _repo;

  @override
  ResultFuture<List<CollectionEntity>> call(String tripId) {
    return _repo.getCollectionsByTripId(tripId);
  }

  /// Load from local storage only
  ResultFuture<List<CollectionEntity>> loadFromLocal(String tripId) {
    return _repo.getLocalCollectionsByTripId(tripId);
  }
}
