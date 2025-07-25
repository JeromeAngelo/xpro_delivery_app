import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/repo/personal_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';

class GetPersonelById implements UsecaseWithParams<PersonelEntity, String> {
  const GetPersonelById(this._repo);
  final PersonelRepo _repo;

  @override
  ResultFuture<PersonelEntity> call(String personelId) => _repo.getPersonelById(personelId);
}
