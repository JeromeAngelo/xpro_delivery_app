import '../../../../../../../typedefs/typedefs.dart';
import '../entity/vehicle_profile_entity.dart';

abstract class VehicleProfileRepo {
  const VehicleProfileRepo();

  /// Fetch all vehicle profiles
  ResultFuture<List<VehicleProfileEntity>> getVehicleProfiles();

  /// Fetch single vehicle profile by id
  ResultFuture<VehicleProfileEntity> getVehicleProfileById(String id);

  /// Create a vehicle profile
  ResultFuture<VehicleProfileEntity> createVehicleProfile(
    VehicleProfileEntity vehicleProfile,
  );

  /// Update an existing vehicle profile
  ResultFuture<VehicleProfileEntity> updateVehicleProfile(
    String id,
    VehicleProfileEntity updatedVehicleProfile,
  );

  /// Delete a vehicle profile
  ResultFuture<void> deleteVehicleProfile(String id);
}
