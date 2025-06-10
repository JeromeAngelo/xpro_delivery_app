import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/entity/vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/repo/vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetVehicle extends UsecaseWithoutParams<VehicleEntity> {
  const GetVehicle(this._repo);

  final VehicleRepo _repo;

  @override
  ResultFuture<VehicleEntity> call() => _repo.getVehicles();
}