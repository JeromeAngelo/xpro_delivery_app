import 'package:dartz/dartz.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/datasource/remote_datasource/personel_remote_data_source.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/repo/personal_repo.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_role.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:xpro_delivery_admin_app/core/errors/failures.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:flutter/foundation.dart';

class PersonelsRepoImpl implements PersonelRepo {
  final PersonelRemoteDataSource _remoteDataSource;

  PersonelsRepoImpl(this._remoteDataSource);

  @override
  ResultFuture<List<PersonelEntity>> getPersonels() async {
    try {
      debugPrint('🔄 Getting all personnel from remote');
      final remotePersonels = await _remoteDataSource.getPersonels();
      debugPrint('✅ Successfully retrieved ${remotePersonels.length} personnel');
      return Right(remotePersonels);
    } on ServerException catch (e) {
      debugPrint('❌ Server error getting personnel: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<PersonelEntity> getPersonelById(String personelId) async {
    try {
      debugPrint('🔄 Getting personnel by ID: $personelId');
      final remotePersonel = await _remoteDataSource.getPersonelById(personelId);
      debugPrint('✅ Successfully retrieved personnel');
      return Right(remotePersonel);
    } on ServerException catch (e) {
      debugPrint('❌ Server error getting personnel by ID: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> setRole(String id, UserRole newRole) async {
    try {
      debugPrint('🔄 Setting role for personnel $id to ${newRole.toString()}');
      await _remoteDataSource.setRole(id, newRole);
      debugPrint('✅ Successfully set role');
      return const Right(null);
    } on ServerException catch (e) {
      debugPrint('❌ Server error setting role: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<List<PersonelEntity>> loadPersonelsByTripId(String tripId) async {
    try {
      debugPrint('🔄 Loading personnel for trip: $tripId');
      final remotePersonels = await _remoteDataSource.loadPersonelsByTripId(tripId);
      debugPrint('✅ Successfully loaded ${remotePersonels.length} personnel for trip');
      return Right(remotePersonels);
    } on ServerException catch (e) {
      debugPrint('❌ Server error loading personnel by trip: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<List<PersonelEntity>> loadPersonelsByDeliveryTeam(String deliveryTeamId) async {
    try {
      debugPrint('🔄 Loading personnel for delivery team: $deliveryTeamId');
      final remotePersonels = await _remoteDataSource.loadPersonelsByDeliveryTeam(deliveryTeamId);
      debugPrint('✅ Successfully loaded ${remotePersonels.length} personnel for delivery team');
      return Right(remotePersonels);
    } on ServerException catch (e) {
      debugPrint('❌ Server error loading personnel by delivery team: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<PersonelEntity> createPersonel({
    required String name,
    required UserRole role,
    String? deliveryTeamId,
    String? tripId,
  }) async {
    try {
      debugPrint('🔄 Creating new personnel: $name');
      final createdPersonel = await _remoteDataSource.createPersonel(
        name: name,
        role: role,
        deliveryTeamId: deliveryTeamId,
        tripId: tripId,
      );
      debugPrint('✅ Successfully created personnel with ID: ${createdPersonel.id}');
      return Right(createdPersonel);
    } on ServerException catch (e) {
      debugPrint('❌ Server error creating personnel: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> deletePersonel(String personelId) async {
    try {
      debugPrint('🔄 Deleting personnel: $personelId');
      final result = await _remoteDataSource.deletePersonel(personelId);
      debugPrint('✅ Successfully deleted personnel');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ Server error deleting personnel: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> deleteAllPersonels(List<String> personelIds) async {
    try {
      debugPrint('🔄 Deleting multiple personnel: ${personelIds.length} items');
      final result = await _remoteDataSource.deleteAllPersonels(personelIds);
      debugPrint('✅ Successfully deleted all personnel');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ Server error deleting multiple personnel: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<PersonelEntity> updatePersonel({
    required String personelId,
    String? name,
    UserRole? role,
    String? deliveryTeamId,
    String? tripId,
  }) async {
    try {
      debugPrint('🔄 Updating personnel: $personelId');
      final updatedPersonel = await _remoteDataSource.updatePersonel(
        personelId: personelId,
        name: name,
        role: role,
        deliveryTeamId: deliveryTeamId,
        tripId: tripId,
      );
      debugPrint('✅ Successfully updated personnel');
      return Right(updatedPersonel);
    } on ServerException catch (e) {
      debugPrint('❌ Server error updating personnel: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
