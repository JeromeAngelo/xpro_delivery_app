import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/repo/vehicle_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';
import 'package:equatable/equatable.dart';

class DeleteAllVehicles implements UsecaseWithParams<bool, DeleteAllVehiclesParams> {
  final VehicleRepo _repo;

  const DeleteAllVehicles(this._repo);

  @override
  ResultFuture<bool> call(DeleteAllVehiclesParams params) => 
      _repo.deleteAllVehicles(params.vehicleIds);
}

class DeleteAllVehiclesParams extends Equatable {
  final List<String> vehicleIds;

  const DeleteAllVehiclesParams({required this.vehicleIds});

  @override
  List<Object> get props => [vehicleIds];
}
