import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import '../../../../../../../usecases/usecase.dart';
import '../entity/vehicle_profile_entity.dart';
import '../repo/vehicle_profile_repo.dart';

class GetVehicleProfileById
    extends UsecaseWithParams<VehicleProfileEntity, String> {
  
  final VehicleProfileRepo repository;

  const GetVehicleProfileById(this.repository);

  @override
  ResultFuture<VehicleProfileEntity> call(String id) {
    return repository.getVehicleProfileById(id);
  }
}
