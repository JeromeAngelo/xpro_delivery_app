
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/repo/vehicle_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';

class GetVehicle extends UsecaseWithoutParams<List<VehicleEntity>> {
  const GetVehicle(this._repo);

  final VehicleRepo _repo;

  @override
  ResultFuture<List<VehicleEntity>> call() => _repo.getVehicles();
}