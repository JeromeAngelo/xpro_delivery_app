import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import '../../../../../../../usecases/usecase.dart';
import '../entity/vehicle_profile_entity.dart';
import '../repo/vehicle_profile_repo.dart';

class CreateVehicleProfile
    extends UsecaseWithParams<VehicleProfileEntity, VehicleProfileEntity> {
  
  final VehicleProfileRepo repository;

  const CreateVehicleProfile(this.repository);

  @override
  ResultFuture<VehicleProfileEntity> call(VehicleProfileEntity vehicleProfile) {
    return repository.createVehicleProfile(vehicleProfile);
  }
}
