import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

abstract class VehicleRepo {
  const VehicleRepo();

  // Updated to return a list
  ResultFuture<List<VehicleEntity>> getVehicles();
  
  // Remote functions for loading vehicles
  ResultFuture<VehicleEntity> loadVehicleByDeliveryTeam(String deliveryTeamId);
  ResultFuture<VehicleEntity> loadVehicleByTripId(String tripId);
  
  // New CRUD operations
  ResultFuture<VehicleEntity> createVehicle({
    required String vehicleName,
    required String vehiclePlateNumber,
    required String vehicleType,
    String? deliveryTeamId,
    String? tripId,
  });
  
  ResultFuture<VehicleEntity> updateVehicle({
    required String vehicleId,
    String? vehicleName,
    String? vehiclePlateNumber,
    String? vehicleType,
    String? deliveryTeamId,
    String? tripId,
  });
  
  ResultFuture<bool> deleteVehicle(String vehicleId);
  
  ResultFuture<bool> deleteAllVehicles(List<String> vehicleIds);
}
