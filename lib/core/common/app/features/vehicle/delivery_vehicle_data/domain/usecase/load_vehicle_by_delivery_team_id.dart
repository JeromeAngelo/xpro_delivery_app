
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/repo/vehicle_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';

class LoadVehicleByDeliveryTeam implements UsecaseWithParams<VehicleEntity, String> {
  final VehicleRepo _repo;

  const LoadVehicleByDeliveryTeam(this._repo);

  @override
  ResultFuture<VehicleEntity> call(String deliveryTeamId) async {
    return _repo.loadVehicleByDeliveryTeam(deliveryTeamId);
  }

  
}
