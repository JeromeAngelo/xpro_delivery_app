import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/src/auth/domain/entity/users_entity.dart';
import 'package:x_pro_delivery_app/src/auth/domain/repo/auth_repo.dart';

class RefreshUserData extends UsecaseWithoutParams<LocalUser> {
  const RefreshUserData(this._repo);

  final AuthRepo _repo;

  @override
  ResultFuture<LocalUser> call() async {
    return _repo.refreshUserData();
  }
}
