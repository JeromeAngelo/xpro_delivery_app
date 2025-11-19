import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/vehicle_profile/data/model/vehicle_profile_model.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/vehicle_profile/domain/entity/vehicle_profile_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/vehicle_profile/domain/repo/vehicle_profile_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/vehicle_profile/data/datasources/remote_datasource/vehicle_profile_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:xpro_delivery_admin_app/core/errors/failures.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

class VehicleProfileRepoImpl implements VehicleProfileRepo {
  final VehicleProfileRemoteDatasource _remoteDatasource;

  const VehicleProfileRepoImpl(this._remoteDatasource);

  @override
  ResultFuture<VehicleProfileEntity> createVehicleProfile(
    VehicleProfileEntity vehicleProfile,
  ) async {
    try {
      debugPrint('🔄 Creating new vehicle profile');
      final createdProfile = await _remoteDatasource.createVehicleProfile(
        vehicleProfile as VehicleProfileModel,
      );
      debugPrint(
        '✅ Successfully created vehicle profile with ID: ${createdProfile.id}',
      );
      return Right(createdProfile);
    } on ServerException catch (e) {
      debugPrint('❌ Server error creating vehicle profile: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> deleteVehicleProfile(String id) async {
    try {
      debugPrint('🔄 Deleting vehicle profile for delivery vehicle ID: $id');
      await _remoteDatasource.deleteVehicleProfile(id);
      debugPrint('✅ Successfully deleted vehicle profile');
      return const Right(null);
    } on ServerException catch (e) {
      debugPrint('❌ Server error deleting vehicle profile: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<VehicleProfileEntity> getVehicleProfileById(String id) async {
    try {
      debugPrint('🔄 Fetching vehicle profile by delivery vehicle ID: $id');
      final profile = await _remoteDatasource.getVehicleProfileById(id);
      debugPrint('✅ Successfully fetched vehicle profile: ${profile.id}');
      return Right(profile);
    } on ServerException catch (e) {
      debugPrint('❌ Server error fetching vehicle profile: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<VehicleProfileEntity>> getVehicleProfiles() async {
    try {
      debugPrint('🔄 Fetching all vehicle profiles');
      final profiles = await _remoteDatasource.getVehicleProfiles();
      debugPrint('✅ Successfully fetched ${profiles.length} vehicle profiles');
      return Right(profiles);
    } on ServerException catch (e) {
      debugPrint('❌ Server error fetching vehicle profiles: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<VehicleProfileEntity> updateVehicleProfile(
    String id,
    VehicleProfileEntity updatedVehicleProfile,
  ) async {
    try {
      debugPrint('🔄 Updating vehicle profile for delivery vehicle ID: $id');
      final updatedProfile = await _remoteDatasource.updateVehicleProfile(
        id,
        updatedVehicleProfile as VehicleProfileModel,
      );
      debugPrint(
        '✅ Successfully updated vehicle profile: ${updatedProfile.id}',
      );
      return Right(updatedProfile);
    } on ServerException catch (e) {
      debugPrint('❌ Server error updating vehicle profile: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
