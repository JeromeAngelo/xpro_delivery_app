import 'package:dartz/dartz.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/data/datasource/remote_datasource/personnel_trip_remote_data_src.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/entity/personnel_trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/repo/personnel_trip_repo.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:flutter/material.dart';

import '../../../../../../errors/failures.dart';

class PersonnelTripRepoImpl implements PersonnelTripRepo {
  const PersonnelTripRepoImpl(this._remoteDataSource);

  final PersonnelTripRemoteDataSource _remoteDataSource;

  @override
  ResultFuture<List<PersonnelTripEntity>> getAllPersonnelTrips() async {
    try {
      debugPrint('🔄 REPO: Fetching all personnel trips');
      final result = await _remoteDataSource.getAllPersonnelTrips();
      debugPrint('✅ REPO: Successfully retrieved ${result.length} personnel trips');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server exception - ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error - ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<PersonnelTripEntity> getPersonnelTripById(String id) async {
    try {
      debugPrint('🔄 REPO: Fetching personnel trip by ID: $id');
      final result = await _remoteDataSource.getPersonnelTripById(id);
      debugPrint('✅ REPO: Successfully retrieved personnel trip: ${result.id}');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server exception - ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error - ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<PersonnelTripEntity>> getPersonnelTripsByPersonnelId(String personnelId) async {
    try {
      debugPrint('🔄 REPO: Fetching personnel trips by personnel ID: $personnelId');
      final result = await _remoteDataSource.getPersonnelTripsByPersonnelId(personnelId);
      debugPrint('✅ REPO: Successfully retrieved ${result.length} personnel trips for personnel: $personnelId');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server exception - ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error - ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<PersonnelTripEntity>> getPersonnelTripsByTripId(String tripId) async {
    try {
      debugPrint('🔄 REPO: Fetching personnel trips by trip ID: $tripId');
      final result = await _remoteDataSource.getPersonnelTripsByTripId(tripId);
      debugPrint('✅ REPO: Successfully retrieved ${result.length} personnel trips for trip: $tripId');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server exception - ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error - ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
}
