import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/domain/repo/collection_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class DeleteCollection extends UsecaseWithParams<bool, String> {
  const DeleteCollection(this._repo);

  final CollectionRepo _repo;

  @override
  ResultFuture<bool> call(String collectionId) {
    return _repo.deleteCollection(collectionId);
  }
}
