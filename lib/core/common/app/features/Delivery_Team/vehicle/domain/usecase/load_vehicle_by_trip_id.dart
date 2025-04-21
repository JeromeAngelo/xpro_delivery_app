import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/entity/vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/repo/vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadVehicleByTripId implements UsecaseWithParams<VehicleEntity, String> {
  final VehicleRepo _repo;

  const LoadVehicleByTripId(this._repo);

  @override
  ResultFuture<VehicleEntity> call(String tripId) async {
    return _repo.loadVehicleByTripId(tripId);
  }

  ResultFuture<VehicleEntity> loadFromLocal(String tripId) async {
    return _repo.loadLocalVehicleByTripId(tripId);
  }
}
