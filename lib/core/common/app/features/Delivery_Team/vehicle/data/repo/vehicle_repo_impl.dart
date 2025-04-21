import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/datasource/local_datasource/vehicle_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/datasource/remote_datasource/vehicle_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/entity/vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/repo/vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class VehicleRepoImpl extends VehicleRepo {
  const VehicleRepoImpl(this._remoteDatasource, this._localDatasource);
  
  final VehicleRemoteDatasource _remoteDatasource;
  final VehicleLocalDatasource _localDatasource;

  @override
  ResultFuture<VehicleEntity> getVehicles() async {
    try {
      final remoteVehicle = await _remoteDatasource.getVehicles();
      await _localDatasource.getVehicles();
      return Right(remoteVehicle);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<VehicleEntity> loadVehicleByDeliveryTeam(String deliveryTeamId) async {
    try {
      final remoteVehicle = await _remoteDatasource.loadVehicleByDeliveryTeam(deliveryTeamId);
      return Right(remoteVehicle);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<VehicleEntity> loadVehicleByTripId(String tripId) async {
    try {
      final remoteVehicle = await _remoteDatasource.loadVehicleByTripId(tripId);
      return Right(remoteVehicle);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<VehicleEntity> loadLocalVehicleByDeliveryTeam(String deliveryTeamId) async {
    try {
      final localVehicle = await _localDatasource.loadVehicleByDeliveryTeam(deliveryTeamId);
      return Right(localVehicle);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<VehicleEntity> loadLocalVehicleByTripId(String tripId) async {
    try {
      final localVehicle = await _localDatasource.loadVehicleByTripId(tripId);
      return Right(localVehicle);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
