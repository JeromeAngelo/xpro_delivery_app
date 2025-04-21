import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/src/auth/domain/repo/auth_repo.dart';

class SignOut extends UsecaseWithoutParams<void> {
  const SignOut(this._repo);

  final AuthRepo _repo;

  @override
  ResultFuture<void> call() async {
    return _repo.signOut();
  }
}
