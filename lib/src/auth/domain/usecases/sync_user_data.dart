// sync_user_data.dart
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/src/auth/domain/repo/auth_repo.dart';

class SyncUserData extends UsecaseWithParams<void, String> {
  const SyncUserData(this._repo);
  final AuthRepo _repo;

  @override
  ResultFuture<void> call(String params) => _repo.syncUserData(params);
}
