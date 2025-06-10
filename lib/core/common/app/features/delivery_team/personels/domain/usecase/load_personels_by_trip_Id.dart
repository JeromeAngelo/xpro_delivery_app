import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/entity/personel_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/repo/personal_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadPersonelsByTripId implements UsecaseWithParams<List<PersonelEntity>, String> {
  final PersonelRepo _repo;

  const LoadPersonelsByTripId(this._repo);

  @override
  ResultFuture<List<PersonelEntity>> call(String tripId) async {
    return _repo.loadPersonelsByTripId(tripId);
  }

  ResultFuture<List<PersonelEntity>> loadFromLocal(String tripId) async {
    return _repo.loadLocalPersonelsByTripId(tripId);
  }
}
