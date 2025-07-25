import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/entity/personnel_trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/repo/personnel_trip_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';

class GetAllPersonnelTrips extends UsecaseWithoutParams<List<PersonnelTripEntity>> {
  const GetAllPersonnelTrips(this._repository);

  final PersonnelTripRepo _repository;

  @override
  ResultFuture<List<PersonnelTripEntity>> call() async =>
      _repository.getAllPersonnelTrips();
}
