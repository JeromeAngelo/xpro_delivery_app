import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import '../../../../../../../usecases/usecase.dart';
import '../repo/vehicle_profile_repo.dart';

class DeleteVehicleProfile
    extends UsecaseWithParams<void, String> {
  
  final VehicleProfileRepo repository;

  const DeleteVehicleProfile(this.repository);

  @override
  ResultFuture<void> call(String id) {
    return repository.deleteVehicleProfile(id);
  }
}
