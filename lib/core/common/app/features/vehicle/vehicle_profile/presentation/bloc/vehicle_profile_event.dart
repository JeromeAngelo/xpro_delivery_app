import 'package:equatable/equatable.dart';
import '../../domain/entity/vehicle_profile_entity.dart';

abstract class VehicleProfileEvent extends Equatable {
  const VehicleProfileEvent();
}

// -----------------------------
// GET ALL VEHICLE PROFILES
// -----------------------------
class GetVehicleProfilesEvent extends VehicleProfileEvent {
  const GetVehicleProfilesEvent();

  @override
  List<Object> get props => [];
}

// -----------------------------
// GET VEHICLE PROFILE BY DELIVERY VEHICLE ID
// -----------------------------
class GetVehicleProfileByIdEvent extends VehicleProfileEvent {
  final String id;

  const GetVehicleProfileByIdEvent(this.id);

  @override
  List<Object> get props => [id];
}

// -----------------------------
// CREATE VEHICLE PROFILE
// -----------------------------
class CreateVehicleProfileEvent extends VehicleProfileEvent {
  final VehicleProfileEntity vehicleProfile;

  const CreateVehicleProfileEvent(this.vehicleProfile);

  @override
  List<Object?> get props => [vehicleProfile];
}

// -----------------------------
// UPDATE VEHICLE PROFILE
// -----------------------------
class UpdateVehicleProfileEvent extends VehicleProfileEvent {
  final String id;
  final VehicleProfileEntity updatedVehicleProfile;

  const UpdateVehicleProfileEvent({
    required this.id,
    required this.updatedVehicleProfile,
  });

  @override
  List<Object?> get props => [id, updatedVehicleProfile];
}

// -----------------------------
// DELETE VEHICLE PROFILE
// -----------------------------
class DeleteVehicleProfileEvent extends VehicleProfileEvent {
  final String id;

  const DeleteVehicleProfileEvent(this.id);

  @override
  List<Object> get props => [id];
}
