import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/entity/vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/repo/vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadVehicleByDeliveryTeam implements UsecaseWithParams<VehicleEntity, String> {
  final VehicleRepo _repo;

  const LoadVehicleByDeliveryTeam(this._repo);

  @override
  ResultFuture<VehicleEntity> call(String deliveryTeamId) async {
    return _repo.loadVehicleByDeliveryTeam(deliveryTeamId);
  }

  ResultFuture<VehicleEntity> loadFromLocal(String deliveryTeamId) async {
    return _repo.loadLocalVehicleByDeliveryTeam(deliveryTeamId);
  }
}
