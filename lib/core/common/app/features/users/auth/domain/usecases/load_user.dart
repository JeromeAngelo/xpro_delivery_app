import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entity/users_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repo/auth_repo.dart';


class LoadUser extends UsecaseWithoutParams<LocalUser> {
  const LoadUser(this._repo);
  final AuthRepo _repo;

  @override
  ResultFuture<LocalUser> call() => _repo.loadUser();
  ResultFuture<LocalUser> loadFromLocal() => _repo.loadLocalUserData();
}

