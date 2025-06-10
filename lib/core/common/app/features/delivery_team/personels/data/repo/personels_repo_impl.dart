import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/datasource/local_datasource/personel_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/datasource/remote_datasource/personel_remote_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/entity/personel_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/repo/personal_repo.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class PersonelsRepoImpl extends PersonelRepo {
  final PersonelRemoteDataSource _remoteDataSource;
  final PersonelLocalDatasource _localDataSource;

  PersonelsRepoImpl(this._remoteDataSource, this._localDataSource);

  @override
  ResultFuture<List<PersonelEntity>> getPersonels() async {
    try {
      final remotePersonels = await _remoteDataSource.getPersonels();
      await _localDataSource.getPersonels();
      return Right(remotePersonels);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> setRole(String id, UserRole newRole) async {
    try {
      await _remoteDataSource.setRole(id, newRole);
      await _localDataSource.setRole(id, newRole);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<List<PersonelEntity>> loadPersonelsByTripId(String tripId) async {
    try {
      final remotePersonels = await _remoteDataSource.loadPersonelsByTripId(tripId);
      return Right(remotePersonels);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<List<PersonelEntity>> loadPersonelsByDeliveryTeam(String deliveryTeamId) async {
    try {
      final remotePersonels = await _remoteDataSource.loadPersonelsByDeliveryTeam(deliveryTeamId);
      return Right(remotePersonels);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<List<PersonelEntity>> loadLocalPersonelsByTripId(String tripId) async {
    try {
      final localPersonels = await _localDataSource.loadPersonelsByTripId(tripId);
      return Right(localPersonels);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<List<PersonelEntity>> loadLocalPersonelsByDeliveryTeam(String deliveryTeamId) async {
    try {
      final localPersonels = await _localDataSource.loadPersonelsByDeliveryTeam(deliveryTeamId);
      return Right(localPersonels);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
