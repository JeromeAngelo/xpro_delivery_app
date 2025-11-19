import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import '../../../../../../../usecases/usecase.dart';
import '../entity/vehicle_profile_entity.dart';
import '../repo/vehicle_profile_repo.dart';

class GetVehicleProfiles extends UsecaseWithoutParams<List<VehicleProfileEntity>> {
  final VehicleProfileRepo repository;

  const GetVehicleProfiles(this.repository);

  @override
  ResultFuture<List<VehicleProfileEntity>> call() {
    return repository.getVehicleProfiles();
  }
}
