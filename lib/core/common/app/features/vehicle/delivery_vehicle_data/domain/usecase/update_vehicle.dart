import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/repo/vehicle_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';
import 'package:equatable/equatable.dart';

class UpdateVehicle implements UsecaseWithParams<VehicleEntity, UpdateVehicleParams> {
  final VehicleRepo _repo;

  const UpdateVehicle(this._repo);

  @override
  ResultFuture<VehicleEntity> call(UpdateVehicleParams params) => _repo.updateVehicle(
    vehicleId: params.vehicleId,
    vehicleName: params.vehicleName,
    vehiclePlateNumber: params.vehiclePlateNumber,
    vehicleType: params.vehicleType,
    deliveryTeamId: params.deliveryTeamId,
    tripId: params.tripId,
  );
}

class UpdateVehicleParams extends Equatable {
  final String vehicleId;
  final String? vehicleName;
  final String? vehiclePlateNumber;
  final String? vehicleType;
  final String? deliveryTeamId;
  final String? tripId;

  const UpdateVehicleParams({
    required this.vehicleId,
    this.vehicleName,
    this.vehiclePlateNumber,
    this.vehicleType,
    this.deliveryTeamId,
    this.tripId,
  });

  @override
  List<Object?> get props => [
    vehicleId, 
    vehicleName, 
    vehiclePlateNumber, 
    vehicleType, 
    deliveryTeamId, 
    tripId
  ];
}
