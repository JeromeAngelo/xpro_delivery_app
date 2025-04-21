import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/entity/vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
abstract class VehicleRepo {
  const VehicleRepo();

  ResultFuture<VehicleEntity> getVehicles();
  
  // Remote functions
  ResultFuture<VehicleEntity> loadVehicleByDeliveryTeam(String deliveryTeamId);
  ResultFuture<VehicleEntity> loadVehicleByTripId(String tripId);
  
  // Local functions
  ResultFuture<VehicleEntity> loadLocalVehicleByDeliveryTeam(String deliveryTeamId);
  ResultFuture<VehicleEntity> loadLocalVehicleByTripId(String tripId);
}
