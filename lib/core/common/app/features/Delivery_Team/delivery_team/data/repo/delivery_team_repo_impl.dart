import 'package:dartz/dartz.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/datasource/remote_datasource/delivery_team_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/repo/delivery_team_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/data/model/vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:xpro_delivery_admin_app/core/errors/failures.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:flutter/foundation.dart';

class DeliveryTeamRepoImpl implements DeliveryTeamRepo {
  final DeliveryTeamDatasource _remoteDatasource;

  const DeliveryTeamRepoImpl(this._remoteDatasource);

  @override
  ResultFuture<DeliveryTeamEntity> loadDeliveryTeam(String tripId) async {
    try {
      debugPrint('🌐 Fetching delivery team from remote for trip: $tripId');
      final remoteTeam = await _remoteDatasource.loadDeliveryTeam(tripId);
      debugPrint('✅ Successfully loaded delivery team from remote');
      return Right(remoteTeam);
    } on ServerException catch (e) {
      debugPrint('❌ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<DeliveryTeamEntity> loadDeliveryTeamById(String deliveryTeamId) async {
    try {
      debugPrint('🌐 Fetching delivery team by ID from remote: $deliveryTeamId');
      final remoteTeam = await _remoteDatasource.loadDeliveryTeamById(deliveryTeamId);
      debugPrint('✅ Successfully loaded delivery team by ID from remote');
      return Right(remoteTeam);
    } on ServerException catch (e) {
      debugPrint('❌ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<DeliveryTeamEntity>> loadAllDeliveryTeam() async {
    try {
      debugPrint('🌐 Fetching all delivery teams from remote');
      final remoteTeams = await _remoteDatasource.loadAllDeliveryTeam();
      debugPrint('✅ Successfully loaded ${remoteTeams.length} delivery teams');
      return Right(remoteTeams);
    } on ServerException catch (e) {
      debugPrint('❌ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<DeliveryTeamEntity> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  }) async {
    try {
      debugPrint('🔄 Assigning delivery team to trip');
      final result = await _remoteDatasource.assignDeliveryTeamToTrip(
        tripId: tripId,
        deliveryTeamId: deliveryTeamId,
      );
      debugPrint('✅ Successfully assigned delivery team to trip');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ Assignment failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<DeliveryTeamEntity> createDeliveryTeam({
    required String deliveryTeamId,
    required VehicleEntity vehicle,
    required List<PersonelEntity> personels,
    required TripEntity tripId,
  }) async {
    try {
      debugPrint('🔄 Creating new delivery team');
      
      // Convert entities to models for the datasource
      final vehicleModel = vehicle as VehicleModel;
      final personelModels = personels.map((p) => p as PersonelModel).toList();
      
      final result = await _remoteDatasource.createDeliveryTeam(
        deliveryTeamId: deliveryTeamId,
        vehicle: vehicleModel,
        personels: personelModels,
        tripId: tripId as TripModel,
      );
      
      debugPrint('✅ Successfully created delivery team');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ Creation failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<DeliveryTeamEntity> updateDeliveryTeam({
    required String deliveryTeamId,
    required VehicleEntity vehicle,
    required List<PersonelEntity> personels,
    required TripEntity tripId,
  }) async {
    try {
      debugPrint('🔄 Updating delivery team: $deliveryTeamId');
      
      // Convert entities to models for the datasource
      final vehicleModel = vehicle as VehicleModel;
      final personelModels = personels.map((p) => p as PersonelModel).toList();
      
      final result = await _remoteDatasource.updateDeliveryTeam(
        deliveryTeamId: deliveryTeamId,
        vehicle: vehicleModel,
        personels: personelModels,
        tripId: tripId as TripModel,
      );
      
      debugPrint('✅ Successfully updated delivery team');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ Update failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> deleteDeliveryTeam(String deliveryTeamId) async {
    try {
      debugPrint('🔄 Deleting delivery team: $deliveryTeamId');
      final result = await _remoteDatasource.deleteDeliveryTeam(deliveryTeamId);
      debugPrint('✅ Successfully deleted delivery team');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ Deletion failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
