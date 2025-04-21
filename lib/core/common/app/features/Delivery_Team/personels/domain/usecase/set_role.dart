import 'package:x_pro_delivery_app/core/enums/user_role.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/domain/repo/personal_repo.dart';

class SetRoleParams {
  const SetRoleParams({
    required this.id,
    required this.newRole,
  });

  final String id;
  final UserRole newRole;
}

class SetRole extends UsecaseWithParams<void, SetRoleParams> {
  const SetRole(this._repo);

  final PersonelRepo _repo;

  @override
  ResultFuture<void> call(SetRoleParams params) async {
    return _repo.setRole(params.id, params.newRole);
  }
}
