import 'package:equatable/equatable.dart';

import '../../domain/entity/vehicle_profile_entity.dart';

abstract class VehicleProfileState extends Equatable {
  const VehicleProfileState();

  @override
  List<Object> get props => [];
}

// -----------------------------
// INITIAL STATE
// -----------------------------
class VehicleProfileInitial extends VehicleProfileState {
  const VehicleProfileInitial();
}

// -----------------------------
// LOADING STATE
// -----------------------------
class VehicleProfileLoading extends VehicleProfileState {
  const VehicleProfileLoading();
}

// -----------------------------
// LOADED STATES
// -----------------------------
class VehicleProfilesLoaded extends VehicleProfileState {
  final List<VehicleProfileEntity> vehicleProfiles;

  const VehicleProfilesLoaded(this.vehicleProfiles);

  @override
  List<Object> get props => [vehicleProfiles];
}

class VehicleProfileByIdLoaded extends VehicleProfileState {
  final VehicleProfileEntity vehicleProfile;

  const VehicleProfileByIdLoaded(this.vehicleProfile);

  @override
  List<Object> get props => [vehicleProfile];
}

// -----------------------------
// CREATE STATE
// -----------------------------
class VehicleProfileCreated extends VehicleProfileState {
  final VehicleProfileEntity vehicleProfile;

  const VehicleProfileCreated(this.vehicleProfile);

  @override
  List<Object> get props => [vehicleProfile];
}

// -----------------------------
// UPDATE STATE
// -----------------------------
class VehicleProfileUpdated extends VehicleProfileState {
  final VehicleProfileEntity vehicleProfile;

  const VehicleProfileUpdated(this.vehicleProfile);

  @override
  List<Object> get props => [vehicleProfile];
}

// -----------------------------
// DELETE STATE
// -----------------------------
class VehicleProfileDeleted extends VehicleProfileState {
  final String deliveryVehicleId;

  const VehicleProfileDeleted(this.deliveryVehicleId);

  @override
  List<Object> get props => [deliveryVehicleId];
}

// -----------------------------
// ERROR STATE
// -----------------------------
class VehicleProfileError extends VehicleProfileState {
  final String message;

  const VehicleProfileError(this.message);

  @override
  List<Object> get props => [message];
}
