import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import '../../../../../../../usecases/usecase.dart';
import '../entity/vehicle_profile_entity.dart';
import '../repo/vehicle_profile_repo.dart';

class UpdateVehicleProfile extends UsecaseWithParams<
    VehicleProfileEntity,
    UpdateVehicleProfileParams> {
  
  final VehicleProfileRepo repository;

  const UpdateVehicleProfile(this.repository);

  @override
  ResultFuture<VehicleProfileEntity> call(
      UpdateVehicleProfileParams params) {
    return repository.updateVehicleProfile(params.id, params.updatedData);
  }
}

class UpdateVehicleProfileParams {
  final String id;
  final VehicleProfileEntity updatedData;

  UpdateVehicleProfileParams({required this.id, required this.updatedData});
}
