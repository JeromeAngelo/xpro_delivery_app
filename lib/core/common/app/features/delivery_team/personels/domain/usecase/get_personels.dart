import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/entity/personel_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/repo/personal_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetPersonels implements UsecaseWithoutParams<List<PersonelEntity>> {
  const GetPersonels(this._repo);
  final PersonelRepo _repo;

  @override
  ResultFuture<List<PersonelEntity>> call() => _repo.getPersonels();
}
