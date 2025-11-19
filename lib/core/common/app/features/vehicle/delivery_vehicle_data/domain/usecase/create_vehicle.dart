import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/repo/vehicle_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';
import 'package:equatable/equatable.dart';

class CreateVehicle implements UsecaseWithParams<VehicleEntity, CreateVehicleParams> {
  final VehicleRepo _repo;

  const CreateVehicle(this._repo);

  @override
  ResultFuture<VehicleEntity> call(CreateVehicleParams params) => _repo.createVehicle(
    vehicleName: params.vehicleName,
    vehiclePlateNumber: params.vehiclePlateNumber,
    vehicleType: params.vehicleType,
    deliveryTeamId: params.deliveryTeamId,
    tripId: params.tripId,
  );
}

class CreateVehicleParams extends Equatable {
  final String vehicleName;
  final String vehiclePlateNumber;
  final String vehicleType;
  final String? deliveryTeamId;
  final String? tripId;

  const CreateVehicleParams({
    required this.vehicleName,
    required this.vehiclePlateNumber,
    required this.vehicleType,
    this.deliveryTeamId,
    this.tripId,
  });

  @override
  List<Object?> get props => [
    vehicleName, 
    vehiclePlateNumber, 
    vehicleType, 
    deliveryTeamId, 
    tripId
  ];
}
