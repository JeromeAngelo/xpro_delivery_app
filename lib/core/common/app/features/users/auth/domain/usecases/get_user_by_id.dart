import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entity/users_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repo/auth_repo.dart';

class GetUserById extends UsecaseWithParams<LocalUser, String> {
  const GetUserById(this._repo);
  final AuthRepo _repo;

  @override
  ResultFuture<LocalUser> call(String params) => _repo.getUserById(params);
  ResultFuture<LocalUser> loadFromLocal(String params) => _repo.loadLocalUserById(params);
}
